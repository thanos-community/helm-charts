# Security Policy

## Supported Versions

Only the latest released version of each chart receives security fixes. Charts are
released continuously from `master`, so fixes ship as a new chart version rather than
as backports.

| Chart  | Supported          |
| ------ | ------------------ |
| latest | :white_check_mark: |
| older  | :x:                |

Vulnerabilities in the Thanos binary itself are handled by the upstream project; see the
[Thanos security policy](https://github.com/thanos-io/thanos/security/policy).

## Reporting a Vulnerability

Please **do not** open a public issue for security problems.

Report vulnerabilities privately through
[GitHub Security Advisories](https://github.com/thanos-community/helm-charts/security/advisories/new),
or by email to the Thanos team at <thanos-io@googlegroups.com>.

Include the chart version, the affected values/templates, and steps to reproduce. We aim
to acknowledge reports within 7 days and will coordinate a fix and disclosure with you.

## Release Integrity

Every chart release is built by the automated [release workflow](.github/workflows/release.yaml) and is:

- GPG-signed (Helm provenance file), with the provenance uploaded to the Rekor transparency log.
- Signed with [Cosign](https://docs.sigstore.dev/) keyless signing, both as a blob bundle
  attached to the GitHub Release and on the OCI artifact in `ghcr.io/thanos-community/helm-charts`.

To verify an OCI chart:

```bash
cosign verify ghcr.io/thanos-community/helm-charts/thanos:<version> \
  --certificate-identity-regexp '^https://github.com/thanos-community/helm-charts/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## Dependency Management

Dependencies (GitHub Actions, sub-charts, Thanos image) are updated by
[Renovate](renovate.json), with GitHub Actions pinned to commit digests. Dependabot is
enabled for security updates only.
