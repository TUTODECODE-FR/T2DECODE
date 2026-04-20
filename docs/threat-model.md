# Threat Model

## Scope

T2DECODE is designed for local-first usage in offline or constrained environments.  
The threat model focuses on:

- Integrity of distributed binaries.
- Integrity of bundled educational assets.
- Confidentiality of local user data.
- Local AI usage through Ollama without cloud dependency.

## Security Assumptions

- The host OS is not already fully compromised.
- Users install artifacts from official GitHub releases.
- Verification checks (`SHA256SUMS.txt`) are performed before install in sensitive contexts.
- Ollama runs on a trusted local endpoint configured by the user.

## Main Threats

| ID | Threat | Impact | Current Mitigations |
| :-- | :-- | :-- | :-- |
| T1 | Tampered release artifact | High | Release checksums, optional GPG signatures, protected release workflow |
| T2 | Asset modification after install | Medium | Startup integrity verification (`AssetIntegrityService`) |
| T3 | Data exfiltration through cloud dependency | High | Zero-cloud architecture, local Ollama only, no telemetry |
| T4 | Supply-chain compromise in CI/CD | High | Pinned actions, isolated runners, release-only tagging workflow |
| T5 | Malicious or unsafe module content | Medium | Local-only loading, signed-content roadmap, manual review process |
| T6 | LAN abuse in Ghost Link mode | Medium | Local network scope, encrypted messaging, user-controlled activation |

## Controls Matrix

| Control | Description | Status | Evidence |
| :-- | :-- | :-- | :-- |
| C1 | SHA-256 checksum publication for every release | Implemented | `SHA256SUMS.txt` in release assets |
| C2 | Detached signatures for Linux artifacts when GPG secret is configured | Implemented (conditional) | `.sig` assets in release |
| C3 | Startup asset integrity validation | Implemented | `lib/core/services/asset_integrity_service.dart` |
| C4 | No third-party analytics/telemetry SDK | Implemented | `docs/privacy.md`, dependency review |
| C5 | CODEOWNERS and manual review policy | Implemented | `.github/CODEOWNERS`, `CONTRIBUTING.md` |
| C6 | Build provenance attestation in release workflow | Implemented | `.github/workflows/build_release.yml` |

## Residual Risks

- Single maintainer model increases operational risk.
- Some platform signing pipelines are conditional on secret availability.
- Manual validation coverage can vary between releases.

## Planned Hardening

- Add release signature verification guide per OS.
- Add reproducible build notes and deterministic build checks.
- Publish periodic security review notes in `docs/releases/`.
