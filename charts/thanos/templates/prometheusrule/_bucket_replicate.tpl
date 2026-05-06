{{/*
Render the thanos-bucket-replicate rule group.

Disabled by default in this chart because the bucket-replicate
component is not deployed here.

Context (.):
  ctx.bucketRepl       — group config
  ctx.brLab/brAnn      — group labels/annotations (resolved)
  ctx.grLab/grAnn      — global rule labels/annotations
  ctx.sCrit            — severity label value
  ctx.jpBucketRepl     — job regex
  ctx.runbook          — runbook base URL
*/}}
{{- define "thanos.rules.bucketReplicate" -}}
{{- if .bucketReplEnabled }}
- name: thanos-bucket-replicate
  rules:
    - alert: ThanosBucketReplicateErrorRate
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Replicate is failing to run." "Thanos Replicate is failing to run, {{$value | humanize}}% of attempts failed." (printf "%s#alert-name-thanosbucketreplicateerrorrate" .runbook) .grAnn .brAnn) | nindent 8 }}
      expr: |
        (
          sum by (job) (rate(thanos_replicate_replication_runs_total{result="error", job=~"{{ .jpBucketRepl }}"}[5m]))
        / on (job) group_left
          sum by (job) (rate(thanos_replicate_replication_runs_total{job=~"{{ .jpBucketRepl }}"}[5m]))
        ) * 100 >= 10
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .brLab) | nindent 8 }}
    - alert: ThanosBucketReplicateRunLatency
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Replicate has a high latency for replicate operations." "Thanos Replicate {{$labels.job}} has a 99th percentile latency of {{$value}} seconds for the replicate operations." (printf "%s#alert-name-thanosbucketreplicaterunlatency" .runbook) .grAnn .brAnn) | nindent 8 }}
      expr: |
        (
          histogram_quantile(0.99, sum by (job) (rate(thanos_replicate_replication_run_duration_seconds_bucket{job=~"{{ .jpBucketRepl }}"}[5m]))) > 20
        and
          sum by (job) (rate(thanos_replicate_replication_run_duration_seconds_bucket{job=~"{{ .jpBucketRepl }}"}[5m])) > 0
        )
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .brLab) | nindent 8 }}
{{- end }}
{{- end -}}
