{{/*
Render the labels block of a Thanos PrometheusRule alert.
Merges (in order of decreasing precedence):
  1. per-group .labels (passed in)
  2. .Values.global.thanosRules.additionalRuleGroupLabels
  3. {severity: <sev>} default

Usage:
  {{- include "thanos.rules.alertLabels" (list $sev $globalLabels $groupLabels) | nindent 8 }}
*/}}
{{- define "thanos.rules.alertLabels" -}}
{{- $sev := index . 0 -}}
{{- $glob := index . 1 | default dict -}}
{{- $grp := index . 2 | default dict -}}
{{- $base := dict "severity" $sev -}}
{{- toYaml (merge (deepCopy $grp) (deepCopy $glob) $base) -}}
{{- end -}}

{{/*
Render the annotations block of a Thanos PrometheusRule alert.
Merges (in order of decreasing precedence):
  1. per-group .annotations (passed in)
  2. .Values.global.thanosRules.additionalRuleGroupAnnotations
  3. {summary, description, runbook_url} from the rule definition

Usage:
  {{- include "thanos.rules.alertAnnotations" (list $summary $description $runbook $globalAnn $groupAnn) | nindent 8 }}
*/}}
{{- define "thanos.rules.alertAnnotations" -}}
{{- $summary := index . 0 -}}
{{- $desc := index . 1 -}}
{{- $rb := index . 2 -}}
{{- $glob := index . 3 | default dict -}}
{{- $grp := index . 4 | default dict -}}
{{- $base := dict "summary" $summary "description" $desc "runbook_url" $rb -}}
{{- toYaml (merge (deepCopy $grp) (deepCopy $glob) $base) -}}
{{- end -}}

{{/*
Build the context dict consumed by every per-group rule helper.
Resolves group configs, label/annotation overrides, severity values
and job-pattern regexes into a single dict so each helper file can
just reference .compact, .grLab, .jpQuery, etc.

Usage:
  {{- $ctx := include "thanos.rules.context" . | fromYaml }}
  {{- include "thanos.rules.compact" $ctx }}
*/}}
{{- define "thanos.rules.context" -}}
{{- $tr := .Values.global.thanosRules -}}
{{- $sev := $tr.severity | default dict -}}
{{- $groups := $tr.groups | default dict -}}
{{- $compact := $groups.thanosCompact | default dict -}}
{{- $query := $groups.thanosQuery | default dict -}}
{{- $receive := $groups.thanosReceive | default dict -}}
{{- $sidecar := $groups.thanosSidecar | default dict -}}
{{- $store := $groups.thanosStore | default dict -}}
{{- $rule := $groups.thanosRule | default dict -}}
{{- $bucketRepl := $groups.thanosBucketReplicate | default dict -}}
{{- $absent := $groups.thanosComponentAbsent | default dict -}}
{{- /* Resolve `enabled` per group. Each group's own toggle defaults to
       true (false for sidecar/bucketReplicate which have no component
       in this chart). For groups that map to a chart component, the
       group is also AND-ed with that component's top-level `enabled`
       flag, so disabling a component (e.g. ruler.enabled=false) also
       silences its rule group and its ThanosXIsDown absent alert. */ -}}
{{- $defaults := dict "compact" true "query" true "receive" true "sidecar" false "store" true "rule" true "bucketRepl" false "absent" true -}}
{{- $compEn  := and (hasKey .Values "compactor")    (default false (index .Values "compactor"    "enabled")) -}}
{{- $qEn     := and (hasKey .Values "query")        (default false (index .Values "query"        "enabled")) -}}
{{- $rcEn    := and (hasKey .Values "receive")      (default false (index .Values "receive"      "enabled")) -}}
{{- $stEn    := and (hasKey .Values "storegateway") (default false (index .Values "storegateway" "enabled")) -}}
{{- $rEn     := and (hasKey .Values "ruler")        (default false (index .Values "ruler"        "enabled")) -}}
{{- $componentGate := dict "compact" $compEn "query" $qEn "receive" $rcEn "store" $stEn "rule" $rEn -}}
{{- $enabled := dict -}}
{{- range $k, $g := dict "compact" $compact "query" $query "receive" $receive "sidecar" $sidecar "store" $store "rule" $rule "bucketRepl" $bucketRepl "absent" $absent -}}
{{- $own := index $defaults $k -}}
{{- if hasKey $g "enabled" -}}{{- $own = $g.enabled -}}{{- end -}}
{{- if hasKey $componentGate $k -}}
{{- $_ := set $enabled $k (and $own (index $componentGate $k)) -}}
{{- else -}}
{{- $_ := set $enabled $k $own -}}
{{- end -}}
{{- end -}}
{{- $ctx := dict
  "runbook"      "https://github.com/thanos-io/thanos/tree/main/mixin/runbook.md"
  "sCrit"        ($sev.critical | default "critical")
  "sWarn"        ($sev.warning  | default "warning")
  "sInfo"        ($sev.info     | default "info")
  "grLab"        ($tr.additionalRuleGroupLabels      | default dict)
  "grAnn"        ($tr.additionalRuleGroupAnnotations | default dict)
  "compact"            $compact
  "query"              $query
  "receive"            $receive
  "sidecar"            $sidecar
  "store"              $store
  "rule"               $rule
  "bucketRepl"         $bucketRepl
  "absent"             $absent
  "compactEnabled"     (index $enabled "compact")
  "queryEnabled"       (index $enabled "query")
  "receiveEnabled"     (index $enabled "receive")
  "sidecarEnabled"     (index $enabled "sidecar")
  "storeEnabled"       (index $enabled "store")
  "ruleEnabled"        (index $enabled "rule")
  "bucketReplEnabled"  (index $enabled "bucketRepl")
  "absentEnabled"      (index $enabled "absent")
  "cLab"         ($compact.labels      | default dict)
  "cAnn"         ($compact.annotations | default dict)
  "qLab"         ($query.labels        | default dict)
  "qAnn"         ($query.annotations   | default dict)
  "rcLab"        ($receive.labels      | default dict)
  "rcAnn"        ($receive.annotations | default dict)
  "sLab"         ($sidecar.labels      | default dict)
  "sAnn"         ($sidecar.annotations | default dict)
  "stLab"        ($store.labels        | default dict)
  "stAnn"        ($store.annotations   | default dict)
  "rLab"         ($rule.labels         | default dict)
  "rAnn"         ($rule.annotations    | default dict)
  "brLab"        ($bucketRepl.labels      | default dict)
  "brAnn"        ($bucketRepl.annotations | default dict)
  "abLab"        ($absent.labels       | default dict)
  "abAnn"        ($absent.annotations  | default dict)
  "jpCompact"    ($compact.jobPattern    | default ".*thanos.*compact.*")
  "jpQuery"      ($query.jobPattern      | default ".*thanos.*query.*")
  "jpReceive"    ($receive.jobPattern    | default ".*thanos.*receive.*")
  "jpSidecar"    ($sidecar.jobPattern    | default ".*thanos.*sidecar.*")
  "jpStore"      ($store.jobPattern      | default ".*thanos.*store.*")
  "jpRule"       ($rule.jobPattern       | default ".*thanos.*rule.*")
  "jpBucketRepl" ($bucketRepl.jobPattern | default ".*thanos.*bucket-replicate.*")
-}}
{{- toYaml $ctx -}}
{{- end -}}
