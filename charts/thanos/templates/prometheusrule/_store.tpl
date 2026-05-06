{{/*
Render the thanos-store rule group (Store Gateway).

Context (.):
  ctx.store        — group config
  ctx.stLab/stAnn  — group labels/annotations (resolved)
  ctx.grLab/grAnn  — global rule labels/annotations
  ctx.sWarn        — severity label value
  ctx.jpStore      — job regex
  ctx.runbook      — runbook base URL
*/}}
{{- define "thanos.rules.store" -}}
{{- if .storeEnabled }}
- name: thanos-store
  rules:
    - alert: ThanosStoreGrpcErrorRate
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Store is failing to handle gRPC requests." "Thanos Store {{$labels.job}} is failing to handle {{$value | humanize}}% of requests." (printf "%s#alert-name-thanosstoregrpcerrorrate" .runbook) .grAnn .stAnn) | nindent 8 }}
      expr: |
        (
          sum by (job) (rate(grpc_server_handled_total{grpc_code=~"Unknown|Internal|Unavailable|DataLoss|DeadlineExceeded", job=~"{{ .jpStore }}"}[5m]))
        /
          sum by (job) (rate(grpc_server_started_total{job=~"{{ .jpStore }}"}[5m]))
        * 100 > 5
        )
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .stLab) | nindent 8 }}
    - alert: ThanosStoreSeriesGateLatencyHigh
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Store has high latency for store series gate requests." "Thanos Store {{$labels.job}} has a 99th percentile latency of {{$value}} seconds for store series gate requests." (printf "%s#alert-name-thanosstoreseriesgatelatencyhigh" .runbook) .grAnn .stAnn) | nindent 8 }}
      expr: |
        (
          histogram_quantile(0.99, sum by (job, le) (rate(thanos_bucket_store_series_gate_duration_seconds_bucket{job=~"{{ .jpStore }}"}[5m]))) > 2
        and
          sum by (job) (rate(thanos_bucket_store_series_gate_duration_seconds_count{job=~"{{ .jpStore }}"}[5m])) > 0
        )
      for: 10m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .stLab) | nindent 8 }}
    - alert: ThanosStoreBucketHighOperationFailures
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Store Bucket is failing to execute operations." "Thanos Store {{$labels.job}} Bucket is failing to execute {{$value | humanize}}% of operations." (printf "%s#alert-name-thanosstorebuckethighoperationfailures" .runbook) .grAnn .stAnn) | nindent 8 }}
      expr: |
        (
          sum by (job) (rate(thanos_objstore_bucket_operation_failures_total{job=~"{{ .jpStore }}"}[5m]))
        /
          sum by (job) (rate(thanos_objstore_bucket_operations_total{job=~"{{ .jpStore }}"}[5m]))
        * 100 > 5
        )
      for: 15m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .stLab) | nindent 8 }}
    - alert: ThanosStoreObjstoreOperationLatencyHigh
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Store is having high latency for bucket operations." "Thanos Store {{$labels.job}} Bucket has a 99th percentile latency of {{$value}} seconds for the bucket operations." (printf "%s#alert-name-thanosstoreobjstoreoperationlatencyhigh" .runbook) .grAnn .stAnn) | nindent 8 }}
      expr: |
        (
          histogram_quantile(0.99, sum by (job, le) (rate(thanos_objstore_bucket_operation_duration_seconds_bucket{job=~"{{ .jpStore }}"}[5m]))) > 2
        and
          sum by (job) (rate(thanos_objstore_bucket_operation_duration_seconds_count{job=~"{{ .jpStore }}"}[5m])) > 0
        )
      for: 10m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .stLab) | nindent 8 }}
{{- end }}
{{- end -}}
