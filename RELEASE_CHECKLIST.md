# Release Checklist — wpa_supplicant-8021X-2020

## Pre-Release

- [ ] All CI tests pass on all platforms (Linux, Windows, macOS)
- [ ] Code coverage meets threshold (>80%)
- [ ] All linked GitHub issues resolved or deferred
- [ ] CHANGELOG.md updated with release notes
- [ ] VERSION file updated
- [ ] No `TODO` or `FIXME` items in release-critical code
- [ ] Documentation is current and complete
- [ ] Architecture decisions (ADRs) are up to date

## Standards Compliance

- [ ] Protocol conformance tests pass
- [ ] Specification section references are accurate
- [ ] No vendor or OS-specific code in standards layer
- [ ] Copyright compliance verified (no reproduced spec text)

## Quality Gates

- [ ] Static analysis clean (no critical/high findings)
- [ ] No security vulnerabilities (OWASP Top 10 review)
- [ ] Memory safety verified (no leaks, bounds violations)
- [ ] Performance benchmarks within specification limits

## Release Process

1. [ ] Create release branch from `main`
2. [ ] Update VERSION to release number
3. [ ] Update CHANGELOG.md with release date
4. [ ] Run full test suite
5. [ ] Tag release: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
6. [ ] Create GitHub Release with notes
7. [ ] Merge back to `main`

## Post-Release

- [ ] Verify release artifacts are downloadable
- [ ] Update documentation links
- [ ] Announce release to stakeholders
- [ ] Plan next iteration
