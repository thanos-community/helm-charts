{{/*
Render the thanos-sidecar rule group.

Disabled by default in this chart because the sidecar is not deployed
here. Enable when scraping a Thanos sidecar from elsewhere in the
cluster (e.g. Prometheus pods running the Thanos sidecar container).

Context (.):
  ctx.sidecar      — group config
  ctx.sLab/sAnn    — group labels/annotations (resolved)
  ctx.grLab/grAnn  — global rule labels/annotations
  ctx.sCrit        — severity label value
  ctx.jpSidecar    — job regex
  ctx.runbook      — runbook base URL
*/}}
{{- define "thanos.rules.sidecar" -}}
{{- if .sidecarEnabled }}
- name: thanos-sidecar
  rules:
    - alert: ThanosSidecarBucketOperationsFailed
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Sidecar bucket operations are failing" "Thanos Sidecar {{$labels.instance}} bucket operations are failing" (printf "%s#alert-name-thanossidecarbucketoperationsfailed" .runbook) .grAnn .sAnn) | nindent 8 }}
      expr: |
        sum by (job, instance) (rate(thanos_objstore_bucket_operation_failures_total{job=~"{{ .jpSidecar }}"}[5m])) > 0
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .sLab) | nindent 8 }}
    - alert: ThanosSidecarNoConnectionToStartedPrometheus
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Sidecar cannot access Prometheus, even though Prometheus seems healthy and has reloaded WAL." "Thanos Sidecar {{$labels.instance}} is unhealthy." (printf "%s#alert-name-thanossidecarnoconnectiontostartedprometheus" .runbook) .grAnn .sAnn) | nindent 8 }}
      expr: |
        thanos_sidecar_prometheus_up{job=~"{{ .jpSidecar }}"} == 0
        AND on (namespace, pod)
        prometheus_tsdb_data_replay_duration_seconds != 0
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .sLab) | nindent 8 }}
{{- end }}
{{- end -}}
