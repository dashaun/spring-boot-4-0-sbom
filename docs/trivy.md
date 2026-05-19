<!-- .slide: data-background-color="#6db33f" -->

# Closing the Loop

### Scan the SBOM with Trivy

Notes:
**~8 min** — the payoff. Lab-4 must still be running on port 9084.

```bash
# One-shot via the helper:
./scripts/scan-with-trivy.sh

# Or the manual roundtrip:
http --check-status --print=b -a admin:changeme GET \
  localhost:9084/actuator/sbom/application | trivy sbom -
```

If Boot 4.0.5 has no current CVEs in the demo SBOM, point to an older artifact you've kept around for narrative effect — `trivy sbom <old-cdx.json>` from a 3.x build usually finds something.

---

## What Trivy does

[Trivy](https://trivy.dev) is an open-source vulnerability scanner. It speaks **CycloneDX** natively — feed it a CycloneDX JSON and it will tell you which dependencies have published CVEs.

> The SBOM tells you what's in the box. Trivy tells you which of those things are on fire.

---

## The roundtrip

```bash
# Pull the SBOM from the secured endpoint, pipe it into trivy.
# --print=b: body only (no headers).  --check-status: fail on 4xx/5xx.
# GET is explicit because HTTPie defaults to POST when -a is set.
http --check-status --print=b -a admin:changeme GET \
  localhost:9084/actuator/sbom/application \
  | trivy sbom -
```

Or use the helper:

```bash
./scripts/scan-with-trivy.sh
```

---

## Why this is interesting

The SBOM is generated **at build time** but exposed **at runtime**.

This means you're scanning the **actual deployed artifact**, not whatever was on the CI runner three months ago.

Different jars, different SBOMs. Different SBOMs, different CVEs.

---

## Production-ready variations

| Need | Approach |
|---|---|
| Scheduled scans | cron + the helper script → push to Slack on findings |
| Air-gapped envs | `trivy --offline-scan` with a pre-downloaded DB |
| Centralized inventory | Push SBOM to [Dependency-Track](https://dependencytrack.org/) |
| CI gating | Run scan in CI, fail the build on `--severity CRITICAL` |

Same pattern — the SBOM endpoint is just JSON.

Notes:
- This is the payoff slide — show the live trivy output if possible.
- If there are no CVEs in a current Boot 4.0.5, show with an older lab artifact for narrative effect.
