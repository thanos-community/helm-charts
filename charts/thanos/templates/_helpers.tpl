{{- define "thanos.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "thanos.fullname" -}}
{{- $name := include "thanos.name" . -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "thanos.compName" -}}
{{- $root := index . 0 -}}
{{- $comp := index . 1 -}}
{{- printf "%s-%s" (include "thanos.fullname" $root) $comp | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "thanos.labels" -}}
app.kubernetes.io/name: {{ include "thanos.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: thanos
{{- range $k, $v := .Values.global.commonLabels }}
{{ $k }}: {{ $v | quote }}
{{- end }}
{{- end -}}


{{- define "thanos.annotations" -}}
{{- $component := .component -}}
{{- $annotations := dict -}}

{{- if .Values.global.podAnnotations }}
  {{- $annotations = merge $annotations .Values.global.podAnnotations }}
{{- end }}

{{- with (index .Values $component).podAnnotations }}
  {{- $annotations = merge $annotations . }}
{{- end }}

{{- if $annotations }}
{{ toYaml $annotations | indent 2 }}
{{- end }}
{{- end }}

{{- define "thanos.podSC" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $comp := index $root.Values $key | default dict -}}
{{- $psc := $comp.podSecurityContext | default $root.Values.global.podSecurityContext -}}
{{- if $psc }}
securityContext:
{{ toYaml $psc | nindent 2 }}
{{- end }}
{{- end }}

{{- define "thanos.containerSC" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $comp := index $root.Values $key | default dict -}}
{{- $csc := $comp.containerSecurityContext | default $root.Values.global.containerSecurityContext -}}
{{- if $csc }}
securityContext:
{{ toYaml $csc | nindent 2 }}
{{- end }}
{{- end }}

{{- define "thanos.httpProbes" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $port := .port -}}
{{- $comp := index $root.Values $key | default dict -}}
{{- $probes := $comp.probes | default dict -}}
{{- with $probes.readiness }}
{{- if .enabled }}
readinessProbe:
  httpGet:
    path: {{ default "/-/ready" .path | quote }}
    port: {{ default $port .port }}
  initialDelaySeconds: {{ default 5 .initialDelaySeconds }}
  periodSeconds: {{ default 10 .periodSeconds }}
  timeoutSeconds: {{ default 5 .timeoutSeconds }}
  failureThreshold: {{ default 6 .failureThreshold }}
  successThreshold: {{ default 1 .successThreshold }}
{{- end }}
{{- end }}
{{- with $probes.liveness }}
{{- if .enabled }}
livenessProbe:
  httpGet:
    path: {{ default "/-/healthy" .path | quote }}
    port: {{ default $port .port }}
  initialDelaySeconds: {{ default 30 .initialDelaySeconds }}
  periodSeconds: {{ default 10 .periodSeconds }}
  timeoutSeconds: {{ default 5 .timeoutSeconds }}
  failureThreshold: {{ default 6 .failureThreshold }}
  successThreshold: {{ default 1 .successThreshold }}
{{- end }}
{{- end }}
{{- with $probes.startup }}
{{- if .enabled }}
startupProbe:
  httpGet:
    path: {{ default "/-/ready" .path | quote }}
    port: {{ default $port .port }}
  initialDelaySeconds: {{ default 0 .initialDelaySeconds }}
  periodSeconds: {{ default 5 .periodSeconds }}
  timeoutSeconds: {{ default 5 .timeoutSeconds }}
  failureThreshold: {{ default 60 .failureThreshold }}
  successThreshold: {{ default 1 .successThreshold }}
{{- end }}
{{- end }}
{{- end }}

{{- define "thanos.extraVolumeItems" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $comp := index $root.Values $key | default dict -}}
{{- $glob := $root.Values.global | default dict -}}
{{- $volsGlob := $glob.extraVolumes | default list -}}
{{- $volsComp := $comp.extraVolumes | default list -}}
{{- range $volsGlob }}
- {{ toYaml . | nindent 2 }}
{{- end }}
{{- range $volsComp }}
- {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "thanos.extraVolumesBlock" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $comp := index $root.Values $key | default dict -}}
{{- $glob := $root.Values.global | default dict -}}
{{- $volsGlob := $glob.extraVolumes | default list -}}
{{- $volsComp := $comp.extraVolumes | default list -}}
{{- if or (gt (len $volsGlob) 0) (gt (len $volsComp) 0) }}
volumes:
{{ include "thanos.extraVolumeItems" (dict "root" $root "key" $key) | nindent 0 }}
{{- end }}
{{- end }}

{{- define "thanos.extraMountItems" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $comp := index $root.Values $key | default dict -}}
{{- $glob := $root.Values.global | default dict -}}
{{- $mtsGlob := $glob.extraVolumeMounts | default list -}}
{{- $mtsComp := $comp.extraVolumeMounts | default list -}}
{{- range $mtsGlob }}
- {{ toYaml . | nindent 2 }}
{{- end }}
{{- range $mtsComp }}
- {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "thanos.extraMountsBlock" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $comp := index $root.Values $key | default dict -}}
{{- $glob := $root.Values.global | default dict -}}
{{- $mtsGlob := $glob.extraVolumeMounts | default list -}}
{{- $mtsComp := $comp.extraVolumeMounts | default list -}}
{{- if or (gt (len $mtsGlob) 0) (gt (len $mtsComp) 0) }}
volumeMounts:
{{ include "thanos.extraMountItems" (dict "root" $root "key" $key) | nindent 0 }}
{{- end }}
{{- end }}


{{- /* ============================== */ -}}
{{- /* Receive headless service name  */ -}}
{{- /* ============================== */ -}}
{{- define "thanos.receiveHeadless" -}}
{{- printf "%s-%s" (include "thanos.fullname" .) "receive-headless" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- /* ============================== */ -}}
{{- /* Receive hashrings helpers      */ -}}
{{- /* ============================== */ -}}

{{- define "thanos.receive.hashringsConfigMapName" -}}
{{- include "thanos.compName" (list . "receive-hashrings") -}}
{{- end -}}

{{- define "thanos.receive.hashrings" -}}
{{- $vals := .Values.receive | default dict -}}
{{- $grpcPort := int (dig "service" "grpcPort" 10901 $vals) -}}
{{- $rc := int (default 1 $vals.replicaCount) -}}
{{- $ns := .Release.Namespace -}}
{{- $domain := .Values.global.clusterDomain | default "cluster.local" -}}

{{- if and (hasKey $vals "hashrings") (hasKey $vals.hashrings "static") (gt (len $vals.hashrings.static) 0) -}}
{{ $vals.hashrings.static | toPrettyJson }}

{{- else if and (hasKey $vals "hashrings") (hasKey $vals.hashrings "autogen") ($vals.hashrings.autogen.enabled | default false) -}}
  {{- $name := include "thanos.compName" (list . "receive") -}}
  {{- $svcName := include "thanos.receiveHeadless" . -}}
  {{- $eps := list -}}
  {{- range $i, $_ := until $rc -}}
    {{- $ep := printf "%s-%d.%s.%s.svc.%s:%d" $name $i $svcName $ns $domain $grpcPort -}}
    {{- $eps = append $eps $ep -}}
  {{- end -}}
  {{- $rings := list (dict "endpoints" $eps) -}}
{{ $rings | toPrettyJson }}

{{- else -}}
  {{- $name := include "thanos.compName" (list . "receive") -}}
  {{- $svcName := include "thanos.receiveHeadless" . -}}
  {{- $eps := list (printf "%s-0.%s.%s.svc.%s:%d" $name $svcName $ns $domain $grpcPort) -}}
  {{- $rings := list (dict "endpoints" $eps) -}}
{{ $rings | toPrettyJson }}
{{- end -}}
{{- end -}}

{{/*
Resolve the ServiceAccount name.
If global.serviceAccount.create is true, we default to "<release>-thanos"
unless a name is provided. If create is false, we must use the provided name.
*/}}
{{- define "thanos.serviceAccountName" -}}
{{- $name := default (printf "%s-%s" (include "thanos.fullname" .) "thanos") .Values.global.serviceAccount.name -}}
{{- if .Values.global.serviceAccount.create -}}
{{- $name -}}
{{- else -}}
{{- $name -}}
{{- end -}}
{{- end -}}

{{/*
Render imagePullSecrets from global.image.imagePullSecrets if any
*/}}
{{- define "thanos.imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets }}
imagePullSecrets:
{{ toYaml .Values.global.imagePullSecrets | indent 2 }}
{{- end }}
{{- end -}}