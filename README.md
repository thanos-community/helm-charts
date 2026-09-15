# Thanos Community Helm Charts

[![Latest Release](https://img.shields.io/github/v/release/thanos-community/helm-charts?label=release)](https://github.com/thanos-community/helm-charts/releases/latest)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/thanos-community)](https://artifacthub.io/packages/search?repo=thanos-community)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

[![CI](https://github.com/thanos-community/helm-charts/actions/workflows/ci.yaml/badge.svg)](https://github.com/thanos-community/helm-charts/actions/workflows/ci.yaml)
[![Release](https://github.com/thanos-community/helm-charts/actions/workflows/release.yaml/badge.svg)](https://github.com/thanos-community/helm-charts/actions/workflows/release.yaml)
[![Docs](https://github.com/thanos-community/helm-charts/actions/workflows/docs.yaml/badge.svg)](https://github.com/thanos-community/helm-charts/actions/workflows/docs.yaml)
[![Renovate](https://github.com/thanos-community/helm-charts/actions/workflows/renovate.yaml/badge.svg)](https://github.com/thanos-community/helm-charts/actions/workflows/renovate.yaml)

[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/thanos-community/helm-charts/badge)](https://scorecard.dev/viewer/?uri=github.com/thanos-community/helm-charts)
[![Scorecard](https://github.com/thanos-community/helm-charts/actions/workflows/scorecard.yaml/badge.svg)](https://github.com/thanos-community/helm-charts/actions/workflows/scorecard.yaml)
[![Trivy](https://github.com/thanos-community/helm-charts/actions/workflows/trivy.yaml/badge.svg)](https://github.com/thanos-community/helm-charts/actions/workflows/trivy.yaml)
[![zizmor](https://github.com/thanos-community/helm-charts/actions/workflows/zizmor.yaml/badge.svg)](https://github.com/thanos-community/helm-charts/actions/workflows/zizmor.yaml)

Community-maintained Helm charts for deploying [Thanos](https://thanos.io/) on Kubernetes — a highly available Prometheus setup with long-term storage capabilities.

<p align="center"><img src="docs/imgs/thanos_logo_full.svg" alt="Thanos Logo" width="300"/></p>

## Available Charts

| Chart | Description |
| ----- | ----------- |
| [thanos](charts/thanos/) | All-in-one chart deploying Thanos components (Query, Receive, Store Gateway, Compactor, Ruler, BucketWeb) |

## Quick Start

```bash
helm install thanos oci://ghcr.io/thanos-community/helm-charts/thanos \
  --namespace monitoring \
  --create-namespace
```

See the [chart README](charts/thanos/README.md) for full installation instructions and configuration options.

## Prerequisites

- Kubernetes >= 1.30
- Helm >= 3.8 (OCI support)
- An object store bucket (GCS, S3, Azure Blob, etc.)

## Documentation

- [Chart Documentation](charts/thanos/README.md)
- [Thanos Official Docs](https://thanos.io/tip/thanos/getting-started.md/)
- [Object Store Configuration](https://thanos.io/tip/thanos/storage.md/)
- [Design Discussion](https://docs.google.com/document/d/18GXxwOm9c2fDK20LV1Sekte0xvK4qXpIGwBcuw_ZYSA/edit?usp=sharing)

## Contributing

Contributions are welcome! Please read the [Contributing Guide](CONTRIBUTING.md) before submitting pull requests.

## Community & Support

- [Thanos Slack](https://cloud-native.slack.com/archives/CL25937SP) — `#thanos` channel on CNCF Slack
- [GitHub Issues](https://github.com/thanos-community/helm-charts/issues) — bug reports and feature requests
- [Thanos GitHub](https://github.com/thanos-io/thanos) — upstream project

## License

[Apache 2.0](LICENSE)
