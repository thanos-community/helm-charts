# thanos-query

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.16.0](https://img.shields.io/badge/AppVersion-v0.16.0-informational?style=flat-square)

A Helm chart for Kubernetes

**Homepage:** <https://thanos.io/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| spencergilbert |  |  |

## Source Code

* <https://github.com/thanos-io/thanos>
* <https://github.com/thanos-community/helm-charts>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for pod assignment ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |
| autoDownsampling | bool | `true` | Enable automatic adjustment (step / 5) to what source of data should be used in store gateways if no max_source_resolution param is specified. |
| autoscaling | object | `{"enabled":false,"maxReplicas":10,"minReplicas":1,"targetCPUUtilizationPercentage":80}` | Horizontal Pod Autoscaler configuration ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/ |
| deploymentAnnotations | object | `{}` | Add extra annotations to deployment ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| deploymentLabels | object | `{}` | Add extra labels to deployment ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/ |
| extraArgs | list | `[]` | Add extra arguments |
| extraContainers | string | `""` | Add extra containers to deployment ref: https://kubernetes.io/docs/concepts/workloads/pods/ |
| extraEnv | list | `[]` | Add extra environment variables |
| fullnameOverride | string | `""` |  |
| grpcIngress.annotations | object | `{}` | Add annotations to grpc ingress |
| grpcIngress.enabled | bool | `false` | Enable ingress for grpc endpoint |
| grpcIngress.hosts | string | `nil` |  |
| grpcIngress.labels | object | `{}` | Add extra labels to grpc ingress |
| grpcIngress.tls | list | `[]` |  |
| httpIngress.annotations | object | `{}` | Add annotations to http ingress |
| httpIngress.enabled | bool | `false` | Enable ingress for http endpoint |
| httpIngress.hosts | string | `nil` |  |
| httpIngress.labels | object | `{}` | Add extra labels to http ingress |
| httpIngress.tls | list | `[]` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"quay.io/thanos/thanos"` |  |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | list | `[]` |  |
| initContainers | string | `""` | Add initContainers to deployment ref: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/ |
| logFormat | string | `"logfmt"` | Log format to use. Possible options: logfmt or json |
| logLevel | string | `"info"` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` | Node labels for pod assignment ref: https://kubernetes.io/docs/user-guide/node-selection/ |
| partialResponse | bool | `true` | Enable partial response for queries if no partial_response param is specified. Setting to `false` will set "--no-query.partial-response". |
| podAnnotations | object | `{}` | Add extra annotations to pod template ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| podLabels | object | `{}` | Add extra labels to pod template ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/ |
| podSecurityContext | object | `{}` | Kubernetes Security Context (pod) ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| replicaCount | int | `1` |  |
| replicaLabels | list | `[]` | Labels to treat as a replica indicator along which data is deduplicated. Still you will be able to query without deduplication using 'dedup=false' parameter. |
| resources | object | `{}` | Resource requests and limits ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ |
| securityContext | object | `{}` | Kubernetes Security Context (container) ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/ |
| selectorLabels | list | `[]` | Query selector labels that will be exposed in info endpoint |
| service.annotations | object | `{}` | Add annotations to service |
| service.headless | bool | `false` |  |
| service.labels | object | `{}` | Add extra labels to service |
| service.matchLabels | object | `{}` | Add labels for service selector |
| service.port.grpc | int | `10901` |  |
| service.port.http | int | `9090` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.labels | object | `{}` | Labels to add to the service account |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| serviceMonitor | object | `{"enabled":false,"relabelings":[{"separator":"/","sourceLabels":["namespace","pod"],"targetLabel":"instance"}]}` | Prometheus Operator's ServiceMonitor configuration |
| stores | list | `[]` | Addresses of statically configured store API servers (repeatable). The scheme may be prefixed with 'dns+' or 'dnssrv+' to detect store API servers through respective DNS lookups. |
| strategy | object | `{}` | Kubernetes deployment strategy object ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |
| tolerations | list | `[]` | Tolerations for pod assignment ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ |
| tracingConfig | object | `{}` | Alternative to 'tracing.config-file' flag (lower priority). Content of YAML file with tracing configuration. See format details: https://thanos.io/tip/thanos/tracing.md |

