# thanos-query-frontend

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.16.0](https://img.shields.io/badge/AppVersion-v0.16.0-informational?style=flat-square)

A Helm chart for deploying thanos-query-frontend on Kubernetes.

**Homepage:** <https://thanos.io/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| spencergilbert |  |  |
| obiesmans |  |  |

## Source Code

* <https://github.com/thanos-io/thanos>
* <https://github.com/thanos-community/helm-charts>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for pod assignment ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |
| autoscaling | object | `{"enabled":false,"maxReplicas":10,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Horizontal Pod Autoscaler configuration ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/ |
| cacheCompressionType | string | `""` | Use compression in results cache. Supported values are: "snappy" and "" (disable compression). |
| deploymentAnnotations | object | `{}` | Add extra annotations to deployment ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| deploymentLabels | object | `{}` | Add extra labels to deployment ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/ |
| downstreamUrl | string | `http://thanos-query.default.svc.cluster.local:9090` | URL of downstream Prometheus Query compatible API. | compressResponses | bool | `true` | Compress HTTP responses. |
| extraEnv | list | `[]` | Add extra environment variables |
| fullnameOverride | string | `""` |  |
| httpGracePeriod | string | `2m` | Time to wait after an interrupt received for HTTP Server.
| ingress.annotations | object | `{}` | Add annotations to http ingress |
| ingress.enabled | bool | `false` | Enable ingress for http endpoint |
| ingress.hosts | string | `nil` |  |
| ingress.labels | object | `{}` | Add extra labels to http ingress |
| ingress.tls | list | `[]` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"quay.io/thanos/thanos"` |  |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` |  |
| logFormat | string | `"logfmt"` | Log format to use. Possible options: logfmt or json |
| logLevel | string | `"info"` |  |
| logQueriesLongerThan | string | `5s` | Log queries that are slower than the specified duration. Set to 0 to disable. Set to `< 0` to enable on all queries. |
| logRequestDecision | string | `LogFinishCall` | Request Logging for logging the start and end of requests. `LogFinishCall` : Logs the finish call of the requests. `LogStartAndFinishCall` : Logs the start and finish call of the requests. `NoLogCall` : Disable request logging. |
| maxReplicas | int | `5` | Maximum number of retries for a single request; beyond this, the downstream error is returned. |
| maxQueryLength | int | `0` | Limit the query time range (end - start time) in the query-frontend, 0 disables it. |
| maxQueryParallelism | int | `14` | Maximum number of queries will be scheduled in parallel by the frontend. |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` | Node labels for pod assignment ref: https://kubernetes.io/docs/user-guide/node-selection/ |
| partialResponse | bool | `true` | Enable partial response for queries if no partial_response param is specified. |
| podAnnotations | object | `{}` | Add extra annotations to pod template ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| podLabels | object | `{}` | Add extra labels to pod template ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/ |
| podSecurityContext | object | `{}` | Kubernetes Security Context (pod) ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| resources | object | `{}` | Resource requests and limits ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ |
| replicaCount | int | `1` |  |
| responseCacheConfig | object | `{"type":"IN-MEMORY", "config":{"max_size":0,"max_size_items":2048, "validity":"6h"}}` | Response cache configuration ref : https://thanos.io/v0.16/components/query-frontend.md/#caching |
| responseCacheMaxFreshness | string | `1m` | Most recent allowed cacheable result, to prevent caching very recent results that might still be in flux. |
| securityContext | object | `{}` | Kubernetes Security Context (thanos-query-frontend container) ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| service.annotations | object | `{}` | Add annotations to service |
| service.headless | bool | `false` |  |
| service.labels | object | `{}` | Add extra labels to service |
| service.matchLabels | object | `{}` | Add labels for service selector |
| service.port | int | `9090` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.labels | object | `{}` | Labels to add to the service account |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| serviceMonitor | object | `{"enabled":false,"relabelings":[{"separator":"/","sourceLabels":["namespace","pod"],"targetLabel":"instance"}]}` | Prometheus Operator's ServiceMonitor configuration |
| splitInterval | string | `24h` | Split queries by an interval and execute in parallel, 0 disables it. |
| strategy | object | `{}` | Kubernetes deployment strategy object ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |
| tolerations | list | `[]` | Tolerations for pod assignment ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ |
| tracingConfig | object | `{}` | Alternative to 'tracing.config-file' flag (lower priority). Content of YAML file with tracing configuration. See format details: https://thanos.io/tip/thanos/tracing.md |

