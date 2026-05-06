{{/*
Render the thanos-component-absent rule group.

Each "Is Down" rule is also gated on the corresponding component
group being enabled, so disabling thanosSidecar removes both the
sidecar alerts and the ThanosSidecarIsDown rule.

Context (.):
  ctx.absent         — group config
  ctx.compact, .query, .receive, .rule, .sidecar, .store — sibling
                       group configs (used to gate per-component alerts)
  ctx.abLab/abAnn    — group labels/annotations (resolved)
  ctx.grLab/grAnn    — global rule labels/annotations
  ctx.sCrit          — severity label value
  ctx.jpCompact ...  — per-component job regexes
  ctx.runbook        — runbook base URL
*/}}
{{- define "thanos.rules.componentAbsent" -}}
{{- if .absentEnabled }}
- name: thanos-component-absent
  rules:
    {{- if .compactEnabled }}
    - alert: ThanosCompactIsDown
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos component has disappeared." "ThanosCompact has disappeared. Prometheus target for the component cannot be discovered." (printf "%s#alert-name-thanoscompactisdown" .runbook) .grAnn .abAnn) | nindent 8 }}
      expr: |
        absent(up{job=~"{{ .jpCompact }}"} == 1)
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .abLab) | nindent 8 }}
    {{- end }}
    {{- if .queryEnabled }}
    - alert: ThanosQueryIsDown
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos component has disappeared." "ThanosQuery has disappeared. Prometheus target for the component cannot be discovered." (printf "%s#alert-name-thanosqueryisdown" .runbook) .grAnn .abAnn) | nindent 8 }}
      expr: |
        absent(up{job=~"{{ .jpQuery }}"} == 1)
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .abLab) | nindent 8 }}
    {{- end }}
    {{- if .receiveEnabled }}
    - alert: ThanosReceiveIsDown
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos component has disappeared." "ThanosReceive has disappeared. Prometheus target for the component cannot be discovered." (printf "%s#alert-name-thanosreceiveisdown" .runbook) .grAnn .abAnn) | nindent 8 }}
      expr: |
        absent(up{job=~"{{ .jpReceive }}"} == 1)
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .abLab) | nindent 8 }}
    {{- end }}
    {{- if .ruleEnabled }}
    - alert: ThanosRuleIsDown
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos component has disappeared." "ThanosRule has disappeared. Prometheus target for the component cannot be discovered." (printf "%s#alert-name-thanosruleisdown" .runbook) .grAnn .abAnn) | nindent 8 }}
      expr: |
        absent(up{job=~"{{ .jpRule }}"} == 1)
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .abLab) | nindent 8 }}
    {{- end }}
    {{- if .sidecarEnabled }}
    - alert: ThanosSidecarIsDown
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos component has disappeared." "ThanosSidecar has disappeared. Prometheus target for the component cannot be discovered." (printf "%s#alert-name-thanossidecarisdown" .runbook) .grAnn .abAnn) | nindent 8 }}
      expr: |
        absent(up{job=~"{{ .jpSidecar }}"} == 1)
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .abLab) | nindent 8 }}
    {{- end }}
    {{- if .storeEnabled }}
    - alert: ThanosStoreIsDown
      annotations:
        {{- include "thanos.rules.alertAnnotations" (list "Thanos component has disappeared." "ThanosStore has disappeared. Prometheus target for the component cannot be discovered." (printf "%s#alert-name-thanosstoreisdown" .runbook) .grAnn .abAnn) | nindent 8 }}
      expr: |
        absent(up{job=~"{{ .jpStore }}"} == 1)
      for: 5m
      labels:
        {{- include "thanos.rules.alertLabels" (list .sCrit .grLab .abLab) | nindent 8 }}
    {{- end }}
{{- end }}
{{- end -}}
