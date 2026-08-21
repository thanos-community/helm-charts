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

{{- /*
Resolve the namespace all chart resources are deployed into.
Defaults to the release namespace unless `.Values.namespaceOverride` overrides it.
*/ -}}
{{- define "thanos.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride -}}
{{- end -}}

{{- define "thanos.compName" -}}
{{- $root := index . 0 -}}
{{- $comp := index . 1 -}}
{{- printf "%s-%s" (include "thanos.fullname" $root) $comp | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- /*
Selector labels identifying the pods of a single component. Rendered into every
`spec.selector` / `spec.podSelector` in the chart and always a subset of the pod
template labels produced by `thanos.labels`.

`app.kubernetes.io/name` is part of the set so that an umbrella chart deploying
another application under the same release name and namespace cannot collide:
`component: compactor` + `instance: <release>` alone also matches, say, a Loki
compactor.

Deliberately excludes `global.commonLabels` and `app.kubernetes.io/part-of`:
workload selectors are immutable, so anything user-tunable must stay out of them.

The root context is passed explicitly because callers such as the Store Gateway
templates render selectors inside a `range` where `.` is the shard, not the root.
`component` is optional.
Usage:
  {{- include "thanos.selectorLabels" (dict "root" $ "component" "compactor") | nindent 6 }}
*/ -}}
{{- define "thanos.selectorLabels" -}}
{{- $root := .root -}}
app.kubernetes.io/name: {{ include "thanos.name" $root }}
app.kubernetes.io/instance: {{ $root.Release.Name }}
{{- with .component }}
app.kubernetes.io/component: {{ . }}
{{- end }}
{{- end -}}

{{- /*
Labels stamped on every resource the chart renders: the selector labels plus the
chart-wide `part-of` marker and any `global.commonLabels`.
*/ -}}
{{- define "thanos.labels" -}}
{{- include "thanos.selectorLabels" (dict "root" .) }}
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
{{- toYaml $annotations }}
{{- end }}
{{- end }}

{{- /*
Render a pod-level securityContext block with component → (optional parent) → global fallback.
Usage:
  {{ include "thanos.podSC" (dict "root" . "key" "compactor") }}
  {{ include "thanos.podSC" (dict "root" . "key" "router" "parent" "receive") }}
*/ -}}
{{- define "thanos.podSC" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $comp := dict -}}
{{- if $parent -}}
{{- $par = index $root.Values $parent | default dict -}}
{{- $comp = index $par $key | default dict -}}
{{- else -}}
{{- $comp = index $root.Values $key | default dict -}}
{{- end -}}
{{- $psc := $comp.podSecurityContext | default $par.podSecurityContext | default $root.Values.global.podSecurityContext -}}
{{- if $psc }}
securityContext:
  {{- toYaml $psc | nindent 2 }}
{{- end }}
{{- end }}

{{- /*
Render a container-level securityContext block with component → (optional parent) → global fallback.
Usage:
  {{ include "thanos.containerSC" (dict "root" . "key" "compactor") }}
  {{ include "thanos.containerSC" (dict "root" . "key" "router" "parent" "receive") }}
*/ -}}
{{- define "thanos.containerSC" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $comp := dict -}}
{{- if $parent -}}
{{- $par = index $root.Values $parent | default dict -}}
{{- $comp = index $par $key | default dict -}}
{{- else -}}
{{- $comp = index $root.Values $key | default dict -}}
{{- end -}}
{{- $csc := $comp.containerSecurityContext | default $par.containerSecurityContext | default $root.Values.global.containerSecurityContext -}}
{{- if $csc }}
securityContext:
  {{- toYaml $csc | nindent 2 }}
{{- end }}
{{- end }}

{{- /*
Render fully qualified Docker image reference (registry, image name, tag).
Usage:
  {{ include "thanos.image" (dict "root" . "image" .global.image) }}
*/ -}}
{{- define "thanos.image" -}}
{{- $root := .root -}}
{{- $image := .image }}
{{- $registry := "" }}
{{- with $image.registry }}
{{- $registry = printf "%s/" . }}
{{- end }}
{{- $tag := $image.tag | default $root.Chart.AppVersion }}
{{- printf "%s%s:%s" $registry $image.repository $tag }}
{{- end }}

{{- /*
Render container security context for the Ruler PrometheusRule importer sidecar.
It inherits the Ruler/global security context and defaults runAsUser to nobody
because the kubectl image otherwise runs as root while runAsNonRoot is enabled.
*/ -}}
{{- define "thanos.ruler.autoImportPrometheusRules.containerSC" -}}
{{- $base := dict "runAsUser" 65534 -}}
{{- $csc := .Values.ruler.containerSecurityContext | default .Values.global.containerSecurityContext -}}
{{- if $csc -}}
{{- $base = mergeOverwrite $base (deepCopy $csc) -}}
{{- end -}}
securityContext:
  {{- toYaml $base | nindent 2 }}
{{- end }}

{{- /*
Render extra pod labels for a component with component → (optional parent) fallback.
Returns the labels as YAML (no leading newline); empty when none are set.
Usage:
  {{- include "thanos.podLabels" (dict "root" . "key" "compactor") | nindent 8 }}
  {{- include "thanos.podLabels" (dict "root" . "key" "ingester" "parent" "receive") | nindent 8 }}
*/ -}}
{{- define "thanos.podLabels" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $comp := dict -}}
{{- if $parent -}}
{{- $par = index $root.Values $parent | default dict -}}
{{- $comp = index $par $key | default dict -}}
{{- else -}}
{{- $comp = index $root.Values $key | default dict -}}
{{- end -}}
{{- $podLabels := $comp.podLabels | default $par.podLabels -}}
{{- with $podLabels }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{- /*
Render dnsConfig with component → (optional parent) → global fallback.
Usage:
  {{ include "thanos.dnsConfig" (dict "Values" .Values "component" "compactor") }}
  {{ include "thanos.dnsConfig" (dict "Values" .Values "component" "router" "parent" "receive") }}
*/ -}}
{{- define "thanos.dnsConfig" -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $component := dict -}}
{{- if $parent -}}
{{- $par = index .Values $parent | default dict -}}
{{- $component = index $par .component | default dict -}}
{{- else -}}
{{- $component = (index .Values .component) | default dict -}}
{{- end -}}
{{- with ($component.dnsConfig | default $par.dnsConfig | default .Values.global.dnsConfig) -}}
dnsConfig:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- /*
Render readiness/liveness/startup probes with component → (optional parent) → global fallback.
Usage:
  {{ include "thanos.httpProbes" (dict "root" . "key" "compactor") }}
  {{ include "thanos.httpProbes" (dict "root" . "key" "router" "parent" "receive") }}
*/ -}}
{{- define "thanos.httpProbes" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $comp := dict -}}
{{- if $parent -}}
{{- $par = index $root.Values $parent | default dict -}}
{{- $comp = index $par $key | default dict -}}
{{- else -}}
{{- $comp = index $root.Values $key | default dict -}}
{{- end -}}
{{- $probes := $comp.probes | default $par.probes | default dict -}}
{{- with $probes.readiness }}
{{- if .enabled }}
readinessProbe:
  httpGet:
    path: {{ default "/-/ready" .path | quote }}
    port: http
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
    port: http
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
    port: http
  initialDelaySeconds: {{ default 0 .initialDelaySeconds }}
  periodSeconds: {{ default 5 .periodSeconds }}
  timeoutSeconds: {{ default 5 .timeoutSeconds }}
  failureThreshold: {{ default 60 .failureThreshold }}
  successThreshold: {{ default 1 .successThreshold }}
{{- end }}
{{- end }}
{{- end }}

{{- /*
Render volume attribute class name. Fail if provided but not supported.
Usage:
  {{ include "thanos.volumeAttributesClassName" (dict "root" . "key" "compactor" "persistence" .Values.compactor.persistence ) }}
*/ -}}
{{- define "thanos.volumeAttributesClassName" }}
{{- $root := .root }}
{{- $key := .key }}
{{- $persistence := .persistence }}
{{- with $persistence.volumeAttributesClassName }}
  {{- if not ($root.Capabilities.APIVersions.Has "storage.k8s.io/v1/VolumeAttributesClass") }}
  {{-   printf "volumeAttributesClassName has been specified for '%s'. However, 'storage.k8s.io/v1/VolumeAttributesClass' isn't supported" $key | fail }}
  {{- end }}
volumeAttributesClassName: {{ . | quote }}
{{- end }}
{{- end }}

{{- /*
Render the storage-class fields of a PVC spec: `storageClassName`, taken from the
component's own `persistence.storageClass` and falling back to the chart-wide
`global.storageClass` when it is empty, followed by `volumeAttributesClassName`.
Renders nothing when neither is set, so the cluster default StorageClass applies.
Usage:
  {{ include "thanos.storageClass" (dict "root" . "key" "compactor" "persistence" .Values.compactor.persistence) }}
*/ -}}
{{- define "thanos.storageClass" }}
{{- $sc := .persistence.storageClass | default .root.Values.global.storageClass }}
{{- with $sc }}
storageClassName: {{ . | quote }}
{{- end }}
{{- include "thanos.volumeAttributesClassName" (dict "root" .root "key" .key "persistence" .persistence) }}
{{- end }}

{{- /*
Render extra volume entries (concatenated) from global, optional parent, then component.
Usage:
  {{ include "thanos.extraVolumeItems" (dict "root" . "key" "compactor") }}
  {{ include "thanos.extraVolumeItems" (dict "root" . "key" "router" "parent" "receive") }}
*/ -}}
{{- define "thanos.extraVolumeItems" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $comp := dict -}}
{{- if $parent -}}
{{- $par = index $root.Values $parent | default dict -}}
{{- $comp = index $par $key | default dict -}}
{{- else -}}
{{- $comp = index $root.Values $key | default dict -}}
{{- end -}}
{{- $glob := $root.Values.global | default dict -}}
{{- $volsGlob := $glob.extraVolumes | default list -}}
{{- $volsPar := $par.extraVolumes | default list -}}
{{- $volsComp := $comp.extraVolumes | default list -}}
{{- range $volsGlob }}
- {{ toYaml . | nindent 2 }}
{{- end }}
{{- range $volsPar }}
- {{ toYaml . | nindent 2 }}
{{- end }}
{{- range $volsComp }}
- {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "thanos.extraVolumesBlock" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $comp := dict -}}
{{- if $parent -}}
{{- $par = index $root.Values $parent | default dict -}}
{{- $comp = index $par $key | default dict -}}
{{- else -}}
{{- $comp = index $root.Values $key | default dict -}}
{{- end -}}
{{- $glob := $root.Values.global | default dict -}}
{{- $volsGlob := $glob.extraVolumes | default list -}}
{{- $volsPar := $par.extraVolumes | default list -}}
{{- $volsComp := $comp.extraVolumes | default list -}}
{{- if or (gt (len $volsGlob) 0) (gt (len $volsPar) 0) (gt (len $volsComp) 0) }}
volumes:
  {{- include "thanos.extraVolumeItems" (dict "root" $root "key" $key "parent" $parent) | nindent 2 }}
{{- end }}
{{- end }}

{{- /*
Render extra volume-mount entries (concatenated) from global, optional parent, then component.
Usage:
  {{ include "thanos.extraMountItems" (dict "root" . "key" "compactor") }}
  {{ include "thanos.extraMountItems" (dict "root" . "key" "router" "parent" "receive") }}
*/ -}}
{{- define "thanos.extraMountItems" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $comp := dict -}}
{{- if $parent -}}
{{- $par = index $root.Values $parent | default dict -}}
{{- $comp = index $par $key | default dict -}}
{{- else -}}
{{- $comp = index $root.Values $key | default dict -}}
{{- end -}}
{{- $glob := $root.Values.global | default dict -}}
{{- $mtsGlob := $glob.extraVolumeMounts | default list -}}
{{- $mtsPar := $par.extraVolumeMounts | default list -}}
{{- $mtsComp := $comp.extraVolumeMounts | default list -}}
{{- range $mtsGlob }}
- {{ toYaml . | nindent 2 }}
{{- end }}
{{- range $mtsPar }}
- {{ toYaml . | nindent 2 }}
{{- end }}
{{- range $mtsComp }}
- {{ toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "thanos.extraMountsBlock" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $comp := dict -}}
{{- if $parent -}}
{{- $par = index $root.Values $parent | default dict -}}
{{- $comp = index $par $key | default dict -}}
{{- else -}}
{{- $comp = index $root.Values $key | default dict -}}
{{- end -}}
{{- $glob := $root.Values.global | default dict -}}
{{- $mtsGlob := $glob.extraVolumeMounts | default list -}}
{{- $mtsPar := $par.extraVolumeMounts | default list -}}
{{- $mtsComp := $comp.extraVolumeMounts | default list -}}
{{- if or (gt (len $mtsGlob) 0) (gt (len $mtsPar) 0) (gt (len $mtsComp) 0) }}
volumeMounts:
  {{- include "thanos.extraMountItems" (dict "root" $root "key" $key "parent" $parent) | nindent 2 }}
{{- end }}
{{- end }}

{{- /* ============================== */ -}}
{{- /* Scheduling and placement       */ -}}
{{- /* ============================== */ -}}

{{- /*
Scheduling helpers: each renders a single field with
  component → (optional parent) → global fallback.

Standard usage:
  {{ include "thanos.affinity" (dict "Values" .Values "component" "compactor") }}

Nested usage (e.g. receive.router falls back to receive then global):
  {{ include "thanos.affinity" (dict "Values" .Values "component" "router" "parent" "receive") }}
*/ -}}
{{- define "thanos.affinity" -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $component := dict -}}
{{- if $parent -}}
{{- $par = index .Values $parent | default dict -}}
{{- $component = index $par .component | default dict -}}
{{- else -}}
{{- $component = index .Values .component | default dict -}}
{{- end -}}
{{- with ($component.affinity | default $par.affinity | default .Values.global.affinity) -}}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "thanos.nodeSelector" -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $component := dict -}}
{{- if $parent -}}
{{- $par = index .Values $parent | default dict -}}
{{- $component = index $par .component | default dict -}}
{{- else -}}
{{- $component = index .Values .component | default dict -}}
{{- end -}}
{{- with ($component.nodeSelector | default $par.nodeSelector | default .Values.global.nodeSelector) -}}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "thanos.priorityClassName" -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $component := dict -}}
{{- if $parent -}}
{{- $par = index .Values $parent | default dict -}}
{{- $component = index $par .component | default dict -}}
{{- else -}}
{{- $component = index .Values .component | default dict -}}
{{- end -}}
{{- with ($component.priorityClassName | default $par.priorityClassName | default .Values.global.priorityClassName) -}}
priorityClassName: {{ . }}
{{- end }}
{{- end }}

{{- define "thanos.tolerations" -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $component := dict -}}
{{- if $parent -}}
{{- $par = index .Values $parent | default dict -}}
{{- $component = index $par .component | default dict -}}
{{- else -}}
{{- $component = index .Values .component | default dict -}}
{{- end -}}
{{- with ($component.tolerations | default $par.tolerations | default .Values.global.tolerations) -}}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "thanos.topologySpreadConstraints" -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $component := dict -}}
{{- if $parent -}}
{{- $par = index .Values $parent | default dict -}}
{{- $component = index $par .component | default dict -}}
{{- else -}}
{{- $component = index .Values .component | default dict -}}
{{- end -}}
{{- with ($component.topologySpreadConstraints | default $par.topologySpreadConstraints | default .Values.global.topologySpreadConstraints) -}}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{- /* ============================== */ -}}
{{- /* Extra env / envFrom helpers    */ -}}
{{- /* ============================== */ -}}

{{- /*
Render merged extraEnv items (global → optional parent → component, by name).
Usage:
  {{ include "thanos.extraEnvItems" (dict "Values" .Values "component" "compactor") }}
  {{ include "thanos.extraEnvItems" (dict "Values" .Values "component" "router" "parent" "receive") }}
*/ -}}
{{- define "thanos.extraEnvItems" -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $component := dict -}}
{{- if $parent -}}
{{- $par = index .Values $parent | default dict -}}
{{- $component = index $par .component | default dict -}}
{{- else -}}
{{- $component = index .Values .component | default dict -}}
{{- end -}}
{{- $merged := dict -}}
{{- range (.Values.global.extraEnv | default list) }}
{{- $_ := set $merged .name . }}
{{- end }}
{{- range ($par.extraEnv | default list) }}
{{- $_ := set $merged .name . }}
{{- end }}
{{- range ($component.extraEnv | default list) }}
{{- $_ := set $merged .name . }}
{{- end }}
{{- range (keys $merged | sortAlpha) }}
- {{ toYaml (index $merged .) | nindent 2 }}
{{- end }}
{{- end }}

{{- define "thanos.extraEnvBlock" -}}
{{- if include "thanos.extraEnvItems" . }}
env:
  {{- include "thanos.extraEnvItems" . | nindent 2 }}
{{- end }}
{{- end }}

{{- define "thanos.podEnvBlock" -}}
env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
{{- include "thanos.extraEnvItems" . | nindent 2 }}
{{- include "thanos.extraEnvFromBlock" . }}
{{- end }}

{{- define "thanos.extraEnvFromItems" -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $component := dict -}}
{{- if $parent -}}
{{- $par = index .Values $parent | default dict -}}
{{- $component = index $par .component | default dict -}}
{{- else -}}
{{- $component = index .Values .component | default dict -}}
{{- end -}}
{{- $merged := dict -}}
{{- range (.Values.global.extraEnvFrom | default list) }}
{{- $_ := set $merged .name . }}
{{- end }}
{{- range ($par.extraEnvFrom | default list) }}
{{- $_ := set $merged .name . }}
{{- end }}
{{- range ($component.extraEnvFrom | default list) }}
{{- $_ := set $merged .name . }}
{{- end }}
{{- range (keys $merged | sortAlpha) }}
- {{ toYaml (index $merged .) | nindent 2 }}
{{- end }}
{{- end }}

{{- define "thanos.extraEnvFromBlock" -}}
{{- if include "thanos.extraEnvFromItems" . }}
envFrom:
  {{- include "thanos.extraEnvFromItems" . | nindent 2 }}
{{- end }}
{{- end }}

{{- /* ============================== */ -}}
{{- /* Init / sidecar containers      */ -}}
{{- /* ============================== */ -}}

{{- /*
Render initContainers (concatenated) from global, optional parent, then component.
Usage:
  {{ include "thanos.initContainers" (dict "Values" .Values "component" "compactor" "root" .) }}
  {{ include "thanos.initContainers" (dict "Values" .Values "component" "router" "parent" "receive" "root" .) }}
*/ -}}
{{- define "thanos.initContainers" -}}
{{- $root := .root -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $component := dict -}}
{{- if $parent -}}
{{- $par = index .Values $parent | default dict -}}
{{- $component = index $par .component | default dict -}}
{{- else -}}
{{- $component = (index .Values .component) | default dict -}}
{{- end -}}
{{- $icGlob := .Values.global.extraInitContainers | default list -}}
{{- $icPar := $par.extraInitContainers | default list -}}
{{- $icComp := $component.extraInitContainers | default list -}}
{{- if or (gt (len $icGlob) 0) (gt (len $icPar) 0) (gt (len $icComp) 0) }}
initContainers:
  {{- range $icGlob }}
  - {{ tpl (toYaml .) $root | nindent 4 }}
  {{- end }}
  {{- range $icPar }}
  - {{ tpl (toYaml .) $root | nindent 4 }}
  {{- end }}
  {{- range $icComp }}
  - {{ tpl (toYaml .) $root | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}

{{- /*
Render extra sidecar containers (concatenated) from global, optional parent, then component.
Usage:
  {{ include "thanos.extraContainers" (dict "Values" .Values "component" "compactor" "root" .) }}
  {{ include "thanos.extraContainers" (dict "Values" .Values "component" "router" "parent" "receive" "root" .) }}
*/ -}}
{{- define "thanos.extraContainers" -}}
{{- $root := .root -}}
{{- $parent := .parent | default "" -}}
{{- $par := dict -}}
{{- $component := dict -}}
{{- if $parent -}}
{{- $par = index .Values $parent | default dict -}}
{{- $component = index $par .component | default dict -}}
{{- else -}}
{{- $component = (index .Values .component) | default dict -}}
{{- end -}}
{{- $cGlob := .Values.global.extraContainers | default list -}}
{{- $cPar := $par.extraContainers | default list -}}
{{- $cComp := $component.extraContainers | default list -}}
{{- range $cGlob }}
- {{ tpl (toYaml .) $root | nindent 2 }}
{{- end }}
{{- range $cPar }}
- {{ tpl (toYaml .) $root | nindent 2 }}
{{- end }}
{{- range $cComp }}
- {{ tpl (toYaml .) $root | nindent 2 }}
{{- end }}
{{- end }}

{{- /* ============================== */ -}}
{{- /* Receive split-mode helpers     */ -}}
{{- /* ============================== */ -}}

{{- /*
Returns the resolved receive mode. Defaults to "standalone".
Accepted values: "standalone", "split".
*/ -}}
{{- define "thanos.receive.mode" -}}
{{- default "standalone" .Values.receive.mode -}}
{{- end -}}

{{- define "thanos.receive.isSplit" -}}
{{- if eq (include "thanos.receive.mode" .) "split" -}}true{{- end -}}
{{- end -}}

{{- /*
Returns the resolved Ingester values block as YAML.
  - standalone mode → returns the top-level `receive.*` block
  - split mode      → returns the `receive.ingester.*` block
Use with `fromYaml` to get a dict:
  {{ $cfg := include "thanos.receive.cfg" . | fromYaml }}
*/ -}}
{{- define "thanos.receive.cfg" -}}
{{- if eq (include "thanos.receive.mode" .) "split" -}}
{{- toYaml (.Values.receive.ingester | default dict) -}}
{{- else -}}
{{- toYaml .Values.receive -}}
{{- end -}}
{{- end -}}

{{- /*
Resolved name for the Receive (StatefulSet) workload and its associated
resources. In standalone mode this is `<fullname>-receive` (unchanged).
In split mode the name is suffixed with `-ingester` so the StatefulSet,
service, ServiceMonitor, etc. become `<fullname>-receive-ingester`.
The Ingester reads its values from `receive.ingester.*` in split mode,
or from the top-level `receive.*` fields in standalone mode (see
`thanos.receive.cfg`).
*/ -}}
{{- define "thanos.receive.workloadName" -}}
{{- if eq (include "thanos.receive.mode" .) "split" -}}
{{- include "thanos.compName" (list . "receive-ingester") -}}
{{- else -}}
{{- include "thanos.compName" (list . "receive") -}}
{{- end -}}
{{- end -}}

{{- /* Router resource name: <fullname>-receive-router. Only used in split mode. */ -}}
{{- define "thanos.receive.routerName" -}}
{{- include "thanos.compName" (list . "receive-router") -}}
{{- end -}}

{{- /* ============================== */ -}}
{{- /* Receive headless service name  */ -}}
{{- /* Returns                        */ -}}
{{- /*  - <fullname>-receive-headless         (standalone)                */ -}}
{{- /*  - <fullname>-receive-ingester-headless (split)                    */ -}}
{{- /* ============================== */ -}}
{{- define "thanos.receiveHeadless" -}}
{{- printf "%s-%s" (include "thanos.receive.workloadName" .) "headless" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- /* ============================== */ -}}
{{- /* Receive hashrings helpers      */ -}}
{{- /* ============================== */ -}}

{{- define "thanos.receive.hashringsConfigMapName" -}}
{{- include "thanos.compName" (list . "receive-hashrings") -}}
{{- end -}}

{{- /*
Render the hashrings JSON. Endpoints reference the Receive workload pods
via its headless service. The workload name is resolved by
`thanos.receive.workloadName` (`-ingester` suffix in split mode), so the
same helper produces a valid hashring for both standalone and split modes.
*/ -}}
{{- define "thanos.receive.hashrings" -}}
{{- $vals := include "thanos.receive.cfg" . | fromYaml -}}
{{- $grpcPort := int (dig "service" "grpcPort" 10901 $vals) -}}
{{- $rc := int (default 1 $vals.replicaCount) -}}
{{- $ns := include "thanos.namespace" . -}}
{{- $domain := .Values.global.clusterDomain | default "cluster.local" -}}

{{- if and (hasKey $vals "hashrings") (hasKey $vals.hashrings "static") (gt (len $vals.hashrings.static) 0) -}}
{{ $vals.hashrings.static | toPrettyJson }}

{{- else if and (hasKey $vals "hashrings") (hasKey $vals.hashrings "autogen") ($vals.hashrings.autogen.enabled | default false) -}}
  {{- $name := include "thanos.receive.workloadName" . -}}
  {{- $svcName := include "thanos.receiveHeadless" . -}}
  {{- $eps := list -}}
  {{- range $i, $_ := until $rc -}}
    {{- $ep := printf "%s-%d.%s.%s.svc.%s:%d" $name $i $svcName $ns $domain $grpcPort -}}
    {{- $eps = append $eps $ep -}}
  {{- end -}}
  {{- $rings := list (dict "endpoints" $eps) -}}
{{ $rings | toPrettyJson }}

{{- else -}}
  {{- $name := include "thanos.receive.workloadName" . -}}
  {{- $svcName := include "thanos.receiveHeadless" . -}}
  {{- $eps := list (printf "%s-0.%s.%s.svc.%s:%d" $name $svcName $ns $domain $grpcPort) -}}
  {{- $rings := list (dict "endpoints" $eps) -}}
{{ $rings | toPrettyJson }}
{{- end -}}
{{- end -}}

{{- /* ============================== */ -}}
{{- /* Store Gateway sharding helpers  */ -}}
{{- /* ============================== */ -}}

{{- /*
Returns "true" when Store Gateway sharding is enabled
(storegateway.sharded.enabled). Empty string otherwise.
*/ -}}
{{- define "thanos.storegateway.sharded" -}}
{{- if and .Values.storegateway.sharded .Values.storegateway.sharded.enabled -}}true{{- end -}}
{{- end -}}

{{- /*
Computes the list of Store Gateway shards and returns it as YAML under a
top-level `shards` key. Consume with:
  {{ $shards := (include "thanos.storegateway.shards" . | fromYaml).shards }}

Each shard is a dict with:
  - index    sequential shard number (0-based)
  - name     StatefulSet/resource name (`<fullname>-storegateway[-<index>]`)
  - isSharded whether sharding is enabled (drives the shard selector label)
  - minTime / maxTime  optional, from timePartitioning (--min-time/--max-time)
  - relabelConfigs     optional list, rendered into --selector.relabel-config

When sharding is disabled a single shard is returned with the unsuffixed
name and no extras, so callers can range uniformly without changing the
output of non-sharded deployments.

The total shard count is the cross-product of timePartitioning entries and
hashPartitioning.shards: each time partition is split into `shards` hash
shards (hashmod on __block_id). Either dimension may be used on its own.
*/ -}}
{{- define "thanos.storegateway.shards" -}}
{{- $base := include "thanos.compName" (list . "storegateway") -}}
{{- $shards := list -}}
{{- if eq (include "thanos.storegateway.sharded" .) "true" -}}
  {{- $s := .Values.storegateway.sharded -}}
  {{- $hashShards := int (dig "hashPartitioning" "shards" 1 $s) -}}
  {{- $extra := dig "hashPartitioning" "extraRelabelingConfigs" (list) $s -}}
  {{- $timeParts := $s.timePartitioning | default (list) -}}
  {{- $useTime := gt (len $timeParts) 0 -}}
  {{- $useHash := gt $hashShards 1 -}}
  {{- $timeIter := $timeParts -}}
  {{- if not $useTime -}}{{- $timeIter = list (dict) -}}{{- end -}}
  {{- $hashCount := 1 -}}
  {{- if $useHash -}}{{- $hashCount = $hashShards -}}{{- end -}}
  {{- $index := 0 -}}
  {{- range $tp := $timeIter -}}
    {{- range $h := until $hashCount -}}
      {{- $shard := dict "index" $index "name" (printf "%s-%d" $base $index) "isSharded" true -}}
      {{- if and $useTime $tp.min -}}{{- $_ := set $shard "minTime" $tp.min -}}{{- end -}}
      {{- if and $useTime $tp.max -}}{{- $_ := set $shard "maxTime" $tp.max -}}{{- end -}}
      {{- $rc := list -}}
      {{- range $extra -}}{{- $rc = append $rc . -}}{{- end -}}
      {{- if $useHash -}}
        {{- $rc = append $rc (dict "action" "hashmod" "source_labels" (list "__block_id") "target_label" "shard" "modulus" $hashShards) -}}
        {{- $rc = append $rc (dict "action" "keep" "source_labels" (list "shard") "regex" (printf "%d" $h)) -}}
      {{- end -}}
      {{- if gt (len $rc) 0 -}}{{- $_ := set $shard "relabelConfigs" $rc -}}{{- end -}}
      {{- $shards = append $shards $shard -}}
      {{- $index = add $index 1 -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
  {{- $shards = list (dict "index" 0 "name" $base "isSharded" false) -}}
{{- end -}}
{{- dict "shards" $shards | toYaml -}}
{{- end -}}

{{- /* ============================== */ -}}
{{- /* Ruler query URLs helpers       */ -}}
{{- /* ============================== */ -}}

{{- define "thanos.ruler.queryUrls" -}}
{{- $urls := .Values.ruler.query.urls -}}
{{- if not $urls -}}
{{- $urls = list (printf "http://%s:%v" (include "thanos.compName" (list . "query")) .Values.query.service.httpPort) -}}
{{- end }}
{{- range $url := $urls }}
{{- $u := urlParse $url }}
- static_configs:
    - {{ $u.host }}
  scheme: {{ $u.scheme }}
{{- if and $u.path (ne $u.path "/") }}
  path_prefix: {{ $u.path }}
{{- end }}
{{- end }}
{{- end -}}

{{- /* ============================== */ -}}
{{- /* ServiceAccount helpers         */ -}}
{{- /* ============================== */ -}}

{{- /*
Name of the chart-wide ServiceAccount, shared by every component that does not
declare one of its own: `global.serviceAccount.name` when set,
`<fullname>-thanos` otherwise.
*/ -}}
{{- define "thanos.sharedServiceAccountName" -}}
{{- $g := .Values.global.serviceAccount | default dict -}}
{{- if $g.name -}}
{{- $g.name -}}
{{- else -}}
{{- printf "%s-%s" (include "thanos.fullname" .) "thanos" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- /*
Resolve the ServiceAccount of a single component. Returns a YAML dict; consume
it with `fromYaml`:

  {{- $sa := include "thanos.serviceAccount" (dict "root" . "component" "compactor") | fromYaml }}

Keys:
  name        ServiceAccount name for the pod spec (never empty)
  dedicated   true when the chart renders a ServiceAccount for this component
              alone (`templates/<component>/serviceaccount.yaml`), false when
              the component falls back to the chart-wide ServiceAccount
  annotations annotations of the dedicated ServiceAccount
              (`global.serviceAccount.annotations` + component annotations)
  automountServiceAccountToken  token automount of the dedicated ServiceAccount

A component is dedicated when `<component>.serviceAccount.create` is set, and
inherits `global.serviceAccount.perComponent` when it is null.

Name resolution — component settings always take precedence over global ones:
  1. `<component>.serviceAccount.name`
  2. `<fullname>-<component>`                       when the component is dedicated
  3. `global.serviceAccount.name`
  4. `<fullname>-thanos`                            when `global.serviceAccount.create` is true
  5. `default`                                      (the namespace default ServiceAccount)

A `<component>.serviceAccount.name` without `create` therefore points the
component at a ServiceAccount managed outside this chart.
*/ -}}
{{- define "thanos.serviceAccount" -}}
{{- $root := .root -}}
{{- $comp := .component -}}
{{- $v := $root.Values -}}
{{- $g := $v.global.serviceAccount | default dict -}}
{{- $bucket := $v.bucket | default dict -}}
{{- $receive := $v.receive | default dict -}}
{{- $owners := dict
      "bucketweb" ($bucket.bucketweb | default dict)
      "compactor" ($v.compactor | default dict)
      "query" ($v.query | default dict)
      "query-frontend" ($v.queryFrontend | default dict)
      "storegateway" ($v.storegateway | default dict)
      "receive" $receive
      "receive-ingester" ($receive.ingester | default dict)
      "receive-router" ($receive.router | default dict)
      "ruler" ($v.ruler | default dict) -}}
{{- if not (hasKey $owners $comp) -}}
{{- fail (printf "thanos.serviceAccount: unknown component %q" $comp) -}}
{{- end -}}
{{- $cfg := (index $owners $comp).serviceAccount | default dict -}}
{{- $dedicated := $g.perComponent | default false -}}
{{- if not (kindIs "invalid" $cfg.create) -}}
{{- $dedicated = $cfg.create -}}
{{- end -}}
{{- $name := "" -}}
{{- if $cfg.name -}}
{{- $name = $cfg.name -}}
{{- else if $dedicated -}}
{{- $name = include "thanos.compName" (list $root $comp) -}}
{{- else if or $g.name $g.create -}}
{{- $name = include "thanos.sharedServiceAccountName" $root -}}
{{- else -}}
{{- $name = "default" -}}
{{- end -}}
{{- $automount := $g.automountServiceAccountToken -}}
{{- if not (kindIs "invalid" $cfg.automountServiceAccountToken) -}}
{{- $automount = $cfg.automountServiceAccountToken -}}
{{- end -}}
{{- if kindIs "invalid" $automount -}}
{{- $automount = true -}}
{{- end -}}
{{- $annotations := merge (deepCopy ($cfg.annotations | default dict)) ($g.annotations | default dict) -}}
{{- dict "name" $name "dedicated" $dedicated "annotations" $annotations "automountServiceAccountToken" $automount | toYaml -}}
{{- end -}}

{{- /*
ServiceAccount name a component's pods run as.
Usage: {{ include "thanos.serviceAccountName" (dict "root" . "component" "compactor") }}
*/ -}}
{{- define "thanos.serviceAccountName" -}}
{{- (include "thanos.serviceAccount" . | fromYaml).name -}}
{{- end -}}

{{- /*
Render the dedicated ServiceAccount of a component, or nothing when the
component shares the chart-wide ServiceAccount. Backs the per-component
`templates/<component>/serviceaccount.yaml` files.
Usage: {{ include "thanos.componentServiceAccount" (dict "root" . "component" "compactor") }}
*/ -}}
{{- define "thanos.componentServiceAccount" -}}
{{- $root := .root -}}
{{- $comp := .component -}}
{{- $sa := include "thanos.serviceAccount" . | fromYaml -}}
{{- if $sa.dedicated -}}
apiVersion: v1
kind: ServiceAccount
automountServiceAccountToken: {{ $sa.automountServiceAccountToken }}
metadata:
  name: {{ $sa.name }}
  namespace: {{ include "thanos.namespace" $root }}
  labels:
    {{- include "thanos.labels" $root | nindent 4 }}
    app.kubernetes.io/component: {{ $comp }}
  annotations:
    {{- toYaml $sa.annotations | nindent 4 }}
{{- end -}}
{{- end -}}

{{/*
Render imagePullSecrets from global.image.imagePullSecrets if any
*/}}
{{- define "thanos.imagePullSecrets" -}}
{{- if .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml .Values.global.imagePullSecrets | nindent 2 }}
{{- end }}
{{- end -}}

{{/*
Render a Gateway API HTTPRoute.
Usage: {{ include "thanos.httpRoute" (list . "query" .Values.query.service.httpPort .Values.query.httpRoute) }}
*/}}
{{- define "thanos.httpRoute" -}}
{{- $root := index . 0 -}}
{{- $comp := index . 1 -}}
{{- $port := index . 2 -}}
{{- $cfg  := index . 3 -}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ include "thanos.compName" (list $root $comp) }}
  namespace: {{ include "thanos.namespace" $root }}
  labels:
    {{- include "thanos.labels" $root | nindent 4 }}
    app.kubernetes.io/component: {{ $comp }}
  {{- with $cfg.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- toYaml $cfg.parentRefs | nindent 4 }}
  {{- with $cfg.hostnames }}
  hostnames:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  rules:
    - backendRefs:
        - name: {{ include "thanos.compName" (list $root $comp) }}
          port: {{ $port }}
      {{- with $cfg.matches }}
      matches:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $cfg.filters }}
      filters:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $cfg.timeouts }}
      timeouts:
        {{- toYaml . | nindent 8 }}
      {{- end }}
  {{- with $cfg.extraRules }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}

{{/*
Render a Gateway API GRPCRoute.
Usage: {{ include "thanos.grpcRoute" (list . "query" .Values.query.service.grpcPort .Values.query.grpcRoute) }}
*/}}
{{- define "thanos.grpcRoute" -}}
{{- $root := index . 0 -}}
{{- $comp := index . 1 -}}
{{- $port := index . 2 -}}
{{- $cfg  := index . 3 -}}
apiVersion: gateway.networking.k8s.io/v1
kind: GRPCRoute
metadata:
  name: {{ include "thanos.compName" (list $root $comp) }}-grpc
  namespace: {{ include "thanos.namespace" $root }}
  labels:
    {{- include "thanos.labels" $root | nindent 4 }}
    app.kubernetes.io/component: {{ $comp }}
  {{- with $cfg.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- toYaml $cfg.parentRefs | nindent 4 }}
  {{- with $cfg.hostnames }}
  hostnames:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  rules:
    - backendRefs:
        - name: {{ include "thanos.compName" (list $root $comp) }}
          port: {{ $port }}
{{- end -}}

{{/*
Render .Values.ruler.autoImportPrometheusRules.labelSelector (a map) as a
comma-separated "key=value" string suitable for `kubectl get -l`.
An empty map renders as the empty string.
*/}}
{{- define "thanos.ruler.autoImportPrometheusRules.labelSelector" -}}
{{- $parts := list -}}
{{- range $k, $v := .Values.ruler.autoImportPrometheusRules.labelSelector -}}
{{- $parts = append $parts (printf "%s=%s" $k $v) -}}
{{- end -}}
{{- join "," $parts -}}
{{- end -}}

{{- /*
PrometheusRule helpers live in templates/prometheusrule/_helpers.tpl
to keep this global file focused on cross-cutting chart utilities.
*/ -}}
