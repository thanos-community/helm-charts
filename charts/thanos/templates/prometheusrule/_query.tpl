{{/*
Render the thanos-query rule group.

Context (.):
  ctx.query        — group config
  ctx.qLab/qAnn    — group labels/annotations (resolved)
  ctx.grLab/grAnn  — global rule labels/annotations
  ctx.sCrit/sWarn  — severity label values
  ctx.jpQuery      — job regex
  ctx.runbook      — runbook base URL
*/}}
{{- define "thanos.rules.query" -}}
{{- if .queryEnabled }}
- name: thanos-query
  rules:
    - alert: ThanosQueryHttpRequestQueryErrorRateHigh
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Query is failing to handle requests." "Thanos Query {{$labels.job}} is failing to handle {{$value | humanize}}% of \"query\" requests." (printf "%s#alert-name-thanosqueryhttprequestqueryerrorratehigh" .runbook) .grAnn .qAnn) | nindent 8 }}
      expr: |
        (
          sum by (job) (rate(http_requests_total{code=~"5..", job=~"{{ .jpQuery }}", handler="query"}[5m]))
        /
          sum by (job) (rate(http_requests_total{job=~"{{ .jpQuery }}", handler="query"}[5m]))
        ) * 100 > 5
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .qLab) | nindent 8 }}
    - alert: ThanosQueryHttpRequestQueryRangeErrorRateHigh
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Query is failing to handle requests." "Thanos Query {{$labels.job}} is failing to handle {{$value | humanize}}% of \"query_range\" requests." (printf "%s#alert-name-thanosqueryhttprequestqueryrangeerrorratehigh" .runbook) .grAnn .qAnn) | nindent 8 }}
      expr: |
        (
          sum by (job) (rate(http_requests_total{code=~"5..", job=~"{{ .jpQuery }}", handler="query_range"}[5m]))
        /
          sum by (job) (rate(http_requests_total{job=~"{{ .jpQuery }}", handler="query_range"}[5m]))
        ) * 100 > 5
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .qLab) | nindent 8 }}
    - alert: ThanosQueryGrpcServerErrorRate
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Query is failing to handle requests." "Thanos Query {{$labels.job}} is failing to handle {{$value | humanize}}% of requests." (printf "%s#alert-name-thanosquerygrpcservererrorrate" .runbook) .grAnn .qAnn) | nindent 8 }}
      expr: |
        (
          sum by (job) (rate(grpc_server_handled_total{grpc_code=~"Unknown|ResourceExhausted|Internal|Unavailable|DataLoss|DeadlineExceeded", job=~"{{ .jpQuery }}"}[5m]))
        /
          sum by (job) (rate(grpc_server_started_total{job=~"{{ .jpQuery }}"}[5m]))
        * 100 > 5
        )
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .qLab) | nindent 8 }}
    - alert: ThanosQueryGrpcClientErrorRate
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Query is failing to send requests." "Thanos Query {{$labels.job}} is failing to send {{$value | humanize}}% of requests." (printf "%s#alert-name-thanosquerygrpcclienterrorrate" .runbook) .grAnn .qAnn) | nindent 8 }}
      expr: |
        (
          sum by (job) (rate(grpc_client_handled_total{grpc_code!="OK", job=~"{{ .jpQuery }}"}[5m]))
        /
          sum by (job) (rate(grpc_client_started_total{job=~"{{ .jpQuery }}"}[5m]))
        ) * 100 > 5
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .qLab) | nindent 8 }}
    - alert: ThanosQueryHighDNSFailures
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Query is having high number of DNS failures." "Thanos Query {{$labels.job}} have {{$value | humanize}}% of failing DNS queries for store endpoints." (printf "%s#alert-name-thanosqueryhighdnsfailures" .runbook) .grAnn .qAnn) | nindent 8 }}
      expr: |
        (
          sum by (job) (rate(thanos_query_store_apis_dns_failures_total{job=~"{{ .jpQuery }}"}[5m]))
        /
          sum by (job) (rate(thanos_query_store_apis_dns_lookups_total{job=~"{{ .jpQuery }}"}[5m]))
        ) * 100 > 1
      for: 15m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .qLab) | nindent 8 }}
    - alert: ThanosQueryInstantLatencyHigh
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Query has high latency for queries." "Thanos Query {{$labels.job}} has a 99th percentile latency of {{$value}} seconds for instant queries." (printf "%s#alert-name-thanosqueryinstantlatencyhigh" .runbook) .grAnn .qAnn) | nindent 8 }}
      expr: |
        (
          histogram_quantile(0.99, sum by (job, le) (rate(http_request_duration_seconds_bucket{job=~"{{ .jpQuery }}", handler="query"}[5m]))) > 40
        and
          sum by (job) (rate(http_request_duration_seconds_bucket{job=~"{{ .jpQuery }}", handler="query"}[5m])) > 0
        )
      for: 10m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .qLab) | nindent 8 }}
    - alert: ThanosQueryRangeLatencyHigh
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Query has high latency for queries." "Thanos Query {{$labels.job}} has a 99th percentile latency of {{$value}} seconds for range queries." (printf "%s#alert-name-thanosqueryrangelatencyhigh" .runbook) .grAnn .qAnn) | nindent 8 }}
      expr: |
        (
          histogram_quantile(0.99, sum by (job, le) (rate(http_request_duration_seconds_bucket{job=~"{{ .jpQuery }}", handler="query_range"}[5m]))) > 90
        and
          sum by (job) (rate(http_request_duration_seconds_count{job=~"{{ .jpQuery }}", handler="query_range"}[5m])) > 0
        )
      for: 10m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .qLab) | nindent 8 }}
    - alert: ThanosQueryOverload
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos query reaches its maximum capacity serving concurrent requests." "Thanos Query {{$labels.job}} has been overloaded for more than 15 minutes. This may be a symptom of excessive simultaneous complex requests, low performance of the Prometheus API, or failures within these components. Assess the health of the Thanos query instances, the connected Prometheus instances, look for potential senders of these requests and then contact support." (printf "%s#alert-name-thanosqueryoverload" .runbook) .grAnn .qAnn) | nindent 8 }}
      expr: |
        (
          max_over_time(thanos_query_concurrent_gate_queries_max{job=~"{{ .jpQuery }}"}[5m]) - avg_over_time(thanos_query_concurrent_gate_queries_in_flight{job=~"{{ .jpQuery }}"}[5m]) < 1
        )
      for: 15m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .qLab) | nindent 8 }}
{{- end }}
{{- end -}}
