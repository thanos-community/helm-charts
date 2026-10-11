{{- /*
Compactor pod template, shared by the StatefulSet and the CronJob.
Call with (dict "root" $ "cron" <bool>); the output starts at column 0.
*/ -}}
{{- define "thanos.compactor.podTemplate" -}}
{{- $cron := .cron -}}
{{- with .root -}}
metadata:
  labels:
    {{- include "thanos.labels" . | nindent 4 }}
    app.kubernetes.io/component: compactor
    {{- include "thanos.podLabels" (dict "root" . "key" "compactor") | nindent 4 }}
  annotations:
    checksum/objstore-configuration: {{ .Values.global.objstore.config | sha256sum }}
    {{- with .Values.global.podAnnotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- if $cron }}
  restartPolicy: {{ .Values.compactor.cronJob.restartPolicy }}
  {{- end }}
  serviceAccountName: {{ include "thanos.serviceAccountName" (dict "root" . "component" "compactor") }}
  {{- include "thanos.affinity" (dict "Values" .Values "component" "compactor") | nindent 2 }}
  {{- include "thanos.imagePullSecrets" . | nindent 2 }}
  {{- include "thanos.podSC" (dict "root" . "key" "compactor") | nindent 2 }}
  containers:
    - name: compactor
      image: {{ include "thanos.image" (dict "root" . "image" .Values.global.image) | quote }}
      imagePullPolicy: {{ .Values.global.image.pullPolicy }}
      args:
        - compact
        - --http-address=0.0.0.0:{{ .Values.compactor.service.port }}
        - --objstore.config-file=/etc/thanos/objstore.yml
        - --data-dir=/var/thanos/compact
        {{- if not $cron }}
        - --wait
        {{- end }}
      {{- with .Values.compactor.retention.resolutionRaw }}
        - --retention.resolution-raw={{ . }}
      {{- end }}
      {{- with .Values.compactor.retention.resolution5m }}
        - --retention.resolution-5m={{ . }}
      {{- end }}
      {{- with .Values.compactor.retention.resolution1h }}
        - --retention.resolution-1h={{ . }}
      {{- end }}
      {{- range .Values.compactor.extraArgs }}
        - {{ . | quote }}
      {{- end }}
      {{- include "thanos.extraEnvBlock" (dict "Values" .Values "component" "compactor") | nindent 6 }}
      {{- include "thanos.extraEnvFromBlock" (dict "Values" .Values "component" "compactor") | nindent 6 }}
      ports:
        - name: http
          containerPort: {{ .Values.compactor.service.port }}
      volumeMounts:
        - name: data
          mountPath: /var/thanos/compact
        - name: objstore
          mountPath: /etc/thanos
          readOnly: true
        {{- include "thanos.extraMountItems" (dict "root" . "key" "compactor") | nindent 8 }}
      {{- include "thanos.containerSC" (dict "root" . "key" "compactor") | nindent 6 }}
      resources:
        {{- toYaml .Values.compactor.resources | nindent 8 }}
      {{- include "thanos.httpProbes" (dict "root" . "key" "compactor") | nindent 6 }}
    {{- include "thanos.extraContainers" (dict "Values" .Values "component" "compactor" "root" .) | nindent 4 }}
  {{- include "thanos.dnsConfig" (dict "Values" .Values "component" "compactor") | nindent 2 }}
  {{- include "thanos.initContainers" (dict "Values" .Values "component" "compactor" "root" .) | nindent 2 }}
  {{- include "thanos.nodeSelector" (dict "Values" .Values "component" "compactor") | nindent 2 }}
  {{- include "thanos.priorityClassName" (dict "Values" .Values "component" "compactor") | nindent 2 }}
  {{- include "thanos.tolerations" (dict "Values" .Values "component" "compactor") | nindent 2 }}
  {{- include "thanos.topologySpreadConstraints" (dict "Values" .Values "component" "compactor") | nindent 2 }}
  volumes:
    - name: objstore
      secret:
        secretName: {{ .Values.global.objstore.secretName }}
        items:
          - key: {{ .Values.global.objstore.secretKey }}
            path: objstore.yml
    {{- if not .Values.compactor.persistence.enabled }}
    - name: data
      emptyDir: {}
    {{- end }}
    {{- if and .Values.compactor.persistence.enabled .Values.compactor.persistence.existingClaim }}
    - name: data
      persistentVolumeClaim:
        claimName: {{ .Values.compactor.persistence.existingClaim }}
    {{- end }}
    {{- if and $cron .Values.compactor.persistence.enabled (not .Values.compactor.persistence.existingClaim) }}
    {{- /* A CronJob has no volumeClaimTemplates: each run gets a fresh claim, deleted with its pod. */}}
    - name: data
      ephemeral:
        volumeClaimTemplate:
          metadata:
            labels:
              {{- include "thanos.labels" . | nindent 14 }}
              app.kubernetes.io/component: compactor
          spec:
            accessModes:
            {{- range .Values.compactor.persistence.accessModes | default (list "ReadWriteOnce") }}
              - {{ . | quote }}
            {{- end }}
            {{- include "thanos.storageClass" (dict "root" . "key" "compactor" "persistence" .Values.compactor.persistence) | indent 12 }}
            resources:
              requests:
                storage: {{ .Values.compactor.persistence.size }}
    {{- end }}
    {{- include "thanos.extraVolumeItems" (dict "root" . "key" "compactor") | nindent 4 }}
{{- end -}}
{{- end -}}
