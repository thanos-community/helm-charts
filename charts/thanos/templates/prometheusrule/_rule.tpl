{{/*
Render the thanos-rule rule group (Ruler).

Context (.):
  ctx.rule              — group config
  ctx.rLab/rAnn         — group labels/annotations (resolved)
  ctx.grLab/grAnn       — global rule labels/annotations
  ctx.sCrit/sWarn/sInfo — severity label values
  ctx.jpRule            — job regex
  ctx.runbook           — runbook base URL
*/}}
{{- define "thanos.rules.rule" -}}
{{- if .ruleEnabled }}
- name: thanos-rule
  rules:
    - alert: ThanosRuleQueueIsDroppingAlerts
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Rule is failing to queue alerts." "Thanos Rule {{$labels.instance}} is failing to queue alerts." (printf "%s#alert-name-thanosrulequeueisdroppingalerts" .runbook) .grAnn .rAnn) | nindent 8 }}
      expr: |
        sum by (job, instance) (rate(thanos_alert_queue_alerts_dropped_total{job=~"{{ .jpRule }}"}[5m])) > 0
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .rLab) | nindent 8 }}
    - alert: ThanosRuleSenderIsFailingAlerts
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Rule is failing to send alerts to alertmanager." "Thanos Rule {{$labels.instance}} is failing to send alerts to alertmanager." (printf "%s#alert-name-thanosrulesenderisfailingalerts" .runbook) .grAnn .rAnn) | nindent 8 }}
      expr: |
        sum by (job, instance) (rate(thanos_alert_sender_alerts_dropped_total{job=~"{{ .jpRule }}"}[5m])) > 0
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .rLab) | nindent 8 }}
    - alert: ThanosRuleHighRuleEvaluationFailures
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Rule is failing to evaluate rules." "Thanos Rule {{$labels.instance}} is failing to evaluate rules." (printf "%s#alert-name-thanosrulehighruleevaluationfailures" .runbook) .grAnn .rAnn) | nindent 8 }}
      expr: |
        (
          sum by (job, instance) (rate(prometheus_rule_evaluation_failures_total{job=~"{{ .jpRule }}"}[5m]))
        /
          sum by (job, instance) (rate(prometheus_rule_evaluations_total{job=~"{{ .jpRule }}"}[5m]))
        * 100 > 5
        )
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .rLab) | nindent 8 }}
    - alert: ThanosRuleHighRuleEvaluationWarnings
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Rule has high number of evaluation warnings." "Thanos Rule {{$labels.instance}} has high number of evaluation warnings." (printf "%s#alert-name-thanosrulehighruleevaluationwarnings" .runbook) .grAnn .rAnn) | nindent 8 }}
      expr: |
        sum by (job, instance) (rate(thanos_rule_evaluation_with_warnings_total{job=~"{{ .jpRule }}"}[5m])) > 0
      for: 15m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sInfo .grLab .rLab) | nindent 8 }}
    - alert: ThanosRuleRuleEvaluationLatencyHigh
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Rule has high rule evaluation latency." "Thanos Rule {{$labels.instance}} has higher evaluation latency than interval for {{$labels.rule_group}}." (printf "%s#alert-name-thanosruleruleevaluationlatencyhigh" .runbook) .grAnn .rAnn) | nindent 8 }}
      expr: |
        (
          sum by (job, instance, rule_group) (prometheus_rule_group_last_duration_seconds{job=~"{{ .jpRule }}"})
        >
          sum by (job, instance, rule_group) (prometheus_rule_group_interval_seconds{job=~"{{ .jpRule }}"})
        )
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .rLab) | nindent 8 }}
    - alert: ThanosRuleGrpcErrorRate
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Rule is failing to handle grpc requests." "Thanos Rule {{$labels.job}} is failing to handle {{$value | humanize}}% of requests." (printf "%s#alert-name-thanosrulegrpcerrorrate" .runbook) .grAnn .rAnn) | nindent 8 }}
      expr: |
        (
          sum by (job, instance) (rate(grpc_server_handled_total{grpc_code=~"Unknown|ResourceExhausted|Internal|Unavailable|DataLoss|DeadlineExceeded", job=~"{{ .jpRule }}"}[5m]))
        /
          sum by (job, instance) (rate(grpc_server_started_total{job=~"{{ .jpRule }}"}[5m]))
        * 100 > 5
        )
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .rLab) | nindent 8 }}
    - alert: ThanosRuleConfigReloadFailure
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Rule has not been able to reload configuration." "Thanos Rule {{$labels.job}} has not been able to reload its configuration." (printf "%s#alert-name-thanosruleconfigreloadfailure" .runbook) .grAnn .rAnn) | nindent 8 }}
      expr: avg by (job, instance) (thanos_rule_config_last_reload_successful{job=~"{{ .jpRule }}"}) != 1
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sInfo .grLab .rLab) | nindent 8 }}
    - alert: ThanosRuleQueryHighDNSFailures
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Rule is having high number of DNS failures." "Thanos Rule {{$labels.job}} has {{$value | humanize}}% of failing DNS queries for query endpoints." (printf "%s#alert-name-thanosrulequeryhighdnsfailures" .runbook) .grAnn .rAnn) | nindent 8 }}
      expr: |
        (
          sum by (job, instance) (rate(thanos_rule_query_apis_dns_failures_total{job=~"{{ .jpRule }}"}[5m]))
        /
          sum by (job, instance) (rate(thanos_rule_query_apis_dns_lookups_total{job=~"{{ .jpRule }}"}[5m]))
        * 100 > 1
        )
      for: 15m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .rLab) | nindent 8 }}
    - alert: ThanosRuleAlertmanagerHighDNSFailures
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Rule is having high number of DNS failures." "Thanos Rule {{$labels.instance}} has {{$value | humanize}}% of failing DNS queries for Alertmanager endpoints." (printf "%s#alert-name-thanosrulealertmanagerhighdnsfailures" .runbook) .grAnn .rAnn) | nindent 8 }}
      expr: |
        (
          sum by (job, instance) (rate(thanos_rule_alertmanagers_dns_failures_total{job=~"{{ .jpRule }}"}[5m]))
        /
          sum by (job, instance) (rate(thanos_rule_alertmanagers_dns_lookups_total{job=~"{{ .jpRule }}"}[5m]))
        * 100 > 1
        )
      for: 15m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sWarn .grLab .rLab) | nindent 8 }}
    - alert: ThanosRuleNoEvaluationFor10Intervals
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Rule has rule groups that did not evaluate for 10 intervals." "Thanos Rule {{$labels.job}} has rule groups that did not evaluate for at least 10x of their expected interval." (printf "%s#alert-name-thanosrulenoevaluationfor10intervals" .runbook) .grAnn .rAnn) | nindent 8 }}
      expr: |
        time() - max by (job, instance, group) (prometheus_rule_group_last_evaluation_timestamp_seconds{job=~"{{ .jpRule }}"})
        >
        10 * max by (job, instance, group) (prometheus_rule_group_interval_seconds{job=~"{{ .jpRule }}"})
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sInfo .grLab .rLab) | nindent 8 }}
    - alert: ThanosNoRuleEvaluations
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos Rule did not perform any rule evaluations." "Thanos Rule {{$labels.instance}} did not perform any rule evaluations in the past 10 minutes." (printf "%s#alert-name-thanosnoruleevaluations" .runbook) .grAnn .rAnn) | nindent 8 }}
      expr: |
        sum by (job, instance) (rate(prometheus_rule_evaluations_total{job=~"{{ .jpRule }}"}[5m])) <= 0
          and
        sum by (job, instance) (thanos_rule_loaded_rules{job=~"{{ .jpRule }}"}) > 0
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .rLab) | nindent 8 }}
{{- end }}
{{- end -}}
