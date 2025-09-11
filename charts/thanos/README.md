# thanos

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.39.2](https://img.shields.io/badge/AppVersion-v0.39.2-informational?style=flat-square)

A Helm chart for Kubernetes

**Homepage:** <https://thanos.io/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| hamdikh |  |  |

## Source Code

* <https://github.com/thanos-io/thanos>
* <https://github.com/thanos-community/helm-charts>

## Requirements

Kubernetes: `>= 1.30.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| bucket.bucketweb.containerSecurityContext | object | `{}` |  |
| bucket.bucketweb.enabled | bool | `false` |  |
| bucket.bucketweb.extraArgs | list | `[]` |  |
| bucket.bucketweb.extraVolumeMounts | list | `[]` |  |
| bucket.bucketweb.extraVolumes | list | `[]` |  |
| bucket.bucketweb.podSecurityContext | object | `{}` |  |
| bucket.bucketweb.probes.liveness.enabled | bool | `true` |  |
| bucket.bucketweb.probes.liveness.failureThreshold | int | `6` |  |
| bucket.bucketweb.probes.liveness.initialDelaySeconds | int | `30` |  |
| bucket.bucketweb.probes.liveness.path | string | `"/-/healthy"` |  |
| bucket.bucketweb.probes.liveness.periodSeconds | int | `10` |  |
| bucket.bucketweb.probes.liveness.port | int | `10902` |  |
| bucket.bucketweb.probes.liveness.successThreshold | int | `1` |  |
| bucket.bucketweb.probes.liveness.timeoutSeconds | int | `5` |  |
| bucket.bucketweb.probes.readiness.enabled | bool | `true` |  |
| bucket.bucketweb.probes.readiness.failureThreshold | int | `6` |  |
| bucket.bucketweb.probes.readiness.initialDelaySeconds | int | `5` |  |
| bucket.bucketweb.probes.readiness.path | string | `"/-/ready"` |  |
| bucket.bucketweb.probes.readiness.periodSeconds | int | `10` |  |
| bucket.bucketweb.probes.readiness.port | int | `10902` |  |
| bucket.bucketweb.probes.readiness.successThreshold | int | `1` |  |
| bucket.bucketweb.probes.readiness.timeoutSeconds | int | `5` |  |
| bucket.bucketweb.probes.startup.enabled | bool | `true` |  |
| bucket.bucketweb.probes.startup.failureThreshold | int | `60` |  |
| bucket.bucketweb.probes.startup.initialDelaySeconds | int | `0` |  |
| bucket.bucketweb.probes.startup.path | string | `"/-/ready"` |  |
| bucket.bucketweb.probes.startup.periodSeconds | int | `5` |  |
| bucket.bucketweb.probes.startup.port | int | `10902` |  |
| bucket.bucketweb.probes.startup.successThreshold | int | `1` |  |
| bucket.bucketweb.probes.startup.timeoutSeconds | int | `5` |  |
| bucket.bucketweb.resources | object | `{}` |  |
| bucket.bucketweb.service.port | int | `10902` |  |
| bucket.bucketweb.service.type | string | `"ClusterIP"` |  |
| bucket.enabled | bool | `false` |  |
| compactor.containerSecurityContext | object | `{}` |  |
| compactor.enabled | bool | `true` |  |
| compactor.extraArgs[0] | string | `"--log.level=info"` |  |
| compactor.extraArgs[1] | string | `"--log.format=logfmt"` |  |
| compactor.extraArgs[2] | string | `"--retention.resolution-raw=30d"` |  |
| compactor.extraArgs[3] | string | `"--retention.resolution-5m=90d"` |  |
| compactor.extraArgs[4] | string | `"--retention.resolution-1h=365d"` |  |
| compactor.extraArgs[5] | string | `"--consistency-delay=30m"` |  |
| compactor.extraArgs[6] | string | `"--wait"` |  |
| compactor.persistence.enabled | bool | `true` |  |
| compactor.persistence.size | string | `"10Gi"` |  |
| compactor.persistence.storageClass | string | `""` |  |
| compactor.podSecurityContext.fsGroup | int | `1000` |  |
| compactor.podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| compactor.probes.extraVolumeMounts | list | `[]` |  |
| compactor.probes.extraVolumes | list | `[]` |  |
| compactor.probes.liveness.enabled | bool | `true` |  |
| compactor.probes.liveness.failureThreshold | int | `6` |  |
| compactor.probes.liveness.initialDelaySeconds | int | `30` |  |
| compactor.probes.liveness.path | string | `"/-/healthy"` |  |
| compactor.probes.liveness.periodSeconds | int | `10` |  |
| compactor.probes.liveness.port | int | `10902` |  |
| compactor.probes.liveness.successThreshold | int | `1` |  |
| compactor.probes.liveness.timeoutSeconds | int | `5` |  |
| compactor.probes.readiness.enabled | bool | `true` |  |
| compactor.probes.readiness.failureThreshold | int | `6` |  |
| compactor.probes.readiness.initialDelaySeconds | int | `5` |  |
| compactor.probes.readiness.path | string | `"/-/ready"` |  |
| compactor.probes.readiness.periodSeconds | int | `10` |  |
| compactor.probes.readiness.port | int | `10902` |  |
| compactor.probes.readiness.successThreshold | int | `1` |  |
| compactor.probes.readiness.timeoutSeconds | int | `5` |  |
| compactor.probes.startup.enabled | bool | `true` |  |
| compactor.probes.startup.failureThreshold | int | `60` |  |
| compactor.probes.startup.initialDelaySeconds | int | `0` |  |
| compactor.probes.startup.path | string | `"/-/ready"` |  |
| compactor.probes.startup.periodSeconds | int | `5` |  |
| compactor.probes.startup.port | int | `10902` |  |
| compactor.probes.startup.successThreshold | int | `1` |  |
| compactor.probes.startup.timeoutSeconds | int | `5` |  |
| compactor.resources | object | `{}` |  |
| compactor.service.port | int | `10902` |  |
| compactor.service.type | string | `"ClusterIP"` |  |
| global.commonLabels | object | `{}` |  |
| global.containerSecurityContext.allowPrivilegeEscalation | bool | `false` |  |
| global.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| global.containerSecurityContext.readOnlyRootFilesystem | bool | `true` |  |
| global.containerSecurityContext.runAsNonRoot | bool | `true` |  |
| global.extraVolumeMounts | list | `[]` |  |
| global.extraVolumes | list | `[]` |  |
| global.image.pullPolicy | string | `"IfNotPresent"` |  |
| global.image.repository | string | `"quay.io/thanos/thanos"` |  |
| global.image.tag | string | `"v0.39.2"` |  |
| global.objstore.config | string | `"type: GCS\nconfig:\n  bucket: change-me\n  endpoint: storage.googleapis.com\n  region: eu-west-1\n  access_key: change-me\n  secret_key: change-me\n  insecure: false\n"` |  |
| global.objstore.createSecret | bool | `false` |  |
| global.objstore.secretKey | string | `"objstore.yml"` |  |
| global.objstore.secretName | string | `"thanos-objstore"` |  |
| global.podAnnotations | object | `{}` |  |
| global.podSecurityContext | object | `{}` |  |
| query.containerSecurityContext | object | `{}` |  |
| query.enabled | bool | `true` |  |
| query.extraArgs[0] | string | `"--log.level=info"` |  |
| query.podSecurityContext | object | `{}` |  |
| query.probes.extraVolumeMounts | list | `[]` |  |
| query.probes.extraVolumes | list | `[]` |  |
| query.probes.liveness.enabled | bool | `true` |  |
| query.probes.liveness.failureThreshold | int | `6` |  |
| query.probes.liveness.initialDelaySeconds | int | `30` |  |
| query.probes.liveness.path | string | `"/-/healthy"` |  |
| query.probes.liveness.periodSeconds | int | `10` |  |
| query.probes.liveness.port | int | `9090` |  |
| query.probes.liveness.successThreshold | int | `1` |  |
| query.probes.liveness.timeoutSeconds | int | `5` |  |
| query.probes.readiness.enabled | bool | `true` |  |
| query.probes.readiness.failureThreshold | int | `6` |  |
| query.probes.readiness.initialDelaySeconds | int | `5` |  |
| query.probes.readiness.path | string | `"/-/ready"` |  |
| query.probes.readiness.periodSeconds | int | `10` |  |
| query.probes.readiness.port | int | `9090` |  |
| query.probes.readiness.successThreshold | int | `1` |  |
| query.probes.readiness.timeoutSeconds | int | `5` |  |
| query.probes.startup.enabled | bool | `true` |  |
| query.probes.startup.failureThreshold | int | `60` |  |
| query.probes.startup.initialDelaySeconds | int | `0` |  |
| query.probes.startup.path | string | `"/-/ready"` |  |
| query.probes.startup.periodSeconds | int | `5` |  |
| query.probes.startup.port | int | `9090` |  |
| query.probes.startup.successThreshold | int | `1` |  |
| query.probes.startup.timeoutSeconds | int | `5` |  |
| query.replicaCount | int | `2` |  |
| query.replicaLabels[0] | string | `"prometheus_replica"` |  |
| query.resources | object | `{}` |  |
| query.service.grpcPort | int | `10901` |  |
| query.service.httpPort | int | `9090` |  |
| query.service.type | string | `"ClusterIP"` |  |
| query.stores | list | `[]` |  |
| queryFrontend.cacheConfig | string | `""` |  |
| queryFrontend.containerSecurityContext | object | `{}` |  |
| queryFrontend.downstreamUrl | string | `""` |  |
| queryFrontend.enabled | bool | `false` |  |
| queryFrontend.extraArgs | list | `[]` |  |
| queryFrontend.podSecurityContext | object | `{}` |  |
| queryFrontend.probes.extraVolumeMounts | list | `[]` |  |
| queryFrontend.probes.extraVolumes | list | `[]` |  |
| queryFrontend.probes.liveness.enabled | bool | `true` |  |
| queryFrontend.probes.liveness.failureThreshold | int | `6` |  |
| queryFrontend.probes.liveness.initialDelaySeconds | int | `30` |  |
| queryFrontend.probes.liveness.path | string | `"/-/healthy"` |  |
| queryFrontend.probes.liveness.periodSeconds | int | `10` |  |
| queryFrontend.probes.liveness.port | int | `9090` |  |
| queryFrontend.probes.liveness.successThreshold | int | `1` |  |
| queryFrontend.probes.liveness.timeoutSeconds | int | `5` |  |
| queryFrontend.probes.readiness.enabled | bool | `true` |  |
| queryFrontend.probes.readiness.failureThreshold | int | `6` |  |
| queryFrontend.probes.readiness.initialDelaySeconds | int | `5` |  |
| queryFrontend.probes.readiness.path | string | `"/-/ready"` |  |
| queryFrontend.probes.readiness.periodSeconds | int | `10` |  |
| queryFrontend.probes.readiness.port | int | `9090` |  |
| queryFrontend.probes.readiness.successThreshold | int | `1` |  |
| queryFrontend.probes.readiness.timeoutSeconds | int | `5` |  |
| queryFrontend.probes.startup.enabled | bool | `true` |  |
| queryFrontend.probes.startup.failureThreshold | int | `60` |  |
| queryFrontend.probes.startup.initialDelaySeconds | int | `0` |  |
| queryFrontend.probes.startup.path | string | `"/-/ready"` |  |
| queryFrontend.probes.startup.periodSeconds | int | `5` |  |
| queryFrontend.probes.startup.port | int | `9090` |  |
| queryFrontend.probes.startup.successThreshold | int | `1` |  |
| queryFrontend.probes.startup.timeoutSeconds | int | `5` |  |
| queryFrontend.replicaCount | int | `2` |  |
| queryFrontend.resources | object | `{}` |  |
| queryFrontend.service.port | int | `9090` |  |
| queryFrontend.service.type | string | `"ClusterIP"` |  |
| receive.containerSecurityContext | object | `{}` |  |
| receive.enabled | bool | `true` |  |
| receive.extraArgs | list | `[]` |  |
| receive.extraVolumeMounts | list | `[]` |  |
| receive.extraVolumes | list | `[]` |  |
| receive.persistence.enabled | bool | `true` |  |
| receive.persistence.size | string | `"10Gi"` |  |
| receive.persistence.storageClass | string | `""` |  |
| receive.podSecurityContext.fsGroup | int | `1000` |  |
| receive.podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| receive.probes.liveness.enabled | bool | `true` |  |
| receive.probes.liveness.failureThreshold | int | `6` |  |
| receive.probes.liveness.initialDelaySeconds | int | `30` |  |
| receive.probes.liveness.path | string | `"/-/healthy"` |  |
| receive.probes.liveness.periodSeconds | int | `10` |  |
| receive.probes.liveness.port | int | `10902` |  |
| receive.probes.liveness.successThreshold | int | `1` |  |
| receive.probes.liveness.timeoutSeconds | int | `5` |  |
| receive.probes.readiness.enabled | bool | `true` |  |
| receive.probes.readiness.failureThreshold | int | `6` |  |
| receive.probes.readiness.initialDelaySeconds | int | `5` |  |
| receive.probes.readiness.path | string | `"/-/ready"` |  |
| receive.probes.readiness.periodSeconds | int | `10` |  |
| receive.probes.readiness.port | int | `10902` |  |
| receive.probes.readiness.successThreshold | int | `1` |  |
| receive.probes.readiness.timeoutSeconds | int | `5` |  |
| receive.probes.startup.enabled | bool | `true` |  |
| receive.probes.startup.failureThreshold | int | `60` |  |
| receive.probes.startup.initialDelaySeconds | int | `0` |  |
| receive.probes.startup.path | string | `"/-/ready"` |  |
| receive.probes.startup.periodSeconds | int | `5` |  |
| receive.probes.startup.port | int | `10902` |  |
| receive.probes.startup.successThreshold | int | `1` |  |
| receive.probes.startup.timeoutSeconds | int | `5` |  |
| receive.replicaCount | int | `3` |  |
| receive.resources | object | `{}` |  |
| receive.service.grpcPort | int | `10901` |  |
| receive.service.httpPort | int | `10902` |  |
| receive.service.type | string | `"ClusterIP"` |  |
| receive.tenancyHeader | string | `""` |  |
| receive.tsdb.retention | string | `"24h"` |  |
| receive.tsdb.walCompression | bool | `true` |  |
| ruler.alertQueryUrl | string | `""` |  |
| ruler.alertmanagers.config | string | `"static_configs:\n  - targets: [\"alertmanager.monitoring.svc.cluster.local:9093\"]\n"` |  |
| ruler.containerSecurityContext | object | `{}` |  |
| ruler.enabled | bool | `false` |  |
| ruler.extraArgs | list | `[]` |  |
| ruler.persistence.enabled | bool | `true` |  |
| ruler.persistence.size | string | `"10Gi"` |  |
| ruler.persistence.storageClass | string | `""` |  |
| ruler.podSecurityContext.fsGroup | int | `1000` |  |
| ruler.podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| ruler.probes.extraVolumeMounts | list | `[]` |  |
| ruler.probes.extraVolumes | list | `[]` |  |
| ruler.probes.liveness.enabled | bool | `true` |  |
| ruler.probes.liveness.failureThreshold | int | `6` |  |
| ruler.probes.liveness.initialDelaySeconds | int | `30` |  |
| ruler.probes.liveness.path | string | `"/-/healthy"` |  |
| ruler.probes.liveness.periodSeconds | int | `10` |  |
| ruler.probes.liveness.port | int | `10902` |  |
| ruler.probes.liveness.successThreshold | int | `1` |  |
| ruler.probes.liveness.timeoutSeconds | int | `5` |  |
| ruler.probes.readiness.enabled | bool | `true` |  |
| ruler.probes.readiness.failureThreshold | int | `6` |  |
| ruler.probes.readiness.initialDelaySeconds | int | `5` |  |
| ruler.probes.readiness.path | string | `"/-/ready"` |  |
| ruler.probes.readiness.periodSeconds | int | `10` |  |
| ruler.probes.readiness.port | int | `10902` |  |
| ruler.probes.readiness.successThreshold | int | `1` |  |
| ruler.probes.readiness.timeoutSeconds | int | `5` |  |
| ruler.probes.startup.enabled | bool | `true` |  |
| ruler.probes.startup.failureThreshold | int | `60` |  |
| ruler.probes.startup.initialDelaySeconds | int | `0` |  |
| ruler.probes.startup.path | string | `"/-/ready"` |  |
| ruler.probes.startup.periodSeconds | int | `5` |  |
| ruler.probes.startup.port | int | `10902` |  |
| ruler.probes.startup.successThreshold | int | `1` |  |
| ruler.probes.startup.timeoutSeconds | int | `5` |  |
| ruler.query.urls | list | `[]` |  |
| ruler.replicaCount | int | `2` |  |
| ruler.resources | object | `{}` |  |
| ruler.rules."example-alerts.yaml" | string | `"groups:\n  - name: thanos-example\n    rules:\n      - alert: ExampleAlwaysFiring\n        expr: vector(1)\n        for: 1m\n        labels:\n          severity: warning\n        annotations:\n          summary: Example alert firing\n"` |  |
| ruler.service.httpPort | int | `10902` |  |
| ruler.service.type | string | `"ClusterIP"` |  |
| storegateway.cachingBucketConfig | string | `""` |  |
| storegateway.containerSecurityContext | object | `{}` |  |
| storegateway.enabled | bool | `true` |  |
| storegateway.extraArgs | list | `[]` |  |
| storegateway.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| storegateway.persistence.enabled | bool | `true` |  |
| storegateway.persistence.size | string | `"10Gi"` |  |
| storegateway.persistence.storageClass | string | `""` |  |
| storegateway.podSecurityContext.fsGroup | int | `1000` |  |
| storegateway.podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| storegateway.probes.extraVolumeMounts | list | `[]` |  |
| storegateway.probes.extraVolumes | list | `[]` |  |
| storegateway.probes.liveness.enabled | bool | `true` |  |
| storegateway.probes.liveness.failureThreshold | int | `6` |  |
| storegateway.probes.liveness.initialDelaySeconds | int | `30` |  |
| storegateway.probes.liveness.path | string | `"/-/healthy"` |  |
| storegateway.probes.liveness.periodSeconds | int | `10` |  |
| storegateway.probes.liveness.port | int | `10902` |  |
| storegateway.probes.liveness.successThreshold | int | `1` |  |
| storegateway.probes.liveness.timeoutSeconds | int | `5` |  |
| storegateway.probes.readiness.enabled | bool | `true` |  |
| storegateway.probes.readiness.failureThreshold | int | `6` |  |
| storegateway.probes.readiness.initialDelaySeconds | int | `5` |  |
| storegateway.probes.readiness.path | string | `"/-/ready"` |  |
| storegateway.probes.readiness.periodSeconds | int | `10` |  |
| storegateway.probes.readiness.port | int | `10902` |  |
| storegateway.probes.readiness.successThreshold | int | `1` |  |
| storegateway.probes.readiness.timeoutSeconds | int | `5` |  |
| storegateway.probes.startup.enabled | bool | `true` |  |
| storegateway.probes.startup.failureThreshold | int | `60` |  |
| storegateway.probes.startup.initialDelaySeconds | int | `0` |  |
| storegateway.probes.startup.path | string | `"/-/ready"` |  |
| storegateway.probes.startup.periodSeconds | int | `5` |  |
| storegateway.probes.startup.port | int | `10902` |  |
| storegateway.probes.startup.successThreshold | int | `1` |  |
| storegateway.probes.startup.timeoutSeconds | int | `5` |  |
| storegateway.replicaCount | int | `2` |  |
| storegateway.resources | object | `{}` |  |
| storegateway.service.grpcPort | int | `10901` |  |
| storegateway.service.httpPort | int | `10902` |  |
| storegateway.service.type | string | `"ClusterIP"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
