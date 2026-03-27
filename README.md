# Thanos Community Helm Charts

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/thanos-community)](https://artifacthub.io/packages/search?repo=thanos-community)
[![License](https://img.shields.io/github/license/thanos-community/helm-charts)](https://github.com/thanos-community/helm-charts/blob/master/LICENSE)

Helm charts for [Thanos](https://thanos.io) and related components, maintained by the Thanos community.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

### Classic Helm repository

```bash
helm repo add thanos-community https://thanos-community.github.io/helm-charts
helm repo update
helm search repo thanos-community
```

### OCI registry (recommended)

```bash
helm install thanos oci://ghcr.io/thanos-community/charts/thanos --version <version>
```

All charts are available as OCI artifacts on [GitHub Container Registry](https://github.com/orgs/thanos-community/packages).

## Charts

| Chart | Description |
|-------|-------------|
| [thanos](https://github.com/thanos-community/helm-charts/tree/master/charts/thanos) | Highly available Prometheus setup with long term storage capabilities |

## Security

All charts are signed with [Cosign](https://docs.sigstore.dev/cosign/overview/) using keyless signing via GitHub Actions OIDC.

To verify a chart:

```bash
cosign verify ghcr.io/thanos-community/charts/thanos:<version> \
  --certificate-identity-regexp="https://github.com/thanos-community/helm-charts" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com"
```

## Contributing

The source code of all charts can be found on [GitHub](https://github.com/thanos-community/helm-charts).
Please refer to the [contribution guidelines](https://github.com/thanos-community/helm-charts/blob/master/CONTRIBUTING.md) for details.

## License

[Apache 2.0 License](https://github.com/thanos-community/helm-charts/blob/master/LICENSE)