# Contributing to Thanos Community Helm Charts

Thank you for your interest in contributing! This guide explains how to set up a local development environment, make changes, test them, and submit a pull request.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Updating Documentation](#updating-documentation)
- [Release Process](#release-process)
- [Getting Help](#getting-help)

## Code of Conduct

This project follows the [CNCF Code of Conduct](https://github.com/cncf/foundation/blob/main/code-of-conduct.md). By participating, you agree to uphold it.

## Prerequisites

Make sure you have the following tools installed:

| Tool | Version | Purpose |
| --- | --- | --- |
| [Helm](https://helm.sh/docs/intro/install/) | >= 3.8 | Chart packaging and testing |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | >= 1.30 | Cluster interaction |
| [KinD](https://kind.sigs.k8s.io/docs/user/quick-start/) | latest | Local Kubernetes clusters for integration tests |
| [chart-testing (ct)](https://github.com/helm/chart-testing) | latest | Helm chart linting and testing |
| [helm-docs](https://github.com/norwoodj/helm-docs) | latest | README generation from `values.yaml` |
| [helm-unittest](https://github.com/helm-unittest/helm-unittest) | latest | Unit testing for chart templates |

## Getting Started

### 1. Fork and clone the repository

```bash
git clone https://github.com/<your-username>/helm-charts.git
cd helm-charts
```

### 2. Add the upstream remote

```bash
git remote add upstream https://github.com/thanos-community/helm-charts.git
```

### 3. Install chart dependencies

```bash
helm repo add thanos-community https://thanos-community.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm dependency update charts/thanos
```

### 4. Create a working branch

```bash
git checkout -b feat/my-feature
```

## Making Changes

### Chart structure

```text
charts/thanos/
├── Chart.yaml            # Chart metadata, version, appVersion, dependencies
├── values.yaml           # Default values (source of truth for docs)
├── values.schema.json    # JSON schema for values validation
├── README.md             # Auto-generated — do not edit directly
├── README.md.gotmpl      # Edit this to change the chart documentation template
└── templates/            # Kubernetes resource templates
    ├── _helpers.tpl       # Shared template helpers
    ├── NOTES.txt          # Post-install notes
    └── <component>/       # One directory per Thanos component
```

### Editing values

All values are documented inline in [values.yaml](charts/thanos/values.yaml) using `helm-docs` annotations:

```yaml
# -- Short description shown in the generated README values table
myKey: myValue

# -- Multi-line description.
# Continues on the next comment line.
# @default -- custom default shown instead of the raw value
myComplexKey: {}
```

- `# --` on a line above a key produces a description in the generated README.
- `# @default -- <text>` overrides the default value shown in the table (useful for large objects).

### Bumping versions

- **Chart change** (templates, values, helpers): bump `version` in `Chart.yaml`.
- **Thanos image update**: bump `appVersion` in `Chart.yaml` and `global.image.tag` in `values.yaml`.
- Follow [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

The CI pipeline enforces that chart version is incremented on every PR that modifies `charts/**`.

## Testing

### Install the helm-unittest plugin

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest
```

### Lint the chart

```bash
ct lint
```

### Run unit tests

Unit tests live under `charts/thanos/tests/` and use the [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin:

```bash
helm dependency build charts/thanos
helm unittest charts/thanos
```

To run a specific test file:

```bash
helm unittest charts/thanos -f tests/gateway_api_test.yaml
```

### Run a full integration test on a local KinD cluster

```bash
# Create the cluster
kind create cluster --config .github/kind-config.yaml

# Run chart-testing install
ct install
```

### Generate updated README

After editing `values.yaml` or `README.md.gotmpl`, regenerate the chart README:

```bash
helm-docs --chart-search-root charts/
```

The generated `charts/thanos/README.md` should be committed alongside your changes.

### Validate the JSON schema

```bash
helm lint charts/thanos --strict
```

## Submitting a Pull Request

1. **Keep PRs focused** — one logical change per PR. Mixing unrelated changes makes review harder.

2. **Commit messages** — use [Conventional Commits](https://www.conventionalcommits.org/):

   ```text
   feat(query): add support for query timeout flag
   fix(compactor): correct PVC access mode default
   docs(readme): update object store configuration examples
   chore(deps): bump kube-prometheus-stack to 80.3.0
   ```

3. **Sign your commits (DCO)** — all commits must be signed off:

   ```bash
   git commit -s -m "feat(query): add timeout flag support"
   ```

   Or configure Git to sign off automatically:

   ```bash
   git config --global format.signoff true
   ```

4. **Fill out the PR template** — describe what changed and why, reference related issues, and confirm you have tested the change.

5. **CI must pass** — the pipeline runs linting, schema validation, and integration tests. Fix any failures before requesting review.

6. **Chart version bump** — any change to `charts/thanos/**` requires a `version` bump in `Chart.yaml`. CI will fail if this is missing.

### PR checklist

- [ ] `Chart.yaml` version is incremented
- [ ] `values.yaml` changes are reflected in the regenerated `README.md`
- [ ] `helm unittest charts/thanos` passes
- [ ] `ct lint` passes without errors
- [ ] Commits are signed off (`git commit -s`)

## Updating Documentation

Chart documentation is auto-generated from `values.yaml` comments and `README.md.gotmpl` using `helm-docs`. **Never edit `charts/thanos/README.md` directly** — your changes will be overwritten.

To update:

1. Edit `values.yaml` inline comments (for values descriptions).
2. Edit `README.md.gotmpl` (for sections, examples, and structure).
3. Run `helm-docs --chart-search-root charts/` to regenerate `README.md`.
4. Commit both the template/values changes and the regenerated `README.md`.

## Release Process

Releases are fully automated via GitHub Actions:

1. A PR is merged into `master` with a version bump in `Chart.yaml`.
2. The [release workflow](.github/workflows/release.yaml) triggers automatically.
3. It packages the chart, signs it with [Cosign](https://docs.sigstore.dev/), pushes it to the OCI registry (`ghcr.io/thanos-community/helm-charts`), and creates a GitHub Release.

Maintainers do not need to manually tag or publish releases.

## Getting Help

- **Slack**: Join `#thanos` on [CNCF Slack](https://cloud-native.slack.com/archives/CL25937SP)
- **GitHub Issues**: [Open an issue](https://github.com/thanos-community/helm-charts/issues) for bug reports or feature requests
- **GitHub Discussions**: Use [Discussions](https://github.com/thanos-community/helm-charts/discussions) for questions and ideas
