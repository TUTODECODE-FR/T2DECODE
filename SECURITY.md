# Security Policy

## Scope

This policy covers:

- Source code hosted in this repository.
- Official release artifacts published on GitHub Releases.
- Local-only runtime behavior (offline-first, no cloud telemetry by design).

See also:

- `docs/security-model.md`
- `docs/threat-model.md`
- `docs/privacy.md`

## Supported Versions

Only the latest stable release is considered supported for security fixes.

| Version | Supported |
| :-- | :--: |
| Latest stable | ✅ |
| Older versions | ❌ |

## Security Controls (Current)

- SHA-256 checksums (`SHA256SUMS.txt`) are published for release assets.
- Linux detached signatures (`.sig`) are produced when release GPG secrets are configured.
- Asset integrity checks are executed at app startup.
- CI and release pipelines are versioned in `.github/workflows/`.
- Ownership policy is declared in `.github/CODEOWNERS`.

## Responsible Disclosure

Do not open public GitHub issues for vulnerabilities.

Use one of these private channels:

- GitHub private security advisory.
- Email: `contact@tutodecode.org`.

When reporting, include:

- Affected version/tag.
- Reproduction steps.
- Impact summary.
- Suggested remediation (if available).

## Response Targets

- Acknowledgement target: within 72 hours.
- Triage target: within 7 business days.
- Fix timeline: depends on severity and platform impact.

After a fix:

- A patched release is published.
- Changelog/release notes mention the correction scope.

## Trust and Verification

Before installing binaries, verify checksums:

```bash
sha256sum -c SHA256SUMS.txt
```

If `.sig` files are present, verify signatures with the public key distributed by maintainers.

## Known Limitations

- Project is still early-stage and maintained by a small team.
- Some signing/notarization paths are conditional on secrets availability in CI.
