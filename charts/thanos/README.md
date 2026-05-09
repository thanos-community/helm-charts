# Thanos Helm Chart

![Version: 0.10.1](https://img.shields.io/badge/Version-0.10.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.41.0](https://img.shields.io/badge/AppVersion-v0.41.0-informational?style=flat-square)

<p align="center"><img src="../../docs/imgs/thanos_logo_full.svg" alt="Thanos Logo" width="300"/></p>

A helm chart to setup Thanos on Kubernetes, a highly available Prometheus setup with long term storage capabilities.

## TL;DR

```bash
helm install thanos oci://ghcr.io/thanos-community/helm-charts/thanos \
  --namespace monitoring \
  --create-namespace
```

## Architecture

![Thanos High Level Architecture](../../docs/imgs/thanos_hld_arch.png)

Thanos extends Prometheus with global query view, long-term storage, and high availability. It is composed of several independently deployable components that each serve a specific role.

Refer to the [Thanos component docs](https://thanos.io/tip/thanos/quick-tutorial.md/#components) for an in-depth explanation.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| hamdikh | <hamdi.khelil@kapheira.cloud> |  |

## Source Code

* <https://github.com/thanos-io/thanos>
* <https://github.com/thanos-community/helm-charts>

## Prerequisites

- Kubernetes `>= 1.30.0-0`
- Helm >= 3.8 (OCI registry support)
- An object store bucket — GCS, S3, Azure Blob, or any S3-compatible store

## Requirements

Kubernetes: `>= 1.30.0-0`

| Repository | Name | Version |
|------------|------|---------|
| https://charts.rustfs.com/ | rustfs | 0.1.0 |
| https://prometheus-community.github.io/helm-charts | kube-prometheus-stack(kube-prometheus-stack) | 84.5.0 |

## Component Overview

The chart deploys each Thanos component as an independent workload. Enable only what you need.

| Component | Enabled by Default | Workload | Purpose |
|-----------|--------------------|----------|---------|
| **query** | Yes | Deployment | Fan-out query engine. Queries multiple Store API endpoints and deduplicates results. This is the Prometheus-compatible query entrypoint. |
| **receive** | Yes | StatefulSet | Remote-write endpoint. Accepts Prometheus `remote_write` traffic, stores samples locally, and ships blocks to the object store. |
| **storegateway** | Yes | StatefulSet | Serves historical blocks from the object store over the Store API. Required for querying data older than what Prometheus/Receive holds locally. |
| **compactor** | Yes | StatefulSet | Compacts and downsamples blocks in the object store. Runs as a singleton — do not scale above 1 replica. |
| **query-frontend** | No | Deployment | Optional caching and query-splitting layer in front of Query. Reduces load for repeated or heavy queries. |
| **ruler** | No | StatefulSet | Evaluates alerting and recording rules by querying the Query component. Sends alerts to Alertmanager. |
| **bucket (bucketweb)** | No | Deployment | Read-only web UI for inspecting blocks in the object store. Useful for debugging, not needed in production. |

## Installation

### 1. Add the Helm repository (optional, for non-OCI installs)

```bash
helm repo add thanos-community https://thanos-community.github.io/helm-charts
helm repo update
```

### 2. Configure object store credentials

All stateful Thanos components (Receive, Store Gateway, Compactor, Ruler) need access to an object store.

Create a `values.yaml` file with your object store configuration:

```yaml
global:
  objstore:
    # Set createSecret: true to let the chart create the Secret from the inline config below.
    # Set createSecret: false (default) if you manage the Secret externally.
    createSecret: true
    secretName: thanos-objstore
    secretKey: objstore.yml
    config: |
      type: S3
      config:
        bucket: my-thanos-bucket
        endpoint: s3.eu-west-1.amazonaws.com
        region: eu-west-1
        access_key: <ACCESS_KEY>
        secret_key: <SECRET_KEY>
```

### 3. Install the chart

```bash
helm install thanos oci://ghcr.io/thanos-community/helm-charts/thanos \
  --namespace monitoring \
  --create-namespace \
  -f values.yaml
```

### 4. Verify the installation

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/instance=thanos
```

## Object Store Configuration

The object store config is shared by all components that write to or read from the object store. It follows the [Thanos object store YAML format](https://thanos.io/tip/thanos/storage.md/).

### Providing credentials

**Option A — let the chart create the Secret** (suitable for development):

```yaml
global:
  objstore:
    createSecret: true
    config: |
      type: GCS
      config:
        bucket: my-bucket
```

**Option B — bring your own Secret** (recommended for production):

Create the Secret externally (e.g. via Vault, External Secrets Operator, or `kubectl`):

```bash
kubectl create secret generic thanos-objstore \
  --from-file=objstore.yml=./objstore.yml \
  -n monitoring
```

Then reference it in values:

```yaml
global:
  objstore:
    createSecret: false
    secretName: thanos-objstore
    secretKey: objstore.yml
```

### Provider examples

<details>
<summary>Google Cloud Storage (GCS)</summary>

```yaml
type: GCS
config:
  bucket: my-thanos-bucket
  service_account: |-
    {
      "type": "service_account",
      ...
    }
```

</details>

<details>
<summary>Amazon S3 / S3-compatible</summary>

```yaml
type: S3
config:
  bucket: my-thanos-bucket
  endpoint: s3.eu-west-1.amazonaws.com
  region: eu-west-1
  access_key: AKIAIOSFODNN7EXAMPLE
  secret_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

</details>

<details>
<summary>Azure Blob Storage</summary>

```yaml
type: AZURE
config:
  storage_account: mystorageaccount
  storage_account_key: <BASE64_ENCODED_KEY>
  container: thanos
  endpoint_suffix: core.windows.net
```

</details>

## Key Configuration Sections

### Global defaults

Settings under `global` apply to **all components** unless overridden at the component level. This avoids repeating common values (image, security context, node selectors, etc.).

```yaml
global:
  image:
    repository: quay.io/thanos/thanos
    tag: v0.39.2
    pullPolicy: IfNotPresent

  # Applied to every pod
  containerSecurityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop: [ALL]
    runAsNonRoot: true

  # Shared resource defaults (override per component as needed)
  resources: {}
  nodeSelector: {}
  tolerations: []
```

### Query

The Query component is the main entrypoint for PromQL queries. It fans out to all registered Store API endpoints and deduplicates results using replica labels.

```yaml
query:
  enabled: true
  replicaCount: 2

  # Labels that identify replica identity — used for deduplication
  replicaLabels:
    - prometheus_replica
    - receive_replica

  # gRPC --endpoint arguments. The in-chart components (Receive, Store Gateway) are auto-wired
  # when autogen.enabled is true. Endpoints defined in static[] are always appended; set
  # autogen.enabled to false to take full control of what endpoint arguments are passed.
  endpoints:
    autogen:
      enabled: true
    static: []
    # Example:
    # static:
    #   - thanos-storegateway.cluster1.internal:443
    #   - thanos-receive.cluster1.internal:443

  # Deprecated. Use query.endpoints.static[] instead.
  stores: []

  ingress:
    http:
      enabled: false
      className: nginx
      hosts:
        - host: thanos-query.example.com
          paths:
            - path: /
              pathType: Prefix
```

### Receive

The Receive component accepts Prometheus `remote_write` traffic and stores samples locally in a TSDB WAL before shipping blocks to the object store.

```yaml
receive:
  enabled: true
  replicaCount: 3           # Minimum 3 for a replication factor of 2

  tsdb:
    retention: 24h          # How long to keep data locally before it is uploaded
    walCompression: true    # Reduces IO and disk usage

  persistence:
    enabled: true
    size: 10Gi

  # Hashring topology — defaults to auto-generating a single ring
  hashrings:
    autogen:
      enabled: true
      name: default
    # static: []            # Set to override autogen with a custom hashring config
```

Configure Prometheus to remote-write to the Receive service:

```yaml
# In your Prometheus / kube-prometheus-stack values
prometheus:
  prometheusSpec:
    remoteWrite:
      - url: http://thanos-receive.monitoring.svc.cluster.local:10908/api/v1/receive
```

### Store Gateway

The Store Gateway exposes historical blocks from the object store over the Store API. Query routes requests for older data to this component.

```yaml
storegateway:
  enabled: true
  replicaCount: 2

  persistence:
    enabled: true
    size: 10Gi              # Used for index cache and chunk downloads

  # Optional: add a caching bucket layer (memcached/redis) to reduce object store calls
  cachingBucketConfig: ""
```

### Compactor

The Compactor runs as a **singleton** (one instance). It compacts blocks uploaded by Receive into larger blocks and downsamples them for faster long-range queries.

```yaml
compactor:
  enabled: true
  replicaCount: 1           # Do NOT increase — compactor must run as a singleton

  extraArgs:
    - --retention.resolution-raw=30d    # Keep raw samples for 30 days
    - --retention.resolution-5m=90d     # Keep 5m-downsampled data for 90 days
    - --retention.resolution-1h=365d    # Keep 1h-downsampled data for 1 year
    - --consistency-delay=30m
    - --wait

  persistence:
    enabled: true
    size: 10Gi              # Used as a working directory during compaction
```

### Query Frontend (optional)

Sits in front of the Query component. Splits large time-range queries, caches results, and reduces load for repeated queries.

```yaml
queryFrontend:
  enabled: false            # Enable when query load is significant

  # Downstream URL of the Query component (auto-resolved when both are in the same chart)
  downstreamUrl: ""

  # Optional: inline caching config (Memcached, Redis, in-memory)
  cacheConfig: ""
```

### Ruler (optional)

Evaluates alerting and recording rules on a schedule by querying the Query component, mirroring how Prometheus rules work.

```yaml
ruler:
  enabled: false

  query:
    urls:
      - http://thanos-query.monitoring.svc.cluster.local:9090

  alertmanagers:
    config: |
      static_configs:
        - targets: ["alertmanager.monitoring.svc.cluster.local:9093"]

  # Inline rule files (key = filename, value = YAML content)
  rules:
    my-alerts.yaml: |
      groups:
        - name: example
          rules:
            - alert: MyAlert
              expr: up == 0
              for: 5m

  # Auto-import PrometheusRule CRDs from the cluster (requires kube-prometheus-stack)
  autoImportPrometheusRules:
    enabled: true
    labelSelector: {}
```

### Monitoring (ServiceMonitor)

Enable Prometheus scraping for each component by enabling its `serviceMonitor`:

```yaml
global:
  serviceMonitor:
    enabled: true           # Enables ServiceMonitor for all components at once
    namespace: monitoring   # Namespace where ServiceMonitors are created
```

Or enable per component:

```yaml
query:
  serviceMonitor:
    enabled: true

receive:
  serviceMonitor:
    enabled: true
```

### Built-in alerting rules

The chart ships with a set of PrometheusRules for Thanos components. They are enabled by default:

```yaml
global:
  thanosRules:
    enabled: true
    severity:
      critical: critical
      warning: warning
    forDefaults:
      default: 2m
      short: 1m
      componentDown: 5m
```

## Upgrading

Before upgrading, review the [chart changelog](https://github.com/thanos-community/helm-charts/releases) and the [Thanos release notes](https://github.com/thanos-io/thanos/releases).

```bash
helm upgrade thanos oci://ghcr.io/thanos-community/helm-charts/thanos \
  --namespace monitoring \
  -f values.yaml
```

## Values Reference

The table below documents all available values. Top-level keys group settings by component. Component-level keys always take precedence over `global` defaults.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| bucket.bucketweb.affinity | object | {} | Affinity rules for Bucketweb pod scheduling. |
| bucket.bucketweb.annotations | object | {} | Extra annotations applied to Bucketweb resources. |
| bucket.bucketweb.autoscaling.enabled | bool | `false` | Enable HorizontalPodAutoscaler for Bucketweb. |
| bucket.bucketweb.autoscaling.maxReplicas | int | `3` | Maximum number of Bucketweb replicas. |
| bucket.bucketweb.autoscaling.minReplicas | int | `1` | Minimum number of Bucketweb replicas. |
| bucket.bucketweb.autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilisation percentage for Bucketweb autoscaling. |
| bucket.bucketweb.autoscaling.targetMemoryUtilizationPercentage | string | `nil` | Target memory utilisation percentage. Null disables memory-based scaling. |
| bucket.bucketweb.containerSecurityContext | object | {} | Container security context for Bucketweb. Overrides global.containerSecurityContext. |
| bucket.bucketweb.dnsConfig | object | {} | DNS configuration for Bucketweb pods. Overrides global.dnsConfig. |
| bucket.bucketweb.enabled | bool | `false` | Enable the Bucketweb deployment (read-only object store browser). |
| bucket.bucketweb.extraArgs | list | [] | Additional CLI arguments appended to the bucketweb command. |
| bucket.bucketweb.extraContainers | list | [] | Extra sidecar containers for Bucketweb pods. |
| bucket.bucketweb.extraEnv | list | [] | Extra environment variables injected into the Bucketweb container. |
| bucket.bucketweb.extraEnvFrom | list | [] | Extra environment variable sources for the Bucketweb container. |
| bucket.bucketweb.extraInitContainers | list | [] | Extra init containers for Bucketweb pods. |
| bucket.bucketweb.extraVolumeMounts | list | [] | Extra volume mounts for the Bucketweb container. |
| bucket.bucketweb.extraVolumes | list | [] | Extra volumes for Bucketweb pods. |
| bucket.bucketweb.httpRoute.annotations | object | {} | Annotations for the HTTPRoute resource. |
| bucket.bucketweb.httpRoute.enabled | bool | `false` | Enable a Gateway API HTTPRoute for Bucketweb (alternative to Ingress). |
| bucket.bucketweb.httpRoute.hostnames | list | [] | Hostnames to match. Empty matches all hostnames on the parent Gateway. |
| bucket.bucketweb.httpRoute.parentRefs | list | [] | Gateway parentRefs the HTTPRoute should attach to. |
| bucket.bucketweb.ingress.annotations | object | {} | Extra annotations for the Ingress resource. |
| bucket.bucketweb.ingress.className | string | `""` | Ingress class name (e.g. nginx, traefik). |
| bucket.bucketweb.ingress.enabled | bool | `false` | Enable a Kubernetes Ingress for Bucketweb. |
| bucket.bucketweb.ingress.hosts[0].host | string | `"bucketweb.local"` |  |
| bucket.bucketweb.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| bucket.bucketweb.ingress.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| bucket.bucketweb.ingress.tls | list | [] | TLS configuration for the Ingress. |
| bucket.bucketweb.labels | object | {} | Extra labels applied to Bucketweb resources. |
| bucket.bucketweb.nodeSelector | object | {} | Node selector for Bucketweb pod scheduling. |
| bucket.bucketweb.pdb.enabled | bool | `false` | Enable a PodDisruptionBudget for Bucketweb. |
| bucket.bucketweb.pdb.maxUnavailable | int or string | `""` | Maximum unavailable Bucketweb pods during a disruption. |
| bucket.bucketweb.pdb.minAvailable | int or string | `""` | Minimum available Bucketweb pods during a disruption. |
| bucket.bucketweb.persistence | object | {} | Storage configuration for Bucketweb. Bucketweb is stateless; leave empty. |
| bucket.bucketweb.podSecurityContext | object | {} | Pod security context for Bucketweb. Overrides global.podSecurityContext. |
| bucket.bucketweb.priorityClassName | string | `""` | Priority class name for Bucketweb pods. |
| bucket.bucketweb.probes.liveness.enabled | bool | `true` | Enable the liveness probe for Bucketweb. |
| bucket.bucketweb.probes.liveness.failureThreshold | int | `6` | Consecutive failures before the container is restarted. |
| bucket.bucketweb.probes.liveness.initialDelaySeconds | int | `30` | Seconds to wait before starting the liveness probe. |
| bucket.bucketweb.probes.liveness.path | string | `"/-/healthy"` | HTTP path checked by the liveness probe. |
| bucket.bucketweb.probes.liveness.periodSeconds | int | `10` | How often (seconds) to run the liveness probe. |
| bucket.bucketweb.probes.liveness.successThreshold | int | `1` | Consecutive successes before the container is considered live. |
| bucket.bucketweb.probes.liveness.timeoutSeconds | int | `5` | Seconds after which the probe times out. |
| bucket.bucketweb.probes.readiness.enabled | bool | `true` | Enable the readiness probe for Bucketweb. |
| bucket.bucketweb.probes.readiness.failureThreshold | int | `6` | Consecutive failures before the pod is marked not-ready. |
| bucket.bucketweb.probes.readiness.initialDelaySeconds | int | `5` | Seconds to wait before starting the readiness probe. |
| bucket.bucketweb.probes.readiness.path | string | `"/-/ready"` | HTTP path checked by the readiness probe. |
| bucket.bucketweb.probes.readiness.periodSeconds | int | `10` | How often (seconds) to run the readiness probe. |
| bucket.bucketweb.probes.readiness.successThreshold | int | `1` | Consecutive successes before the pod is marked ready. |
| bucket.bucketweb.probes.readiness.timeoutSeconds | int | `5` | Seconds after which the probe times out. |
| bucket.bucketweb.probes.startup.enabled | bool | `true` | Enable the startup probe for Bucketweb. |
| bucket.bucketweb.probes.startup.failureThreshold | int | `60` | Consecutive failures allowed during startup before the container is killed. |
| bucket.bucketweb.probes.startup.initialDelaySeconds | int | `0` | Seconds to wait before starting the startup probe. |
| bucket.bucketweb.probes.startup.path | string | `"/-/ready"` | HTTP path checked by the startup probe. |
| bucket.bucketweb.probes.startup.periodSeconds | int | `5` | How often (seconds) to run the startup probe. |
| bucket.bucketweb.probes.startup.successThreshold | int | `1` | Consecutive successes required before the startup probe is considered passed. |
| bucket.bucketweb.probes.startup.timeoutSeconds | int | `5` | Seconds after which the probe times out. |
| bucket.bucketweb.replicaCount | int | `1` | Number of Bucketweb pod replicas. |
| bucket.bucketweb.resources | object | {} | Resource requests and limits for the Bucketweb container. |
| bucket.bucketweb.service.annotations | object | {} | Extra annotations for the Bucketweb Service. |
| bucket.bucketweb.service.labels | object | {} | Extra labels for the Bucketweb Service. |
| bucket.bucketweb.service.port | int | `10902` | HTTP port exposed by the Bucketweb Service. |
| bucket.bucketweb.service.type | string | `"ClusterIP"` | Kubernetes Service type for Bucketweb. |
| bucket.bucketweb.serviceMonitor.annotations | object | {} | Extra annotations for the Bucketweb ServiceMonitor. |
| bucket.bucketweb.serviceMonitor.enabled | bool | `false` | Enable a Prometheus Operator ServiceMonitor for Bucketweb. |
| bucket.bucketweb.serviceMonitor.interval | string | `""` | Scrape interval for Bucketweb. Empty uses the Prometheus operator default. |
| bucket.bucketweb.serviceMonitor.labels | object | {} | Extra labels for the Bucketweb ServiceMonitor. |
| bucket.bucketweb.serviceMonitor.metricRelabelings | list | [] | Metric relabeling rules applied after Bucketweb metrics are ingested. |
| bucket.bucketweb.serviceMonitor.relabelings | list | [] | Relabeling rules applied before Bucketweb metrics are ingested. |
| bucket.bucketweb.serviceMonitor.scheme | string | `""` | Scrape scheme for Bucketweb (http or https). |
| bucket.bucketweb.serviceMonitor.scrapeTimeout | string | `""` | Scrape timeout for Bucketweb. Empty uses the Prometheus operator default. |
| bucket.bucketweb.serviceMonitor.tlsConfig | object | {} | TLS configuration for Bucketweb scraping. |
| bucket.bucketweb.tolerations | list | [] | Tolerations for Bucketweb pod scheduling. |
| bucket.bucketweb.topologySpreadConstraints | list | [] | Topology spread constraints for Bucketweb pods. |
| bucket.enabled | bool | `true` | Enable the bucket group. Must be true for the objstore Secret to be created when global.objstore.createSecret is true. |
| compactor.affinity | object | {} | Affinity rules for Compactor pod scheduling. |
| compactor.annotations | object | {} | Extra annotations applied to Compactor resources. |
| compactor.containerSecurityContext | object | {} | Container security context for the Compactor. Overrides global.containerSecurityContext. |
| compactor.dnsConfig | object | {} | DNS configuration for Compactor pods. Overrides global.dnsConfig. |
| compactor.enabled | bool | `true` | Enable the Compactor StatefulSet. |
| compactor.extraArgs[0] | string | `"--log.level=info"` |  |
| compactor.extraArgs[1] | string | `"--log.format=logfmt"` |  |
| compactor.extraArgs[2] | string | `"--retention.resolution-raw=30d"` |  |
| compactor.extraArgs[3] | string | `"--retention.resolution-5m=90d"` |  |
| compactor.extraArgs[4] | string | `"--retention.resolution-1h=365d"` |  |
| compactor.extraArgs[5] | string | `"--consistency-delay=30m"` |  |
| compactor.extraArgs[6] | string | `"--wait"` |  |
| compactor.extraContainers | list | [] | Extra sidecar containers for the Compactor pod. |
| compactor.extraEnv | list | [] | Extra environment variables injected into the Compactor container. |
| compactor.extraEnvFrom | list | [] | Extra environment variable sources for the Compactor container. |
| compactor.extraInitContainers | list | [] | Extra init containers for the Compactor pod. |
| compactor.extraVolumeMounts | list | [] | Extra volume mounts for the Compactor container. |
| compactor.extraVolumes | list | [] | Extra volumes for Compactor pods. |
| compactor.httpRoute.annotations | object | {} | Annotations for the Compactor HTTPRoute resource. |
| compactor.httpRoute.enabled | bool | `false` | Enable a Gateway API HTTPRoute for the Compactor HTTP endpoint. |
| compactor.httpRoute.hostnames | list | [] | Hostnames to match on the Compactor HTTPRoute. |
| compactor.httpRoute.parentRefs | list | [] | Gateway parentRefs for the Compactor HTTPRoute. |
| compactor.ingress.className | string | `""` | Ingress class name for the Compactor (e.g. nginx, traefik). |
| compactor.ingress.enabled | bool | `false` | Enable a Kubernetes Ingress for the Compactor HTTP endpoint. |
| compactor.ingress.hosts[0].host | string | `"compactor.local"` |  |
| compactor.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| compactor.ingress.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| compactor.ingress.tls | list | [] | TLS configuration for the Compactor Ingress. |
| compactor.labels | object | {} | Extra labels applied to Compactor resources. |
| compactor.nodeSelector | object | {} | Node selector for Compactor pod scheduling. |
| compactor.pdb.enabled | bool | `false` | Enable a PodDisruptionBudget for the Compactor. |
| compactor.pdb.maxUnavailable | int or string | `""` | Maximum unavailable Compactor pods during a disruption. |
| compactor.pdb.minAvailable | int or string | `""` | Minimum available Compactor pods during a disruption. |
| compactor.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| compactor.persistence.enabled | bool | `true` | Enable a PersistentVolumeClaim for the Compactor working directory. |
| compactor.persistence.size | string | `"10Gi"` | Storage capacity for the Compactor PVC (used as a scratch space during compaction). |
| compactor.persistence.storageClass | string | `""` | StorageClass name for the Compactor PVC. Empty uses the cluster default. |
| compactor.podSecurityContext.fsGroup | int | `1000` |  |
| compactor.podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| compactor.priorityClassName | string | `""` | Priority class name for Compactor pods. |
| compactor.probes.liveness.enabled | bool | `true` | Enable the liveness probe for the Compactor. |
| compactor.probes.liveness.failureThreshold | int | `6` | Consecutive failures before the Compactor container is restarted. |
| compactor.probes.liveness.initialDelaySeconds | int | `30` | Seconds to wait before starting the Compactor liveness probe. |
| compactor.probes.liveness.path | string | `"/-/healthy"` | HTTP path checked by the Compactor liveness probe. |
| compactor.probes.liveness.periodSeconds | int | `10` | How often (seconds) to run the Compactor liveness probe. |
| compactor.probes.liveness.successThreshold | int | `1` | Consecutive successes before the Compactor container is considered live. |
| compactor.probes.liveness.timeoutSeconds | int | `5` | Seconds after which the Compactor liveness probe times out. |
| compactor.probes.readiness.enabled | bool | `true` | Enable the readiness probe for the Compactor. |
| compactor.probes.readiness.failureThreshold | int | `6` | Consecutive failures before the Compactor pod is marked not-ready. |
| compactor.probes.readiness.initialDelaySeconds | int | `5` | Seconds to wait before starting the Compactor readiness probe. |
| compactor.probes.readiness.path | string | `"/-/ready"` | HTTP path checked by the Compactor readiness probe. |
| compactor.probes.readiness.periodSeconds | int | `10` | How often (seconds) to run the Compactor readiness probe. |
| compactor.probes.readiness.successThreshold | int | `1` | Consecutive successes before the Compactor pod is marked ready. |
| compactor.probes.readiness.timeoutSeconds | int | `5` | Seconds after which the Compactor readiness probe times out. |
| compactor.probes.startup.enabled | bool | `true` | Enable the startup probe for the Compactor. |
| compactor.probes.startup.failureThreshold | int | `60` | Consecutive failures during Compactor startup before the container is killed. |
| compactor.probes.startup.initialDelaySeconds | int | `0` | Seconds to wait before starting the Compactor startup probe. |
| compactor.probes.startup.path | string | `"/-/ready"` | HTTP path checked by the Compactor startup probe. |
| compactor.probes.startup.periodSeconds | int | `5` | How often (seconds) to run the Compactor startup probe. |
| compactor.probes.startup.successThreshold | int | `1` | Consecutive successes before the Compactor startup probe is considered passed. |
| compactor.probes.startup.timeoutSeconds | int | `5` | Seconds after which the Compactor startup probe times out. |
| compactor.replicaCount | int | `1` | Number of Compactor replicas. Must remain 1 — running multiple compactors against the same bucket causes data corruption. |
| compactor.resources | object | {} | Resource requests and limits for the Compactor container. |
| compactor.service.annotations | object | {} | Extra annotations for the Compactor Service. |
| compactor.service.labels | object | {} | Extra labels for the Compactor Service. |
| compactor.service.port | int | `10902` | HTTP port exposed by the Compactor Service. |
| compactor.service.type | string | `"ClusterIP"` | Kubernetes Service type for the Compactor HTTP endpoint. |
| compactor.serviceMonitor.annotations | object | {} | Extra annotations for the Compactor ServiceMonitor. |
| compactor.serviceMonitor.enabled | bool | `false` | Enable a Prometheus Operator ServiceMonitor for the Compactor. |
| compactor.serviceMonitor.interval | string | `""` | Scrape interval for the Compactor. Empty uses the Prometheus operator default. |
| compactor.serviceMonitor.labels | object | {} | Extra labels for the Compactor ServiceMonitor. |
| compactor.serviceMonitor.metricRelabelings | list | [] | Metric relabeling rules applied after Compactor metrics are ingested. |
| compactor.serviceMonitor.relabelings | list | [] | Relabeling rules applied before Compactor metrics are ingested. |
| compactor.serviceMonitor.scheme | string | `""` | Scrape scheme for the Compactor (http or https). |
| compactor.serviceMonitor.scrapeTimeout | string | `""` | Scrape timeout for the Compactor. Empty uses the Prometheus operator default. |
| compactor.serviceMonitor.tlsConfig | object | {} | TLS configuration for Compactor scraping. |
| compactor.tolerations | list | [] | Tolerations for Compactor pod scheduling. |
| compactor.topologySpreadConstraints | list | [] | Topology spread constraints for Compactor pods. |
| compactor.vpa.enabled | bool | `true` | Enable a VerticalPodAutoscaler for the Compactor. |
| compactor.vpa.maxAllowed.cpu | int | `4` | Maximum CPU resource enforced by the Compactor VPA. |
| compactor.vpa.maxAllowed.memory | string | `"8Gi"` | Maximum memory resource enforced by the Compactor VPA. |
| compactor.vpa.minAllowed.cpu | string | `"500m"` | Minimum CPU resource enforced by the Compactor VPA. |
| compactor.vpa.minAllowed.memory | string | `"512Mi"` | Minimum memory resource enforced by the Compactor VPA. |
| compactor.vpa.targetKind | string | `"StatefulSet"` | Kubernetes workload kind targeted by the Compactor VPA. |
| compactor.vpa.updateMode | string | `"Auto"` | VPA update mode for the Compactor. One of Auto, Off, or Initial. |
| global.affinity | object | {} | Affinity rules applied to every pod by default. |
| global.clusterDomain | string | `"cluster.local"` | Cluster DNS domain, used when constructing in-cluster endpoints. |
| global.commonLabels | object | {} | Extra labels merged into every Kubernetes resource created by this chart. |
| global.containerSecurityContext.allowPrivilegeEscalation | bool | `false` | Prevent privilege escalation inside the container. |
| global.containerSecurityContext.capabilities.drop[0] | string | `"ALL"` |  |
| global.containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mount the root filesystem as read-only. |
| global.containerSecurityContext.runAsNonRoot | bool | `true` | Require the container to run as a non-root user. |
| global.dnsConfig | object | {} | DNS configuration applied to every pod. Component-level values override this. |
| global.extraContainers | list | [] | Extra sidecar containers added to every pod by default. |
| global.extraEnv | list | [] | Extra environment variables injected into every main container by default. |
| global.extraEnvFrom | list | [] | Extra environment variable sources (ConfigMap, Secret) for every main container. |
| global.extraInitContainers | list | [] | Extra init containers added to every pod by default. |
| global.extraVolumeMounts | list | [] | Additional volume mounts added to every main container by default. |
| global.extraVolumes | list | [] | Additional volumes available to every pod by default. |
| global.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy applied to every container. One of Always, IfNotPresent, Never. |
| global.image.repository | string | `"quay.io/thanos/thanos"` | Docker repository for all Thanos containers by default. |
| global.image.tag | string | `"v0.41.0"` | Container image tag. Changing this upgrades all components at once. |
| global.imagePullSecrets | list | [] | List of imagePullSecrets applied to every pod by default. |
| global.networkPolicies | bool | `false` | Create a NetworkPolicy for every enabled component. When true each component gets a NetworkPolicy that allows ingress on its service ports from within the namespace and permits all egress. |
| global.nodeSelector | object | {} | Node selector applied to every pod by default. |
| global.objstore.config | string | `"type: GCS\nconfig:\n  bucket: change-me\n  endpoint: storage.googleapis.com\n  region: eu-west-1\n  insecure: false\n\n# Example for S3\n# type: S3\n# config:\n#   bucket: my-s3-bucket\n#   endpoint: s3.eu-west-1.amazonaws.com\n#   region: eu-west-1\n#   access_key: myaccess\n#   secret_key: mysecret\n"` | Inline object store configuration rendered into the Secret when `createSecret` is true. Processed via `tpl`, so Helm template syntax (e.g. `{{ .Release.Name }}`) is valid inside the string. Refer to https://thanos.io/tip/thanos/storage.md/ for the full schema. |
| global.objstore.createSecret | bool | `false` | When true, the chart creates a Kubernetes Secret named `secretName` containing the inline `config` below. Set to false when the Secret is managed externally (Vault, External Secrets Operator, kubectl, etc.). |
| global.objstore.secretKey | string | `"objstore.yml"` | Key inside the Secret whose value is the object store YAML. |
| global.objstore.secretName | string | `"thanos-objstore"` | Name of the Kubernetes Secret that carries the object store config. All components mount this Secret as a file. |
| global.pdb.enabled | bool | `false` | Enable a PodDisruptionBudget for every component. Individual components can override this with their own pdb.enabled. |
| global.pdb.maxUnavailable | int or string | `""` | Maximum number of unavailable pods during a disruption. Cannot be set at the same time as minAvailable. |
| global.pdb.minAvailable | int or string | `""` | Minimum number of available pods during a disruption. Cannot be set at the same time as maxUnavailable. |
| global.podAnnotations | object | {} | Annotations added to every pod by default. Component-level annotations are merged on top. |
| global.podSecurityContext | object | {} | Pod-level security context applied to every pod. Component-level values override this. |
| global.priorityClassName | string | `""` | Priority class name applied to every pod by default. |
| global.rbac.create | bool | `true` | Create RBAC resources (ClusterRole, ClusterRoleBinding) required by components that need cluster-level access (e.g. Ruler auto-import). |
| global.resources | object | {} | Default resource requests and limits. Override per component as needed. |
| global.serviceAccount.annotations | object | {} | Extra annotations merged into every ServiceAccount. |
| global.serviceAccount.create | bool | `true` | Create a dedicated ServiceAccount for each component. |
| global.serviceAccount.name | string | `""` | Name override for all ServiceAccounts. Empty means auto-generate per-component names based on the release name. |
| global.serviceMonitor.annotations | object | {} | Extra annotations merged into every ServiceMonitor resource. |
| global.serviceMonitor.enabled | bool | `false` | Enable a Prometheus Operator ServiceMonitor for every component. Individual components can override this with their own serviceMonitor.enabled. |
| global.serviceMonitor.interval | string | `""` | Scrape interval. Empty string uses the Prometheus operator default. |
| global.serviceMonitor.labels | object | {} | Extra labels merged into every ServiceMonitor resource. |
| global.serviceMonitor.metricRelabelings | list | [] | Metric relabeling rules applied after ingestion. |
| global.serviceMonitor.namespace | string | `""` | Namespace where ServiceMonitor resources are created. Empty means the same namespace as the release. |
| global.serviceMonitor.relabelings | list | [] | Relabeling rules applied to scraped metrics before ingestion. |
| global.serviceMonitor.scheme | string | `""` | Scrape scheme: http or https. |
| global.serviceMonitor.scrapeTimeout | string | `""` | Scrape timeout. Empty string uses the Prometheus operator default. |
| global.serviceMonitor.tlsConfig | object | {} | TLS configuration for scraping when scheme is https. |
| global.thanosRules.additionalRuleGroupAnnotations | object | {} | Annotations added to every alert rule across all groups. Applied on top of the rule's default annotations (summary, description, runbook_url). |
| global.thanosRules.additionalRuleGroupLabels | object | {} | Labels added to every alert rule across all groups. Applied on top of the rule's default labels (severity). Useful for routing alerts to specific Alertmanager receivers (e.g. team, tenant). |
| global.thanosRules.annotations | object | {} | Extra annotations merged into the PrometheusRule resource metadata. |
| global.thanosRules.enabled | bool | `true` | Deploy a PrometheusRule resource with built-in Thanos alerting rules. |
| global.thanosRules.groups.thanosBucketReplicate.annotations | object | {} | Extra annotations merged into every alert in this group. |
| global.thanosRules.groups.thanosBucketReplicate.enabled | bool | `false` | Render the thanos-bucket-replicate rule group. |
| global.thanosRules.groups.thanosBucketReplicate.jobPattern | string | `".*thanos.*bucket-replicate.*"` | Regex used to match the Prometheus `job` label of bucket-replicate scrape targets. |
| global.thanosRules.groups.thanosBucketReplicate.labels | object | {} | Extra labels merged into every alert in this group. |
| global.thanosRules.groups.thanosCompact.annotations | object | {} | Extra annotations merged into every alert in this group. |
| global.thanosRules.groups.thanosCompact.enabled | bool | `true` | Render the thanos-compact rule group. Also requires `compactor.enabled`. |
| global.thanosRules.groups.thanosCompact.jobPattern | string | `".*thanos.*compact.*"` | Regex used to match the Prometheus `job` label of compactor scrape targets. |
| global.thanosRules.groups.thanosCompact.labels | object | {} | Extra labels merged into every alert in this group. |
| global.thanosRules.groups.thanosComponentAbsent.annotations | object | {} | Extra annotations merged into every alert in this group. |
| global.thanosRules.groups.thanosComponentAbsent.enabled | bool | `true` | Render the thanos-component-absent rule group. |
| global.thanosRules.groups.thanosComponentAbsent.labels | object | {} | Extra labels merged into every alert in this group. |
| global.thanosRules.groups.thanosQuery.annotations | object | {} | Extra annotations merged into every alert in this group. |
| global.thanosRules.groups.thanosQuery.enabled | bool | `true` | Render the thanos-query rule group. Also requires `query.enabled`. |
| global.thanosRules.groups.thanosQuery.jobPattern | string | `".*thanos.*query.*"` | Regex used to match the Prometheus `job` label of query scrape targets. |
| global.thanosRules.groups.thanosQuery.labels | object | {} | Extra labels merged into every alert in this group. |
| global.thanosRules.groups.thanosReceive.annotations | object | {} | Extra annotations merged into every alert in this group. |
| global.thanosRules.groups.thanosReceive.enabled | bool | `true` | Render the thanos-receive rule group. Also requires `receive.enabled`. |
| global.thanosRules.groups.thanosReceive.jobPattern | string | `".*thanos.*receive.*"` | Regex used to match the Prometheus `job` label of receive scrape targets. |
| global.thanosRules.groups.thanosReceive.labels | object | {} | Extra labels merged into every alert in this group. |
| global.thanosRules.groups.thanosRule.annotations | object | {} | Extra annotations merged into every alert in this group. |
| global.thanosRules.groups.thanosRule.enabled | bool | `true` | Render the thanos-rule rule group. Also requires `ruler.enabled`. |
| global.thanosRules.groups.thanosRule.jobPattern | string | `".*thanos.*rule.*"` | Regex used to match the Prometheus `job` label of ruler scrape targets. |
| global.thanosRules.groups.thanosRule.labels | object | {} | Extra labels merged into every alert in this group. |
| global.thanosRules.groups.thanosSidecar.annotations | object | {} | Extra annotations merged into every alert in this group. |
| global.thanosRules.groups.thanosSidecar.enabled | bool | `false` | Render the thanos-sidecar rule group. |
| global.thanosRules.groups.thanosSidecar.jobPattern | string | `".*thanos.*sidecar.*"` | Regex used to match the Prometheus `job` label of sidecar scrape targets. |
| global.thanosRules.groups.thanosSidecar.labels | object | {} | Extra labels merged into every alert in this group. |
| global.thanosRules.groups.thanosStore.annotations | object | {} | Extra annotations merged into every alert in this group. |
| global.thanosRules.groups.thanosStore.enabled | bool | `true` | Render the thanos-store rule group. Also requires `storegateway.enabled`. |
| global.thanosRules.groups.thanosStore.jobPattern | string | `".*thanos.*store.*"` | Regex used to match the Prometheus `job` label of store gateway scrape targets. |
| global.thanosRules.groups.thanosStore.labels | object | {} | Extra labels merged into every alert in this group. |
| global.thanosRules.labels | object | {} | Extra labels merged into the PrometheusRule resource metadata. |
| global.thanosRules.severity.critical | string | `"critical"` | Severity label value used for critical alerts. |
| global.thanosRules.severity.info | string | `"info"` | Severity label value used for informational alerts. |
| global.thanosRules.severity.warning | string | `"warning"` | Severity label value used for warning alerts. |
| global.tolerations | list | [] | Toleration rules applied to every pod by default. |
| global.topologySpreadConstraints | list | [] | Topology spread constraints applied to every pod by default. |
| kube-prometheus-stack.enabled | bool | `false` | Enable the kube-prometheus-stack subchart. Deploys Prometheus Operator and associated components into the same namespace as Thanos. |
| query.affinity | object | {} | Affinity rules for Query pod scheduling. |
| query.annotations | object | {} | Extra annotations applied to Query resources. |
| query.autoscaling.enabled | bool | `false` | Enable HorizontalPodAutoscaler for the Query component. |
| query.autoscaling.maxReplicas | int | `5` | Maximum number of Query replicas. |
| query.autoscaling.minReplicas | int | `2` | Minimum number of Query replicas. |
| query.autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilisation percentage for Query autoscaling. |
| query.autoscaling.targetMemoryUtilizationPercentage | string | `nil` | Target memory utilisation percentage for Query autoscaling. Null disables memory-based scaling. |
| query.containerSecurityContext | object | {} | Container security context for Query. Overrides global.containerSecurityContext. |
| query.dnsConfig | object | {} | DNS configuration for Query pods. Overrides global.dnsConfig. |
| query.enabled | bool | `true` | Enable the Query Deployment. |
| query.endpoints.autogen.enabled | bool | `true` | Auto-generate endpoint arguments for the in-chart components (Receive, Store Gateway). These use the dnssrv+_grpc._tcp.<svc>.<namespace>.svc.<cluster-domain> format. |
| query.endpoints.static | list | [] | Optional static endpoint arguments. When non-empty will be added as extra endpoints. When `query.endpoints.autogen.enabled` is `false`, these will give you full control over the endpoints. |
| query.extraArgs[0] | string | `"--log.level=info"` |  |
| query.extraContainers | list | [] | Extra sidecar containers for Query pods. |
| query.extraEnv | list | [] | Extra environment variables injected into the Query container. |
| query.extraEnvFrom | list | [] | Extra environment variable sources for the Query container. |
| query.extraInitContainers | list | [] | Extra init containers for Query pods. |
| query.extraVolumeMounts | list | [] | Extra volume mounts for the Query container. |
| query.extraVolumes | list | [] | Extra volumes for Query pods. |
| query.grpcRoute.annotations | object | {} | Annotations for the Query GRPCRoute resource. |
| query.grpcRoute.enabled | bool | `false` | Enable a Gateway API GRPCRoute for the Query gRPC Store API endpoint. |
| query.grpcRoute.hostnames | list | [] | Hostnames to match on the Query GRPCRoute. |
| query.grpcRoute.parentRefs | list | [] | Gateway parentRefs for the Query GRPCRoute. |
| query.httpRoute.annotations | object | {} | Annotations for the Query HTTPRoute resource. |
| query.httpRoute.enabled | bool | `false` | Enable a Gateway API HTTPRoute for the Query HTTP endpoint. |
| query.httpRoute.hostnames | list | [] | Hostnames to match on the Query HTTPRoute. |
| query.httpRoute.parentRefs | list | [] | Gateway parentRefs for the Query HTTPRoute. |
| query.ingress.annotations | object | {} | Deprecated. Use `query.ingress.http.annotations` instead. |
| query.ingress.className | string | `""` | Deprecated. Use `query.ingress.http.className` instead. |
| query.ingress.enabled | bool | `false` | Deprecated. Use `query.ingress.http.enabled` instead. |
| query.ingress.grpc.annotations | object | {} | Extra annotations for the Query gRPC Ingress. |
| query.ingress.grpc.className | string | `""` | Ingress class name for Query gRPC endpoint (e.g. nginx, traefik). |
| query.ingress.grpc.enabled | bool | `false` | Enable a Kubernetes Ingress for the Query gRPC endpoint. Note this is independent of ingress.enabled that is for the HTTP ingress. |
| query.ingress.grpc.hosts[0].host | string | `"thanos-query-grpc.local"` |  |
| query.ingress.grpc.hosts[0].paths[0].path | string | `"/"` |  |
| query.ingress.grpc.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| query.ingress.grpc.tls | list | [] | TLS configuration for the Query gRPC Ingress. |
| query.ingress.hosts[0].host | string | `"thanos-query.local"` |  |
| query.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| query.ingress.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| query.ingress.http.annotations | object | {} | Extra annotations for the Query HTTP Ingress. |
| query.ingress.http.className | string | `""` | Ingress class name for Query HTTP endpoint (e.g. nginx, traefik). |
| query.ingress.http.enabled | bool | `false` | Enable a Kubernetes Ingress for the Query HTTP endpoint. |
| query.ingress.http.hosts[0].host | string | `"thanos-query.local"` |  |
| query.ingress.http.hosts[0].paths[0].path | string | `"/"` |  |
| query.ingress.http.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| query.ingress.http.tls | list | [] | TLS configuration for the Query HTTP Ingress. |
| query.ingress.tls | list | [] | Deprecated. Use `query.ingress.http.tls` instead. |
| query.labels | object | {} | Extra labels applied to Query resources. |
| query.nodeSelector | object | {} | Node selector for Query pod scheduling. |
| query.pdb.enabled | bool | `false` | Enable a PodDisruptionBudget for Query. |
| query.pdb.maxUnavailable | int or string | `""` | Maximum unavailable Query pods during a disruption. |
| query.pdb.minAvailable | int or string | `""` | Minimum available Query pods during a disruption. |
| query.podSecurityContext | object | {} | Pod security context for Query pods. Overrides global.podSecurityContext. |
| query.priorityClassName | string | `""` | Priority class name for Query pods. |
| query.probes.liveness.enabled | bool | `true` | Enable the liveness probe for Query. |
| query.probes.liveness.failureThreshold | int | `6` | Consecutive failures before the Query container is restarted. |
| query.probes.liveness.initialDelaySeconds | int | `30` | Seconds to wait before starting the Query liveness probe. |
| query.probes.liveness.path | string | `"/-/healthy"` | HTTP path checked by the Query liveness probe. |
| query.probes.liveness.periodSeconds | int | `10` | How often (seconds) to run the Query liveness probe. |
| query.probes.liveness.successThreshold | int | `1` | Consecutive successes before the Query container is considered live. |
| query.probes.liveness.timeoutSeconds | int | `5` | Seconds after which the Query liveness probe times out. |
| query.probes.readiness.enabled | bool | `true` | Enable the readiness probe for Query. |
| query.probes.readiness.failureThreshold | int | `6` | Consecutive failures before the Query pod is marked not-ready. |
| query.probes.readiness.initialDelaySeconds | int | `5` | Seconds to wait before starting the Query readiness probe. |
| query.probes.readiness.path | string | `"/-/ready"` | HTTP path checked by the Query readiness probe. |
| query.probes.readiness.periodSeconds | int | `10` | How often (seconds) to run the Query readiness probe. |
| query.probes.readiness.successThreshold | int | `1` | Consecutive successes before the Query pod is marked ready. |
| query.probes.readiness.timeoutSeconds | int | `5` | Seconds after which the Query readiness probe times out. |
| query.probes.startup.enabled | bool | `true` | Enable the startup probe for Query. |
| query.probes.startup.failureThreshold | int | `60` | Consecutive failures during Query startup before the container is killed. |
| query.probes.startup.initialDelaySeconds | int | `0` | Seconds to wait before starting the Query startup probe. |
| query.probes.startup.path | string | `"/-/ready"` | HTTP path checked by the Query startup probe. |
| query.probes.startup.periodSeconds | int | `5` | How often (seconds) to run the Query startup probe. |
| query.probes.startup.successThreshold | int | `1` | Consecutive successes before the Query startup probe is considered passed. |
| query.probes.startup.timeoutSeconds | int | `5` | Seconds after which the Query startup probe times out. |
| query.replicaCount | int | `2` | Number of Query pod replicas. Two or more is recommended for HA. |
| query.replicaLabels[0] | string | `"prometheus_replica"` |  |
| query.replicaLabels[1] | string | `"receive_replica"` |  |
| query.resources | object | {} | Resource requests and limits for the Query container. |
| query.service.annotations | object | {} | Extra annotations for the Query Service. |
| query.service.grpcPort | int | `10901` | gRPC Store API port exposed by the Query Service. |
| query.service.httpPort | int | `9090` | HTTP/PromQL port exposed by the Query Service. |
| query.service.labels | object | {} | Extra labels for the Query Service. |
| query.service.type | string | `"ClusterIP"` | Kubernetes Service type for the Query component. |
| query.serviceMonitor.annotations | object | {} | Extra annotations for the Query ServiceMonitor. |
| query.serviceMonitor.enabled | bool | `false` | Enable a Prometheus Operator ServiceMonitor for Query. |
| query.serviceMonitor.interval | string | `""` | Scrape interval for Query. Empty uses the Prometheus operator default. |
| query.serviceMonitor.labels | object | {} | Extra labels for the Query ServiceMonitor. |
| query.serviceMonitor.metricRelabelings | list | [] | Metric relabeling rules applied after Query metrics are ingested. |
| query.serviceMonitor.relabelings | list | [] | Relabeling rules applied before Query metrics are ingested. |
| query.serviceMonitor.scheme | string | `""` | Scrape scheme for Query (http or https). |
| query.serviceMonitor.scrapeTimeout | string | `""` | Scrape timeout for Query. Empty uses the Prometheus operator default. |
| query.serviceMonitor.tlsConfig | object | {} | TLS configuration for Query scraping. |
| query.stores | list | [] | Deprecated. Use `query.endpoints.static[]` instead. |
| query.tolerations | list | [] | Tolerations for Query pod scheduling. |
| query.topologySpreadConstraints | list | [] | Topology spread constraints for Query pods. |
| queryFrontend.affinity | object | {} | Affinity rules for Query Frontend pod scheduling. |
| queryFrontend.annotations | object | {} | Extra annotations applied to Query Frontend resources. |
| queryFrontend.autoscaling.enabled | bool | `false` | Enable HorizontalPodAutoscaler for Query Frontend. |
| queryFrontend.autoscaling.maxReplicas | int | `5` | Maximum number of Query Frontend replicas. |
| queryFrontend.autoscaling.minReplicas | int | `2` | Minimum number of Query Frontend replicas. |
| queryFrontend.autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilisation percentage for Query Frontend autoscaling. |
| queryFrontend.autoscaling.targetMemoryUtilizationPercentage | string | `nil` | Target memory utilisation percentage for Query Frontend autoscaling. Null disables memory-based scaling. |
| queryFrontend.cacheConfig | string | `""` | Optional result cache configuration (Memcached, Redis, or in-memory) passed as an inline YAML string. See https://thanos.io/tip/components/query-frontend.md/ |
| queryFrontend.containerSecurityContext | object | {} | Container security context for Query Frontend. Overrides global.containerSecurityContext. |
| queryFrontend.dnsConfig | object | {} | DNS configuration for Query Frontend pods. Overrides global.dnsConfig. |
| queryFrontend.downstreamUrl | string | `""` | Downstream URL of the Query component. Leave empty to use the in-chart Query service endpoint (auto-resolved). |
| queryFrontend.enabled | bool | `false` | Enable the Query Frontend Deployment. |
| queryFrontend.extraArgs | list | [] | Additional CLI arguments appended to the `thanos query-frontend` command. |
| queryFrontend.extraContainers | list | [] | Extra sidecar containers for Query Frontend pods. |
| queryFrontend.extraEnv | list | [] | Extra environment variables injected into the Query Frontend container. |
| queryFrontend.extraEnvFrom | list | [] | Extra environment variable sources for the Query Frontend container. |
| queryFrontend.extraInitContainers | list | [] | Extra init containers for Query Frontend pods. |
| queryFrontend.extraVolumeMounts | list | [] | Extra volume mounts for the Query Frontend container. |
| queryFrontend.extraVolumes | list | [] | Extra volumes for Query Frontend pods. |
| queryFrontend.httpRoute.annotations | object | {} | Annotations for the Query Frontend HTTPRoute resource. |
| queryFrontend.httpRoute.enabled | bool | `false` | Enable a Gateway API HTTPRoute for Query Frontend. |
| queryFrontend.httpRoute.hostnames | list | [] | Hostnames to match on the Query Frontend HTTPRoute. |
| queryFrontend.httpRoute.parentRefs | list | [] | Gateway parentRefs for the Query Frontend HTTPRoute. |
| queryFrontend.ingress.annotations | object | {} | Extra annotations for the Query Frontend Ingress. |
| queryFrontend.ingress.className | string | `""` | Ingress class name for Query Frontend (e.g. nginx, traefik). |
| queryFrontend.ingress.enabled | bool | `false` | Enable a Kubernetes Ingress for Query Frontend. |
| queryFrontend.ingress.hosts[0].host | string | `"thanos-query-frontend.local"` |  |
| queryFrontend.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| queryFrontend.ingress.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| queryFrontend.ingress.tls | list | [] | TLS configuration for the Query Frontend Ingress. |
| queryFrontend.labels | object | {} | Extra labels applied to Query Frontend resources. |
| queryFrontend.nodeSelector | object | {} | Node selector for Query Frontend pod scheduling. |
| queryFrontend.pdb.enabled | bool | `false` | Enable a PodDisruptionBudget for Query Frontend. |
| queryFrontend.pdb.maxUnavailable | int or string | `""` | Maximum unavailable Query Frontend pods during a disruption. |
| queryFrontend.pdb.minAvailable | int or string | `""` | Minimum available Query Frontend pods during a disruption. |
| queryFrontend.podSecurityContext | object | {} | Pod security context for Query Frontend pods. Overrides global.podSecurityContext. |
| queryFrontend.priorityClassName | string | `""` | Priority class name for Query Frontend pods. |
| queryFrontend.probes.liveness.enabled | bool | `true` | Enable the liveness probe for Query Frontend. |
| queryFrontend.probes.liveness.failureThreshold | int | `6` | Consecutive failures before the Query Frontend container is restarted. |
| queryFrontend.probes.liveness.initialDelaySeconds | int | `30` | Seconds to wait before starting the Query Frontend liveness probe. |
| queryFrontend.probes.liveness.path | string | `"/-/healthy"` | HTTP path checked by the Query Frontend liveness probe. |
| queryFrontend.probes.liveness.periodSeconds | int | `10` | How often (seconds) to run the Query Frontend liveness probe. |
| queryFrontend.probes.liveness.successThreshold | int | `1` | Consecutive successes before the Query Frontend container is considered live. |
| queryFrontend.probes.liveness.timeoutSeconds | int | `5` | Seconds after which the Query Frontend liveness probe times out. |
| queryFrontend.probes.readiness.enabled | bool | `true` | Enable the readiness probe for Query Frontend. |
| queryFrontend.probes.readiness.failureThreshold | int | `6` | Consecutive failures before the Query Frontend pod is marked not-ready. |
| queryFrontend.probes.readiness.initialDelaySeconds | int | `5` | Seconds to wait before starting the Query Frontend readiness probe. |
| queryFrontend.probes.readiness.path | string | `"/-/ready"` | HTTP path checked by the Query Frontend readiness probe. |
| queryFrontend.probes.readiness.periodSeconds | int | `10` | How often (seconds) to run the Query Frontend readiness probe. |
| queryFrontend.probes.readiness.successThreshold | int | `1` | Consecutive successes before the Query Frontend pod is marked ready. |
| queryFrontend.probes.readiness.timeoutSeconds | int | `5` | Seconds after which the Query Frontend readiness probe times out. |
| queryFrontend.probes.startup.enabled | bool | `true` | Enable the startup probe for Query Frontend. |
| queryFrontend.probes.startup.failureThreshold | int | `60` | Consecutive failures during Query Frontend startup before the container is killed. |
| queryFrontend.probes.startup.initialDelaySeconds | int | `0` | Seconds to wait before starting the Query Frontend startup probe. |
| queryFrontend.probes.startup.path | string | `"/-/ready"` | HTTP path checked by the Query Frontend startup probe. |
| queryFrontend.probes.startup.periodSeconds | int | `5` | How often (seconds) to run the Query Frontend startup probe. |
| queryFrontend.probes.startup.successThreshold | int | `1` | Consecutive successes before the Query Frontend startup probe is considered passed. |
| queryFrontend.probes.startup.timeoutSeconds | int | `5` | Seconds after which the Query Frontend startup probe times out. |
| queryFrontend.replicaCount | int | `2` | Number of Query Frontend pod replicas. |
| queryFrontend.resources | object | {} | Resource requests and limits for the Query Frontend container. |
| queryFrontend.service.annotations | object | {} | Extra annotations for the Query Frontend Service. |
| queryFrontend.service.labels | object | {} | Extra labels for the Query Frontend Service. |
| queryFrontend.service.port | int | `9090` | HTTP port exposed by the Query Frontend Service. |
| queryFrontend.service.type | string | `"ClusterIP"` | Kubernetes Service type for Query Frontend. |
| queryFrontend.serviceMonitor.annotations | object | {} | Extra annotations for the Query Frontend ServiceMonitor. |
| queryFrontend.serviceMonitor.enabled | bool | `false` | Enable a Prometheus Operator ServiceMonitor for Query Frontend. |
| queryFrontend.serviceMonitor.interval | string | `""` | Scrape interval for Query Frontend. Empty uses the Prometheus operator default. |
| queryFrontend.serviceMonitor.labels | object | {} | Extra labels for the Query Frontend ServiceMonitor. |
| queryFrontend.serviceMonitor.metricRelabelings | list | [] | Metric relabeling rules applied after Query Frontend metrics are ingested. |
| queryFrontend.serviceMonitor.relabelings | list | [] | Relabeling rules applied before Query Frontend metrics are ingested. |
| queryFrontend.serviceMonitor.scheme | string | `""` | Scrape scheme for Query Frontend (http or https). |
| queryFrontend.serviceMonitor.scrapeTimeout | string | `""` | Scrape timeout for Query Frontend. Empty uses the Prometheus operator default. |
| queryFrontend.serviceMonitor.tlsConfig | object | {} | TLS configuration for Query Frontend scraping. |
| queryFrontend.tolerations | list | [] | Tolerations for Query Frontend pod scheduling. |
| queryFrontend.topologySpreadConstraints | list | [] | Topology spread constraints for Query Frontend pods. |
| receive.affinity | object | {} | Affinity rules for Receive pod scheduling. |
| receive.annotations | object | {} | Extra annotations applied to Receive resources. |
| receive.containerSecurityContext | object | {} | Container security context for Receive. Overrides global.containerSecurityContext. |
| receive.dnsConfig | object | {} | DNS configuration for Receive pods. Overrides global.dnsConfig. |
| receive.enabled | bool | `true` | Enable the Receive StatefulSet. |
| receive.extraArgs | list | [] | Additional CLI arguments appended to the `thanos receive` command. |
| receive.extraContainers | list | [] | Extra sidecar containers for Receive pods. |
| receive.extraEnv | list | [] | Extra environment variables injected into the Receive container. |
| receive.extraEnvFrom | list | [] | Extra environment variable sources for the Receive container. |
| receive.extraInitContainers | list | [] | Extra init containers for Receive pods. |
| receive.extraVolumeMounts | list | [] | Extra volume mounts for the Receive container. |
| receive.extraVolumes | list | [] | Extra volumes for Receive pods. |
| receive.grpcRoute.annotations | object | {} | Annotations for the Receive GRPCRoute resource. |
| receive.grpcRoute.enabled | bool | `false` | Enable a Gateway API GRPCRoute for the Receive gRPC Store API endpoint. |
| receive.grpcRoute.hostnames | list | [] | Hostnames to match on the Receive GRPCRoute. |
| receive.grpcRoute.parentRefs | list | [] | Gateway parentRefs for the Receive GRPCRoute. |
| receive.hashrings.autogen.enabled | bool | `true` | Auto-generate a single default hashring whose endpoints are derived from the StatefulSet pod DNS names: `<pod-0>.<headless-svc>:10901 ... <pod-N>.<headless-svc>:10901`. |
| receive.hashrings.autogen.name | string | `"default"` | Name of the auto-generated hashring. |
| receive.hashrings.static | list | [] | Optional static hashring configuration. When non-empty this overrides `autogen` and gives full control over ring topology. |
| receive.httpRoute.annotations | object | {} | Annotations for the Receive HTTPRoute resource. |
| receive.httpRoute.enabled | bool | `false` | Enable a Gateway API HTTPRoute for the Receive HTTP endpoint. |
| receive.httpRoute.hostnames | list | [] | Hostnames to match on the Receive HTTPRoute. |
| receive.httpRoute.parentRefs | list | [] | Gateway parentRefs for the Receive HTTPRoute. |
| receive.ingress.annotations | object | {} | Deprecated. Use `receive.ingress.http.annotations` instead. |
| receive.ingress.className | string | `""` | Deprecated. Use `receive.ingress.http.className` instead. |
| receive.ingress.enabled | bool | `false` | Deprecated. Use `receive.ingress.http.enabled` instead. |
| receive.ingress.grpc.annotations | object | {} | Extra annotations for the Receive gRPC Ingress. |
| receive.ingress.grpc.className | string | `""` | Ingress class name for Receive gRPC endpoint (e.g. nginx, traefik). |
| receive.ingress.grpc.enabled | bool | `false` | Enable a Kubernetes Ingress for the Receive gRPC endpoint. Note this is independent of ingress.enabled that is for the HTTP ingress. |
| receive.ingress.grpc.hosts[0].host | string | `"thanos-receive-grpc.local"` |  |
| receive.ingress.grpc.hosts[0].paths[0].path | string | `"/"` |  |
| receive.ingress.grpc.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| receive.ingress.grpc.tls | list | [] | TLS configuration for the Receive gRPC Ingress. |
| receive.ingress.hosts[0].host | string | `"thanos-receive.local"` |  |
| receive.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| receive.ingress.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| receive.ingress.http.annotations | object | {} | Extra annotations for the Receive HTTP Ingress. |
| receive.ingress.http.className | string | `""` | Ingress class name for Receive HTTP endpoint (e.g. nginx, traefik). |
| receive.ingress.http.enabled | bool | `false` | Enable a Kubernetes Ingress for the Receive HTTP endpoint. |
| receive.ingress.http.hosts[0].host | string | `"thanos-receive.local"` |  |
| receive.ingress.http.hosts[0].paths[0].path | string | `"/"` |  |
| receive.ingress.http.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| receive.ingress.http.tls | list | [] | TLS configuration for the Receive HTTP Ingress. |
| receive.ingress.tls | list | [] | Deprecated. Use `receive.ingress.http.tls` instead. |
| receive.labels | object | {} | Extra labels applied to Receive resources. |
| receive.nodeSelector | object | {} | Node selector for Receive pod scheduling. |
| receive.pdb.enabled | bool | `false` | Enable a PodDisruptionBudget for Receive. |
| receive.pdb.maxUnavailable | int or string | `""` | Maximum unavailable Receive pods during a disruption. |
| receive.pdb.minAvailable | int or string | `""` | Minimum available Receive pods during a disruption. |
| receive.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| receive.persistence.enabled | bool | `true` | Enable a PersistentVolumeClaim for the Receive TSDB WAL. |
| receive.persistence.size | string | `"10Gi"` | Storage capacity for the Receive PVC. Should be sized to hold at least `tsdb.retention` worth of data. |
| receive.persistence.storageClass | string | `""` | StorageClass name for the Receive PVC. Empty uses the cluster default. |
| receive.podSecurityContext.fsGroup | int | `1000` |  |
| receive.podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| receive.priorityClassName | string | `""` | Priority class name for Receive pods. |
| receive.probes.liveness.enabled | bool | `true` | Enable the liveness probe for Receive. |
| receive.probes.liveness.failureThreshold | int | `6` | Consecutive failures before the Receive container is restarted. |
| receive.probes.liveness.initialDelaySeconds | int | `30` | Seconds to wait before starting the Receive liveness probe. |
| receive.probes.liveness.path | string | `"/-/healthy"` | HTTP path checked by the Receive liveness probe. |
| receive.probes.liveness.periodSeconds | int | `10` | How often (seconds) to run the Receive liveness probe. |
| receive.probes.liveness.successThreshold | int | `1` | Consecutive successes before the Receive container is considered live. |
| receive.probes.liveness.timeoutSeconds | int | `5` | Seconds after which the Receive liveness probe times out. |
| receive.probes.readiness.enabled | bool | `true` | Enable the readiness probe for Receive. |
| receive.probes.readiness.failureThreshold | int | `6` | Consecutive failures before the Receive pod is marked not-ready. |
| receive.probes.readiness.initialDelaySeconds | int | `5` | Seconds to wait before starting the Receive readiness probe. |
| receive.probes.readiness.path | string | `"/-/ready"` | HTTP path checked by the Receive readiness probe. |
| receive.probes.readiness.periodSeconds | int | `10` | How often (seconds) to run the Receive readiness probe. |
| receive.probes.readiness.successThreshold | int | `1` | Consecutive successes before the Receive pod is marked ready. |
| receive.probes.readiness.timeoutSeconds | int | `5` | Seconds after which the Receive readiness probe times out. |
| receive.probes.startup.enabled | bool | `true` | Enable the startup probe for Receive. |
| receive.probes.startup.failureThreshold | int | `60` | Consecutive failures during Receive startup before the container is killed. |
| receive.probes.startup.initialDelaySeconds | int | `0` | Seconds to wait before starting the Receive startup probe. |
| receive.probes.startup.path | string | `"/-/ready"` | HTTP path checked by the Receive startup probe. |
| receive.probes.startup.periodSeconds | int | `5` | How often (seconds) to run the Receive startup probe. |
| receive.probes.startup.successThreshold | int | `1` | Consecutive successes before the Receive startup probe is considered passed. |
| receive.probes.startup.timeoutSeconds | int | `5` | Seconds after which the Receive startup probe times out. |
| receive.replicaCount | int | `3` | Number of Receive pod replicas. Minimum 3 is recommended for replication factor 2 (write quorum = floor(replicaCount/2)+1). |
| receive.resources | object | {} | Resource requests and limits for the Receive container. |
| receive.service.annotations | object | {} | Extra annotations for the Receive Service. |
| receive.service.grpcPort | int | `10901` | gRPC Store API port exposed by the Receive Service. |
| receive.service.httpPort | int | `10902` | HTTP port exposed by the Receive Service. |
| receive.service.labels | object | {} | Extra labels for the Receive Service. |
| receive.service.remoteWritePort | int | `10908` | Remote-write ingestion port exposed by the Receive Service. |
| receive.service.type | string | `"ClusterIP"` | Kubernetes Service type for the Receive component. |
| receive.serviceMonitor.annotations | object | {} | Extra annotations for the Receive ServiceMonitor. |
| receive.serviceMonitor.enabled | bool | `false` | Enable a Prometheus Operator ServiceMonitor for Receive. |
| receive.serviceMonitor.interval | string | `""` | Scrape interval for Receive. Empty uses the Prometheus operator default. |
| receive.serviceMonitor.labels | object | {} | Extra labels for the Receive ServiceMonitor. |
| receive.serviceMonitor.metricRelabelings | list | [] | Metric relabeling rules applied after Receive metrics are ingested. |
| receive.serviceMonitor.relabelings | list | [] | Relabeling rules applied before Receive metrics are ingested. |
| receive.serviceMonitor.scheme | string | `""` | Scrape scheme for Receive (http or https). |
| receive.serviceMonitor.scrapeTimeout | string | `""` | Scrape timeout for Receive. Empty uses the Prometheus operator default. |
| receive.serviceMonitor.tlsConfig | object | {} | TLS configuration for Receive scraping. |
| receive.tenancyHeader | string | `""` | Optional HTTP header name used to segregate tenants in multi-tenant setups. When set, Receive routes write requests to the correct tenant shard based on this header. |
| receive.tolerations | list | [] | Tolerations for Receive pod scheduling. |
| receive.topologySpreadConstraints | list | [] | Topology spread constraints for Receive pods. |
| receive.tsdb.retention | string | `"24h"` | How long Receive keeps data in the local WAL before uploading to the object store. |
| receive.tsdb.walCompression | bool | `true` | Enable WAL compression to reduce disk I/O and storage usage. |
| receive.vpa.enabled | bool | `true` | Enable a VerticalPodAutoscaler for the Receive StatefulSet. |
| receive.vpa.maxAllowed.cpu | string | `"4"` | Maximum CPU resource enforced by the Receive VPA. |
| receive.vpa.maxAllowed.memory | string | `"8Gi"` | Maximum memory resource enforced by the Receive VPA. |
| receive.vpa.minAllowed.cpu | string | `"500m"` | Minimum CPU resource enforced by the Receive VPA. |
| receive.vpa.minAllowed.memory | string | `"512Mi"` | Minimum memory resource enforced by the Receive VPA. |
| receive.vpa.targetKind | string | `"StatefulSet"` | Kubernetes workload kind targeted by the Receive VPA. |
| receive.vpa.updateMode | string | `"Auto"` | VPA update mode for Receive. One of Auto, Off, or Initial. |
| ruler.affinity | object | {} | Affinity rules for Ruler pod scheduling. |
| ruler.alertQueryUrl | string | `""` | URL used in rule alert annotations to link back to a Thanos query UI. |
| ruler.alertmanagers.config | string | `"alertmanagers:\n  - static_configs:\n      - alertmanager.monitoring.svc.cluster.local:9093\n    scheme: http\n    api_version: v2\n"` |  |
| ruler.annotations | object | {} | Extra annotations applied to Ruler resources. |
| ruler.autoImportPrometheusRules.enabled | bool | `true` | Enable automatic import of PrometheusRule CRDs from the cluster into the Ruler. Requires kube-prometheus-stack (or any Prometheus Operator deployment) to be present in the cluster. |
| ruler.autoImportPrometheusRules.labelSelector | object | {} | Label selector used to filter which PrometheusRule CRDs are imported. Empty selector imports all PrometheusRule resources visible to the sidecar. |
| ruler.autoImportPrometheusRules.sidecar.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy for the kubectl sidecar. |
| ruler.autoImportPrometheusRules.sidecar.image.repository | string | `"alpine/kubectl"` | Repository for the kubectl sidecar that reads PrometheusRule CRDs. |
| ruler.autoImportPrometheusRules.sidecar.image.tag | string | `"latest"` | Tag for the kubectl sidecar image. |
| ruler.containerSecurityContext | object | {} | Container security context for Ruler. Overrides global.containerSecurityContext. |
| ruler.dnsConfig | object | {} | DNS configuration for Ruler pods. Overrides global.dnsConfig. |
| ruler.enabled | bool | `false` | Enable the Ruler StatefulSet. |
| ruler.extraArgs | list | [] | Additional CLI arguments appended to the `thanos rule` command. |
| ruler.extraContainers | list | [] | Extra sidecar containers for Ruler pods. |
| ruler.extraEnv | list | [] | Extra environment variables injected into the Ruler container. |
| ruler.extraEnvFrom | list | [] | Extra environment variable sources for the Ruler container. |
| ruler.extraInitContainers | list | [] | Extra init containers for Ruler pods. |
| ruler.extraVolumeMounts | list | [] | Extra volume mounts for the Ruler container. |
| ruler.extraVolumes | list | [] | Extra volumes for Ruler pods. |
| ruler.httpRoute.annotations | object | {} | Annotations for the Ruler HTTPRoute resource. |
| ruler.httpRoute.enabled | bool | `false` | Enable a Gateway API HTTPRoute for the Ruler HTTP endpoint. |
| ruler.httpRoute.hostnames | list | [] | Hostnames to match on the Ruler HTTPRoute. |
| ruler.httpRoute.parentRefs | list | [] | Gateway parentRefs for the Ruler HTTPRoute. |
| ruler.ingress.annotations | object | {} | Extra annotations for the Ruler Ingress. |
| ruler.ingress.className | string | `""` | Ingress class name for Ruler (e.g. nginx, traefik). |
| ruler.ingress.enabled | bool | `false` | Enable a Kubernetes Ingress for the Ruler HTTP endpoint. |
| ruler.ingress.hosts[0].host | string | `"thanos-ruler.local"` |  |
| ruler.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ruler.ingress.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| ruler.ingress.tls | list | [] | TLS configuration for the Ruler Ingress. |
| ruler.labels | object | {} | Extra labels applied to Ruler resources. |
| ruler.nodeSelector | object | {} | Node selector for Ruler pod scheduling. |
| ruler.pdb.enabled | bool | `false` | Enable a PodDisruptionBudget for the Ruler. |
| ruler.pdb.maxUnavailable | int or string | `""` | Maximum unavailable Ruler pods during a disruption. |
| ruler.pdb.minAvailable | int or string | `""` | Minimum available Ruler pods during a disruption. |
| ruler.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| ruler.persistence.enabled | bool | `true` | Enable a PersistentVolumeClaim for the Ruler data directory. |
| ruler.persistence.size | string | `"10Gi"` | Storage capacity for the Ruler PVC. |
| ruler.persistence.storageClass | string | `""` | StorageClass name for the Ruler PVC. Empty uses the cluster default. |
| ruler.podSecurityContext.fsGroup | int | `1000` |  |
| ruler.podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| ruler.priorityClassName | string | `""` | Priority class name for Ruler pods. |
| ruler.probes.liveness.enabled | bool | `true` | Enable the liveness probe for the Ruler. |
| ruler.probes.liveness.failureThreshold | int | `6` | Consecutive failures before the Ruler container is restarted. |
| ruler.probes.liveness.initialDelaySeconds | int | `30` | Seconds to wait before starting the Ruler liveness probe. |
| ruler.probes.liveness.path | string | `"/-/healthy"` | HTTP path checked by the Ruler liveness probe. |
| ruler.probes.liveness.periodSeconds | int | `10` | How often (seconds) to run the Ruler liveness probe. |
| ruler.probes.liveness.successThreshold | int | `1` | Consecutive successes before the Ruler container is considered live. |
| ruler.probes.liveness.timeoutSeconds | int | `5` | Seconds after which the Ruler liveness probe times out. |
| ruler.probes.readiness.enabled | bool | `true` | Enable the readiness probe for the Ruler. |
| ruler.probes.readiness.failureThreshold | int | `6` | Consecutive failures before the Ruler pod is marked not-ready. |
| ruler.probes.readiness.initialDelaySeconds | int | `5` | Seconds to wait before starting the Ruler readiness probe. |
| ruler.probes.readiness.path | string | `"/-/ready"` | HTTP path checked by the Ruler readiness probe. |
| ruler.probes.readiness.periodSeconds | int | `10` | How often (seconds) to run the Ruler readiness probe. |
| ruler.probes.readiness.successThreshold | int | `1` | Consecutive successes before the Ruler pod is marked ready. |
| ruler.probes.readiness.timeoutSeconds | int | `5` | Seconds after which the Ruler readiness probe times out. |
| ruler.probes.startup.enabled | bool | `true` | Enable the startup probe for the Ruler. |
| ruler.probes.startup.failureThreshold | int | `60` | Consecutive failures during Ruler startup before the container is killed. |
| ruler.probes.startup.initialDelaySeconds | int | `0` | Seconds to wait before starting the Ruler startup probe. |
| ruler.probes.startup.path | string | `"/-/ready"` | HTTP path checked by the Ruler startup probe. |
| ruler.probes.startup.periodSeconds | int | `5` | How often (seconds) to run the Ruler startup probe. |
| ruler.probes.startup.successThreshold | int | `1` | Consecutive successes before the Ruler startup probe is considered passed. |
| ruler.probes.startup.timeoutSeconds | int | `5` | Seconds after which the Ruler startup probe times out. |
| ruler.query.urls | list | [] | List of Query component base URLs used by the Ruler to evaluate rules. |
| ruler.replicaCount | int | `2` | Number of Ruler pod replicas. Multiple replicas require consistent rule distribution to avoid duplicate alerts. |
| ruler.resources | object | {} | Resource requests and limits for the Ruler container. |
| ruler.rules."example-alerts.yaml" | string | `"groups:\n  - name: thanos-example\n    rules:\n      - alert: ExampleAlwaysFiring\n        expr: vector(1)\n        for: 1m\n        labels:\n          severity: warning\n        annotations:\n          summary: Example alert firing\n"` |  |
| ruler.service.annotations | object | {} | Extra annotations for the Ruler Service. |
| ruler.service.grpcPort | int | `10901` | gRPC Store API port exposed by the Ruler headless Service. |
| ruler.service.httpPort | int | `10902` | HTTP port exposed by the Ruler Service. |
| ruler.service.labels | object | {} | Extra labels for the Ruler Service. |
| ruler.service.type | string | `"ClusterIP"` | Kubernetes Service type for the Ruler component. |
| ruler.serviceMonitor.annotations | object | {} | Extra annotations for the Ruler ServiceMonitor. |
| ruler.serviceMonitor.enabled | bool | `false` | Enable a Prometheus Operator ServiceMonitor for the Ruler. |
| ruler.serviceMonitor.interval | string | `""` | Scrape interval for the Ruler. Empty uses the Prometheus operator default. |
| ruler.serviceMonitor.labels | object | {} | Extra labels for the Ruler ServiceMonitor. |
| ruler.serviceMonitor.metricRelabelings | list | [] | Metric relabeling rules applied after Ruler metrics are ingested. |
| ruler.serviceMonitor.relabelings | list | [] | Relabeling rules applied before Ruler metrics are ingested. |
| ruler.serviceMonitor.scheme | string | `""` | Scrape scheme for the Ruler (http or https). |
| ruler.serviceMonitor.scrapeTimeout | string | `""` | Scrape timeout for the Ruler. Empty uses the Prometheus operator default. |
| ruler.serviceMonitor.tlsConfig | object | {} | TLS configuration for Ruler scraping. |
| ruler.tolerations | list | [] | Tolerations for Ruler pod scheduling. |
| ruler.topologySpreadConstraints | list | [] | Topology spread constraints for Ruler pods. |
| rustfs.enabled | bool | `false` | Deploy a local RustFS instance as an S3-compatible object store alongside Thanos. Intended for CI and development only. Do not enable in production. |
| rustfs.initBucket.accessKey | string | `"rustfsadmin"` | RustFS admin username. Ignored when existingSecret is set. |
| rustfs.initBucket.bucketName | string | `"thanos"` | S3 bucket name to create. |
| rustfs.initBucket.existingSecret | string | `""` | Name of an existing Secret containing the RustFS credentials. When set, accessKey and secretKey are ignored. The Secret must contain the keys defined in existingSecretKeys. |
| rustfs.initBucket.existingSecretKeys.accessKey | string | `"access-key"` | Key in the existing Secret for the access key. |
| rustfs.initBucket.existingSecretKeys.secretKey | string | `"secret-key"` | Key in the existing Secret for the secret key. |
| rustfs.initBucket.image | string | `"rustfs/rc:latest"` | Image used by the init-bucket Job to create the S3 bucket via the RustFS CLI. |
| rustfs.initBucket.secretKey | string | `"rustfsadmin"` | RustFS admin password. Ignored when existingSecret is set. |
| storegateway.affinity | object | {} | Affinity rules for Store Gateway pod scheduling. |
| storegateway.annotations | object | {} | Extra annotations applied to Store Gateway resources. |
| storegateway.autoscaling.enabled | bool | `false` | Enable HorizontalPodAutoscaler for the Store Gateway. |
| storegateway.autoscaling.maxReplicas | int | `6` | Maximum number of Store Gateway replicas. |
| storegateway.autoscaling.minReplicas | int | `2` | Minimum number of Store Gateway replicas. |
| storegateway.autoscaling.targetCPUUtilizationPercentage | int | `80` | Target CPU utilisation percentage for Store Gateway autoscaling. |
| storegateway.autoscaling.targetMemoryUtilizationPercentage | string | `nil` | Target memory utilisation percentage for Store Gateway autoscaling. Null disables memory-based scaling. |
| storegateway.cachingBucketConfig | string | `""` | Optional caching bucket configuration (e.g. Memcached) that wraps the object store to reduce the number of object store API calls. Provide as an inline YAML string. See https://thanos.io/tip/components/store.md/#caching-bucket |
| storegateway.containerSecurityContext | object | {} | Container security context for Store Gateway. Overrides global.containerSecurityContext. |
| storegateway.dnsConfig | object | {} | DNS configuration for Store Gateway pods. Overrides global.dnsConfig. |
| storegateway.enabled | bool | `true` | Enable the Store Gateway StatefulSet. |
| storegateway.extraArgs | list | [] | Additional CLI arguments appended to the `thanos store` command. |
| storegateway.extraContainers | list | [] | Extra sidecar containers for Store Gateway pods. |
| storegateway.extraEnv | list | [] | Extra environment variables injected into the Store Gateway container. |
| storegateway.extraEnvFrom | list | [] | Extra environment variable sources for the Store Gateway container. |
| storegateway.extraInitContainers | list | [] | Extra init containers for Store Gateway pods. |
| storegateway.extraVolumeMounts | list | [] | Extra volume mounts for the Store Gateway container. |
| storegateway.extraVolumes | list | [] | Extra volumes for Store Gateway pods. |
| storegateway.grpcRoute.annotations | object | {} | Annotations for the Store Gateway GRPCRoute resource. |
| storegateway.grpcRoute.enabled | bool | `false` | Enable a Gateway API GRPCRoute for the Store Gateway gRPC Store API endpoint. |
| storegateway.grpcRoute.hostnames | list | [] | Hostnames to match on the Store Gateway GRPCRoute. |
| storegateway.grpcRoute.parentRefs | list | [] | Gateway parentRefs for the Store Gateway GRPCRoute. |
| storegateway.httpRoute.annotations | object | {} | Annotations for the Store Gateway HTTPRoute resource. |
| storegateway.httpRoute.enabled | bool | `false` | Enable a Gateway API HTTPRoute for the Store Gateway HTTP endpoint. |
| storegateway.httpRoute.hostnames | list | [] | Hostnames to match on the Store Gateway HTTPRoute. |
| storegateway.httpRoute.parentRefs | list | [] | Gateway parentRefs for the Store Gateway HTTPRoute. |
| storegateway.ingress.annotations | object | {} | Deprecated. Use `storegateway.ingress.http.annotations` instead. |
| storegateway.ingress.className | string | `""` | Deprecated. Use `storegateway.ingress.http.className` instead. |
| storegateway.ingress.enabled | bool | `false` | Deprecated. Use `storegateway.ingress.http.enabled` instead. |
| storegateway.ingress.grpc.annotations | object | {} | Extra annotations for the Store Gateway gRPC Ingress. |
| storegateway.ingress.grpc.className | string | `""` | Ingress class name for Store Gateway gRPC endpoint (e.g. nginx, traefik). |
| storegateway.ingress.grpc.enabled | bool | `false` | Enable a Kubernetes Ingress for the Store Gateway gRPC endpoint. Note this is independent of ingress.enabled that is for the HTTP ingress. |
| storegateway.ingress.grpc.hosts[0].host | string | `"thanos-store-grpc.local"` |  |
| storegateway.ingress.grpc.hosts[0].paths[0].path | string | `"/"` |  |
| storegateway.ingress.grpc.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| storegateway.ingress.grpc.tls | list | [] | TLS configuration for the Store Gateway gRPC Ingress. |
| storegateway.ingress.hosts[0].host | string | `"thanos-store.local"` |  |
| storegateway.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| storegateway.ingress.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| storegateway.ingress.http.annotations | object | {} | Extra annotations for the Store Gateway HTTP Ingress. |
| storegateway.ingress.http.className | string | `""` | Ingress class name for Store Gateway HTTP endpoint (e.g. nginx, traefik). |
| storegateway.ingress.http.enabled | bool | `false` | Enable a Kubernetes Ingress for the Store Gateway HTTP endpoint. |
| storegateway.ingress.http.hosts[0].host | string | `"thanos-store.local"` |  |
| storegateway.ingress.http.hosts[0].paths[0].path | string | `"/"` |  |
| storegateway.ingress.http.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| storegateway.ingress.http.tls | list | [] | TLS configuration for the Store Gateway HTTP Ingress. |
| storegateway.ingress.tls | list | [] | Deprecated. Use `storegateway.ingress.http.tls` instead. |
| storegateway.labels | object | {} | Extra labels applied to Store Gateway resources. |
| storegateway.nodeSelector | object | {} | Node selector for Store Gateway pod scheduling. |
| storegateway.pdb.enabled | bool | `false` | Enable a PodDisruptionBudget for the Store Gateway. |
| storegateway.pdb.maxUnavailable | int or string | `""` | Maximum unavailable Store Gateway pods during a disruption. |
| storegateway.pdb.minAvailable | int or string | `""` | Minimum available Store Gateway pods during a disruption. |
| storegateway.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| storegateway.persistence.enabled | bool | `true` | Enable a PersistentVolumeClaim for the Store Gateway index cache and chunk store. |
| storegateway.persistence.size | string | `"10Gi"` | Storage capacity for the Store Gateway PVC. |
| storegateway.persistence.storageClass | string | `""` | StorageClass name for the Store Gateway PVC. Empty uses the cluster default. |
| storegateway.podSecurityContext.fsGroup | int | `1000` |  |
| storegateway.podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| storegateway.priorityClassName | string | `""` | Priority class name for Store Gateway pods. |
| storegateway.probes.liveness.enabled | bool | `true` | Enable the liveness probe for the Store Gateway. |
| storegateway.probes.liveness.failureThreshold | int | `6` | Consecutive failures before the Store Gateway container is restarted. |
| storegateway.probes.liveness.initialDelaySeconds | int | `30` | Seconds to wait before starting the Store Gateway liveness probe. |
| storegateway.probes.liveness.path | string | `"/-/healthy"` | HTTP path checked by the Store Gateway liveness probe. |
| storegateway.probes.liveness.periodSeconds | int | `10` | How often (seconds) to run the Store Gateway liveness probe. |
| storegateway.probes.liveness.successThreshold | int | `1` | Consecutive successes before the Store Gateway container is considered live. |
| storegateway.probes.liveness.timeoutSeconds | int | `5` | Seconds after which the Store Gateway liveness probe times out. |
| storegateway.probes.readiness.enabled | bool | `true` | Enable the readiness probe for the Store Gateway. |
| storegateway.probes.readiness.failureThreshold | int | `6` | Consecutive failures before the Store Gateway pod is marked not-ready. |
| storegateway.probes.readiness.initialDelaySeconds | int | `5` | Seconds to wait before starting the Store Gateway readiness probe. |
| storegateway.probes.readiness.path | string | `"/-/ready"` | HTTP path checked by the Store Gateway readiness probe. |
| storegateway.probes.readiness.periodSeconds | int | `10` | How often (seconds) to run the Store Gateway readiness probe. |
| storegateway.probes.readiness.successThreshold | int | `1` | Consecutive successes before the Store Gateway pod is marked ready. |
| storegateway.probes.readiness.timeoutSeconds | int | `5` | Seconds after which the Store Gateway readiness probe times out. |
| storegateway.probes.startup.enabled | bool | `true` | Enable the startup probe for the Store Gateway. |
| storegateway.probes.startup.failureThreshold | int | `60` | Consecutive failures during Store Gateway startup before the container is killed. |
| storegateway.probes.startup.initialDelaySeconds | int | `0` | Seconds to wait before starting the Store Gateway startup probe. |
| storegateway.probes.startup.path | string | `"/-/ready"` | HTTP path checked by the Store Gateway startup probe. |
| storegateway.probes.startup.periodSeconds | int | `5` | How often (seconds) to run the Store Gateway startup probe. |
| storegateway.probes.startup.successThreshold | int | `1` | Consecutive successes before the Store Gateway startup probe is considered passed. |
| storegateway.probes.startup.timeoutSeconds | int | `5` | Seconds after which the Store Gateway startup probe times out. |
| storegateway.replicaCount | int | `2` | Number of Store Gateway pod replicas. Two or more is recommended for HA. |
| storegateway.resources | object | {} | Resource requests and limits for the Store Gateway container. |
| storegateway.service.annotations | object | {} | Extra annotations for the Store Gateway Service. |
| storegateway.service.grpcPort | int | `10901` | gRPC Store API port exposed by the Store Gateway Service. |
| storegateway.service.httpPort | int | `10902` | HTTP port exposed by the Store Gateway Service. |
| storegateway.service.labels | object | {} | Extra labels for the Store Gateway Service. |
| storegateway.service.type | string | `"ClusterIP"` | Kubernetes Service type for the Store Gateway. |
| storegateway.serviceMonitor.annotations | object | {} | Extra annotations for the Store Gateway ServiceMonitor. |
| storegateway.serviceMonitor.enabled | bool | `false` | Enable a Prometheus Operator ServiceMonitor for the Store Gateway. |
| storegateway.serviceMonitor.interval | string | `""` | Scrape interval for the Store Gateway. Empty uses the Prometheus operator default. |
| storegateway.serviceMonitor.labels | object | {} | Extra labels for the Store Gateway ServiceMonitor. |
| storegateway.serviceMonitor.metricRelabelings | list | [] | Metric relabeling rules applied after Store Gateway metrics are ingested. |
| storegateway.serviceMonitor.relabelings | list | [] | Relabeling rules applied before Store Gateway metrics are ingested. |
| storegateway.serviceMonitor.scheme | string | `""` | Scrape scheme for the Store Gateway (http or https). |
| storegateway.serviceMonitor.scrapeTimeout | string | `""` | Scrape timeout for the Store Gateway. Empty uses the Prometheus operator default. |
| storegateway.serviceMonitor.tlsConfig | object | {} | TLS configuration for Store Gateway scraping. |
| storegateway.tolerations | list | [] | Tolerations for Store Gateway pod scheduling. |
| storegateway.topologySpreadConstraints | list | [] | Topology spread constraints for Store Gateway pods. |

---

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
