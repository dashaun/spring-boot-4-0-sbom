<!-- .slide: data-background-color="#191e1e" -->

# Recap

---

## What we covered

1. **Build it** — `cyclonedx-maven-plugin` embeds an SBOM in the jar.
2. **Expose it** — `/actuator/sbom` is one config line away.
3. **Isolate it** — `management.server.port` keeps it off the public listener.
4. **Secure it** — `EndpointRequest` matchers + role-based HTTP Basic.
5. **Scan it** — `trivy sbom -` closes the loop on supply-chain CVEs.

---

## Spring Boot 4 superpowers used

| Feature | Lab |
|---|---|
| `spring-boot-starter-actuator` | 2 |
| `cyclonedx-maven-plugin` (version-managed) | 2 |
| `/actuator/sbom` endpoint (auto-config) | 2 |
| `management.server.port` | 3 |
| `EndpointRequest.toAnyEndpoint()` | 4 |
| Role-based `authorizeHttpRequests` | 4 |

---

## Take it home

```bash
git clone https://github.com/dashaun/spring-boot-4-sbom
```

- **Four diff-able labs** — read in order or jump around.
- **Slides + speaker notes** — `jwebserver -d "$(pwd)/docs" -p 8000`.

---

<!-- .slide: data-background-color="#6db33f" -->

# Thank you

@dashaun on most places · dashaun.com
