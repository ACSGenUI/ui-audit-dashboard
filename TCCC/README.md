# TCCC Gating App source audit

- **Snapshot:** `stage`, revision `666f572221990fcac9092bfd5920486d8d77ec45`
- **Date:** 2026-11-23
- **Source:** https://github.com/adbprojectssam/tccc-gating-app
- **Dashboard:** [dashboard.html](./dashboard.html)
- **Data:** [Code checklist](./Code_Audit_Checklist.csv),
  [metrics](./Metrics.csv), [full audit](./audit.json)

This is a source-code audit, not an authenticated browser/manual audit or a
release/security/WCAG certification. Browser and manual checks remain unassessed.
The plaintext dashboard contains a static snapshot of all findings and needs no
network connection to render. JavaScript only enables search and filtering.

The checklist preserves the standard 11 columns. `Yes` means a source-level
pass; `No` means a verified source failure. Empty implementation cells are
explicitly identified as **Unassessed** or **Not applicable** in Comments.
Metrics distinguish those statuses and calculate the assessed-check pass rate
as `passed / (passed + failed)`. No overall UI score is claimed.

## Validation

Dependencies were restored from the lockfile using
`npm ci --ignore-scripts --no-audit --no-fund` on Node v22.13.0 / npm 10.9.2.
`npm run lint` passed. `npm test -- --runInBand` passed 625 tests in 25 suites;
13 additional suites failed to load the missing generated
`web-src/src/config.json`. No placeholder configuration was created.
`npm audit --json` reported 77 affected packages, including development and
transitive dependencies. Production build and authenticated smoke tests remain
outstanding.

Measurements cover 86 tracked production JS/TS files under source, actions,
scripts and hooks, plus tracked CSS/HTML inspection. Dependency internals,
generated files and rendered Spectrum markup are excluded. Source tag ratios
are repository-wide, not rendered per-page ratios. HTML-first checklist
requirements and required font binaries may need documented project exceptions.

To refresh, repeat the checklist review and validation against a new recorded
revision, update CSV/JSON/metrics, and regenerate the dashboard snapshot together.
Keep all dashboard data in this folder. Publish plaintext files through a PR to
`main`; CI produces the password-protected `reports` version.
