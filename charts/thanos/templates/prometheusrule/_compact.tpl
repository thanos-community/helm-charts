{{/*
Render the thanos-compact rule group.

Context (.):
  ctx.compact      — group config (enabled, jobPattern, labels, annotations)
  ctx.cLab/cAnn    — group labels/annotations (resolved with defaults)
  ctx.grLab/grAnn  — global additionalRuleGroupLabels/Annotations
  ctx.sWarn        — severity label value for warnings
  ctx.jpCompact    — job regex
  ctx.runbook      — runbook base URL

Output is the `- name: thanos-compact` block plus its `rules:` list.
*/}}
{{- define "thanos.rules.compact" -}}
{{- if .compactEnabled }}
- name: thanos-compact
  rules:
    - alert: ThanosCompactMultipleRunning
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Compact has multiple instances running." "No more than one Thanos Compact instance should be running at once. There are {{$value}} instances running." (printf "%s#alert-name-thanoscompactmultiplerunning" .runbook) .grAnn .cAnn) | nindent 8 }}
      expr: sum by (job) (up{job=~"{{ .jpCompact }}"}) > 1
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .cLab) | nindent 8 }}
    - alert: ThanosCompactHalted
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Compact has failed to run and is now halted." "Thanos Compact {{$labels.job}} has failed to run and now is halted." (printf "%s#alert-name-thanoscompacthalted" .runbook) .grAnn .cAnn) | nindent 8 }}
      expr: thanos_compact_halted{job=~"{{ .jpCompact }}"} == 1
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .cLab) | nindent 8 }}
    - alert: ThanosCompactHighCompactionFailures
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Compact is failing to execute compactions." "Thanos Compact {{$labels.job}} is failing to execute {{$value | humanize}}% of compactions." (printf "%s#alert-name-thanoscompacthighcompactionfailures" .runbook) .grAnn .cAnn) | nindent 8 }}
      expr: |
        (
          sum by (job) (rate(thanos_compact_group_compactions_failures_total{job=~"{{ .jpCompact }}"}[5m]))
        /
          sum by (job) (rate(thanos_compact_group_compactions_total{job=~"{{ .jpCompact }}"}[5m]))
        * 100 > 5
        )
      for: 15m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .cLab) | nindent 8 }}
    - alert: ThanosCompactBucketHighOperationFailures
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Compact Bucket is having a high number of operation failures." "Thanos Compact {{$labels.job}} Bucket is failing to execute {{$value | humanize}}% of operations." (printf "%s#alert-name-thanoscompactbuckethighoperationfailures" .runbook) .grAnn .cAnn) | nindent 8 }}
      expr: |
        (
          sum by (job) (rate(thanos_objstore_bucket_operation_failures_total{job=~"{{ .jpCompact }}"}[5m]))
        /
          sum by (job) (rate(thanos_objstore_bucket_operations_total{job=~"{{ .jpCompact }}"}[5m]))
        * 100 > 5
        )
      for: 15m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .cLab) | nindent 8 }}
    - alert: ThanosCompactHasNotRun
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Compact has not uploaded anything for last 24 hours." "Thanos Compact {{$labels.job}} has not uploaded anything for 24 hours." (printf "%s#alert-name-thanoscompacthasnotrun" .runbook) .grAnn .cAnn) | nindent 8 }}
      expr: (time() - max by (job) (max_over_time(thanos_objstore_bucket_last_successful_upload_time{job=~"{{ .jpCompact }}"}[24h]))) / 60 / 60 > 24
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .cLab) | nindent 8 }}
{{- end }}
{{- end -}}
