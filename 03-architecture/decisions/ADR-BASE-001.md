# ADR-BASE-001: Rebase Implementation Baseline to Upstream wpa_supplicant 2.12

**GitHub Issue**: #63  
**Date**: 2026-08-27

See [GitHub Issue #63](https://github.com/johnfu-ai/802.1X_dev_practices/issues/63) for full context, alternatives, and consequences.

## Status

Accepted

## Context

The implementation fork was based on the official `wpa_supplicant-2.11.tar.gz`
snapshot. Upstream released wpa_supplicant 2.12 (w1.fi), which includes
security fixes and protocol work that this project would otherwise drift away
from — in particular EAP-TEAP changes (deprecated PAC/provisioning removal
per RFC 7170bis, S-IMCK derivation fix, FreeRADIUS compatibility mode) and
EAP-over-Authentication-frames support in the supplicant EAPOL state machine.

The fork's history is unrelated to the w1.fi git history (tarball-import
root), so a naive merge has no common ancestor.

## Decision

1. Rebase the implementation baseline from 2.11 to the official
   `wpa_supplicant-2.12.tar.gz` snapshot, merged into the fork's `main`
   branch (merge commit `e86339efe` in johnfu-ai/wpa_supplicant, 2026-08-27).
2. Establish the merge base by grafting histories without rewriting published
   history: a history-connecting commit (`37a209526`) on the vendor-import
   branch `w1.fi/wpa_supplicant_2.12` adds the fork's 2.11 root commit as a
   second parent, enabling a true 3-way merge (base = 2.11 tarball tree).
3. Where upstream and the fork had not yet diverged, follow upstream. In
   particular, accept the upstream removal of EAP-TEAP PAC provisioning
   support: the fork's `anon_provisioning` phase-2 method check was dropped
   together with the rest of the PAC code (RFC 7170bis deprecates PAC
   provisioning). This **supersedes StR-005 success criterion 5** as
   originally written; the requirement is revised in place with a dated note.
4. All `CONFIG_IEEE8021X_2020*`-gated fork code (Logon Process, NID, ANCP,
   MKA 2020 extensions, CP/PACP wiring, EAP-TEAP reauth enablement) is
   retained unchanged, per ADR-COMPAT-001.

## Consequences

- **Positive**: baseline picks up upstream 2.12 security/protocol fixes;
  conflict surface for future upstream syncs stays limited to genuinely
  fork-modified files; the graft technique is repeatable for 2.13+.
- **Positive**: EAP-over-auth-frame infrastructure from upstream is now
  available for 802.1X-2020 work if needed.
- **Negative**: EAP-TEAP deployments relying on PAC provisioning (implicit
  provisioning with machine credentials) are no longer supported, mirroring
  upstream; deployments must use certificate/identity-based TLS provisioning.
- **Negative**: baseline-equivalence statements (release guide,
  DESIGN-PAE-001 non-regression verification) must reference 2.12 from now on
  (updated 2026-08-27).
- **Neutral**: ADR-ARCH-001 and other decision-time records continue to
  describe the 2.11-era context in which they were written.

## Requirements Satisfied

- StR-005 (revised criterion 5, GitHub Issue #28 context)
- StR-008 / REQ-NF-COMPAT-001/002/003 (gating preserved; non-opt-in builds
  remain equivalent to upstream 2.12)

## Verification Evidence

- Full build of `wpa_supplicant`/`wpa_cli`/`wpa_passphrase` with
  `CONFIG_IEEE8021X_2020_LOGON=y`, `CONFIG_EAP_TEAP=y`, `CONFIG_MACSEC=y`,
  `CONFIG_EAP_TNC=y`: clean, no warnings; binaries report v2.12.
- `tests/pae && make test`: 90/90 PASS across 6 suites (logon 24, cp 12,
  kay 9, pacp 8, nid 20, ancp 17).
