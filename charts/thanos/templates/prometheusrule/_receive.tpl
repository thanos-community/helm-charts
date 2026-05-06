{{/*
Render the thanos-receive rule group.

Context (.):
  ctx.receive          — group config
  ctx.rcLab/rcAnn      — group labels/annotations (resolved)
  ctx.grLab/grAnn      — global rule labels/annotations
  ctx.sCrit/sWarn/sInfo — severity label values
  ctx.jpReceive        — job regex
  ctx.runbook          — runbook base URL
*/}}
{{- define "thanos.rules.receive" -}}
{{- if .receiveEnabled }}
- name: thanos-receive
  rules:
    - alert: ThanosReceiveHttpRequestErrorRateHigh
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Receive is failing to handle requests." "Thanos Receive {{$labels.job}} is failing to handle {{$value | humanize}}% of requests." (printf "%s#alert-name-thanosreceivehttprequesterrorratehigh" .runbook) .grAnn .rcAnn) | nindent 8 }}
      expr: |
        (
          sum by (job) (rate(http_requests_total{code=~"5..", job=~"{{ .jpReceive }}", handler="receive"}[5m]))
        /
          sum by (job) (rate(http_requests_total{job=~"{{ .jpReceive }}", handler="receive"}[5m]))
        ) * 100 > 5
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .rcLab) | nindent 8 }}
    - alert: ThanosReceiveHttpRequestLatencyHigh
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Receive has high HTTP requests latency." "Thanos Receive {{$labels.job}} has a 99th percentile latency of {{ $value }} seconds for requests." (printf "%s#alert-name-thanosreceivehttprequestlatencyhigh" .runbook) .grAnn .rcAnn) | nindent 8 }}
      expr: |
        (
          histogram_quantile(0.99, sum by (job, le) (rate(http_request_duration_seconds_bucket{job=~"{{ .jpReceive }}", handler="receive"}[5m]))) > 10
        and
          sum by (job) (rate(http_request_duration_seconds_count{job=~"{{ .jpReceive }}", handler="receive"}[5m])) > 0
        )
      for: 10m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .rcLab) | nindent 8 }}
    - alert: ThanosReceiveHighReplicationFailures
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Receive is having high number of replication failures." "Thanos Receive {{$labels.job}} is failing to replicate {{$value | humanize}}% of requests." (printf "%s#alert-name-thanosreceivehighreplicationfailures" .runbook) .grAnn .rcAnn) | nindent 8 }}
      expr: |
        thanos_receive_replication_factor{job=~"{{ .jpReceive }}"} > 1
          and
        (
          (
            sum by (job) (rate(thanos_receive_replications_total{result="error", job=~"{{ .jpReceive }}"}[5m]))
          /
            sum by (job) (rate(thanos_receive_replications_total{job=~"{{ .jpReceive }}"}[5m]))
          )
          >
          (
            max by (job) (floor((thanos_receive_replication_factor{job=~"{{ .jpReceive }}"}+1) / 2))
          /
            max by (job) (thanos_receive_hashring_nodes{job=~"{{ .jpReceive }}"})
          )
        ) * 100
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .rcLab) | nindent 8 }}
    - alert: ThanosReceiveHighForwardRequestFailures
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Receive is failing to forward requests." "Thanos Receive {{$labels.job}} is failing to forward {{$value | humanize}}% of requests." (printf "%s#alert-name-thanosreceivehighforwardrequestfailures" .runbook) .grAnn .rcAnn) | nindent 8 }}
      expr: |
        (
          sum by (job) (rate(thanos_receive_forward_requests_total{result="error", job=~"{{ .jpReceive }}"}[5m]))
        /
          sum by (job) (rate(thanos_receive_forward_requests_total{job=~"{{ .jpReceive }}"}[5m]))
        ) * 100 > 20
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sInfo .grLab .rcLab) | nindent 8 }}
    - alert: ThanosReceiveHighHashringFileRefreshFailures
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Receive is failing to refresh hasring file." "Thanos Receive {{$labels.job}} is failing to refresh hashring file, {{$value | humanize}} of attempts failed." (printf "%s#alert-name-thanosreceivehighhashringfilerefreshfailures" .runbook) .grAnn .rcAnn) | nindent 8 }}
      expr: |
        (
          sum by (job) (rate(thanos_receive_hashrings_file_errors_total{job=~"{{ .jpReceive }}"}[5m]))
        /
          sum by (job) (rate(thanos_receive_hashrings_file_refreshes_total{job=~"{{ .jpReceive }}"}[5m]))
        > 0
        )
      for: 15m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .rcLab) | nindent 8 }}
    - alert: ThanosReceiveConfigReloadFailure
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Receive has not been able to reload configuration." "Thanos Receive {{$labels.job}} has not been able to reload hashring configurations." (printf "%s#alert-name-thanosreceiveconfigreloadfailure" .runbook) .grAnn .rcAnn) | nindent 8 }}
      expr: avg by (job) (thanos_receive_config_last_reload_successful{job=~"{{ .jpReceive }}"}) != 1
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .rcLab) | nindent 8 }}
    - alert: ThanosReceiveNoUpload
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Receive has not uploaded latest data to object storage." "Thanos Receive {{$labels.instance}} has not uploaded latest data to object storage." (printf "%s#alert-name-thanosreceivenoupload" .runbook) .grAnn .rcAnn) | nindent 8 }}
      expr: |
        (up{job=~"{{ .jpReceive }}"} - 1)
        + on (job, instance)
        (sum by (job, instance) (increase(thanos_shipper_uploads_total{job=~"{{ .jpReceive }}"}[3h])) == 0)
      for: 3h
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .rcLab) | nindent 8 }}
    - alert: ThanosReceiveLimitsConfigReloadFailure
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Receive has not been able to reload the limits configuration." "Thanos Receive {{$labels.job}} has not been able to reload the limits configuration." (printf "%s#alert-name-thanosreceivelimitsconfigreloadfailure" .runbook) .grAnn .rcAnn) | nindent 8 }}
      expr: sum by(job) (increase(thanos_receive_limits_config_reload_err_total{job=~"{{ .jpReceive }}"}[5m])) > 0
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .rcLab) | nindent 8 }}
    - alert: ThanosReceiveLimitsHighMetaMonitoringQueriesFailureRate
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Receive has not been able to update the number of head series." "Thanos Receive {{$labels.job}} is failing for {{$value | humanize}}% of meta monitoring queries." (printf "%s#alert-name-thanosreceivelimitshighmetamonitoringqueriesfailurerate" .runbook) .grAnn .rcAnn) | nindent 8 }}
      expr: (sum by(job) (increase(thanos_receive_metamonitoring_failed_queries_total{job=~"{{ .jpReceive }}"}[5m])) / 20) * 100 > 20
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .rcLab) | nindent 8 }}
    - alert: ThanosReceiveTenantLimitedByHeadSeries
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "A Thanos Receive tenant is limited by head series." "Thanos Receive tenant {{$labels.tenant}} is limited by head series." (printf "%s#alert-name-thanosreceivetenantlimitedbyheadseries" .runbook) .grAnn .rcAnn) | nindent 8 }}
      expr: sum by(job, tenant) (increase(thanos_receive_head_series_limited_requests_total{job=~"{{ .jpReceive }}"}[5m])) > 0
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .rcLab) | nindent 8 }}
{{- end }}
{{- end -}}
