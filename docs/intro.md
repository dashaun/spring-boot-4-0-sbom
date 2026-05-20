<!-- .slide: data-background-color="#6db33f" -->

# Spring Boot 4

### SBOM Generation, Exposure & Scanning

DaShaun Carter | Spring Developer Advocate

Notes:
**Pre-flight (run before going on stage)**
- `./scripts/preflight.sh` — verifies toolchain, ports, builds each lab, smoke-tests every endpoint, warms the Trivy DB. Refuses to proceed until everything's green.
- If it fails on a port: `./scripts/stop-all-labs.sh` (or `pkill -f 'lab-.-.*\.jar'`).

**Running this deck**
- `jwebserver -d "$(pwd)/docs" -p 8000` — JDK 18+ built-in static server.
- Open http://localhost:8000 in a presenter window.

**Reveal.js shortcuts**
- `S` — speaker view (notes + next slide + timer)
- `B` — black out screen
- `F` — fullscreen
- `Esc` — slide overview

**Suggested timing (~40 min + Q&A)**

| Section | Time |
|---|---|
| Intro: why SBOMs matter | 5 min |
| Lab 1: baseline | 3 min |
| Lab 2: + CycloneDX + `/actuator/sbom` | 8 min |
| Lab 3: + separate management port | 5 min |
| Lab 4: + Spring Security | 10 min |
| Trivy demo (scan SBOM for CVEs) | 8 min |
| Q & A | open |

**Live-demo gotchas to watch for**
- Port still bound from a prior run → `lsof -i :PORT`, then kill the stray Java pid.
- `./mvnw` taking forever first time → preflight already packaged all labs.
- Trivy DB download on first run → preflight pre-downloaded it.

**Narrative**
- Build an SBOM, expose it safely, scan it for CVEs.
- Four labs, each ~5-10 minutes of code, all standalone Maven projects.
- Hands-on welcome — clone and follow along.

---

## Why this talk, why now

- **Executive Order 14028** (2021) — federal procurement requires SBOMs.
- **EU Cyber Resilience Act** (2024) — SBOMs for products with digital elements.
- **Real incidents** — Log4Shell, xz-utils backdoor — were "do we even use this?" emergencies.
- Spring Boot has shipped a turnkey answer since 3.3. Spring Boot 4 polishes it.

> An SBOM is just an ingredient list. The question is who can read it, and what they do with it.

---

## What you'll see

```text
Lab 1: Baseline app                  → no SBOM, just a starting point
Lab 2: + CycloneDX + /actuator/sbom  → it's literally one dependency + one plugin
Lab 3: + dedicated management port   → blast-radius reduction
Lab 4: + Spring Security             → who gets to see the ingredient list?
       → Pipe SBOM into Trivy        → close the loop on CVE scanning
```

Each lab is a `diff` away from the previous one.

---

## The repo

```bash
git clone https://github.com/dashaun/spring-boot-4-sbom
cd spring-boot-4-sbom
```

- **Each lab is standalone** — `cd labs/lab-N && ./mvnw spring-boot:run`.
- **Slides are the repo** — what you're reading is in `docs/`.

Notes:
- Prerequisites: JDK 25 + a recent Maven (the wrapper handles Maven), plus HTTPie and Trivy for the scan demo.
