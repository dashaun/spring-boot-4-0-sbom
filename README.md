# Spring Boot 4 — SBOM Generation, Exposure & Scanning

A demo-heavy presentation repo that walks through generating a CycloneDX Software Bill of Materials at build time, exposing it via the Spring Boot Actuator, separating it onto a dedicated management port, securing it with Spring Security, and consuming it with [Trivy](https://trivy.dev) for vulnerability scanning.

> Companion presentation lives in [`docs/`](./docs/) (Reveal.js, served from any static host).

## Quick start

### Option A — GitHub Codespaces / Dev Container

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/dashaun/spring-boot-4-sbom)

The `.devcontainer/` brings JDK 25, Docker-in-Docker, and Trivy. No local setup required.

### Option B — Local

```bash
# JDK 25 + a recent Maven (the wrapper takes care of Maven)
git clone https://github.com/dashaun/spring-boot-4-sbom
cd spring-boot-4-sbom

cd labs/lab-1-baseline && ./mvnw spring-boot:run
```

## The four labs

| Lab | What it adds | App port | Mgmt port |
|---|---|---|---|
| [lab-1-baseline](./labs/lab-1-baseline) | Plain Spring Boot 4 web app | 8081 | — |
| [lab-2-sbom](./labs/lab-2-sbom) | CycloneDX plugin + `/actuator/sbom` | 8082 | 8082 (same) |
| [lab-3-mgmt-port](./labs/lab-3-mgmt-port) | Dedicated management port for actuators | 8083 | 9083 |
| [lab-4-secured](./labs/lab-4-secured) | Spring Security: HTTP Basic + role-based actuator access | 8084 | 9084 |

Each lab is a standalone Maven project. Run `./mvnw spring-boot:run` from inside any of them.

## The demo arc

1. **Build it** — `./mvnw package` in lab-2 onward embeds a CycloneDX SBOM in the jar (`META-INF/sbom/application.cdx.json`).
2. **Expose it** — `/actuator/sbom` lists embedded SBOMs; `/actuator/sbom/application` returns the JSON.
3. **Isolate it** — lab-3 moves the actuator to a separate port (`9083`) so you can firewall it.
4. **Secure it** — lab-4 adds HTTP Basic auth with an `ACTUATOR_ADMIN` role required for `/actuator/sbom`.
5. **Scan it** — `./scripts/scan-with-trivy.sh` pulls the secured SBOM and pipes it through `trivy sbom -`.

```bash
# Lab 4 — auth required
http http://localhost:9084/actuator/sbom               # → 401
http --check-status -a admin:changeme --print=b GET \
  http://localhost:9084/actuator/sbom/application | trivy sbom -
```

## Running the presentation

```bash
jwebserver -d "$(pwd)/docs" -p 8000
# open http://localhost:8000
```

## Presenting

Presenter cheatsheet lives in the **speaker notes of the deck itself** (press `S` in Reveal.js to open speaker view). The title slide carries pre-flight + setup; each lab's title slide carries its timing and paste-able demo commands.

## Companion docs

- [`CLAUDE.md`](./CLAUDE.md) — architecture & build commands (for AI coding assistants)
- [`AGENTS.md`](./AGENTS.md) — per-lab build/test matrix
