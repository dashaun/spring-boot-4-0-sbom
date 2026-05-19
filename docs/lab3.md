<!-- .slide: data-background-color="#191e1e" -->

# Lab 3

### Management Port

`labs/lab-3-mgmt-port/` — app `8083`, mgmt `9083`

Notes:
**~5 min** — don't oversell port isolation; it's defense in depth, not a security boundary by itself. Pivot fast to "let's actually authenticate this."

```bash
# Start it:
cd labs/lab-3-mgmt-port && ./mvnw spring-boot:run

# Show the port split (status line only):
http -h localhost:8083/hello | head -n1            # → 200
http -h localhost:8083/actuator/sbom | head -n1    # → 404 (not on app port)
http -h localhost:9083/actuator/sbom | head -n1    # → 200 (on mgmt port)
```

---

## One config change

```yaml
server:
  port: 8083

management:
  server:
    port: 9083       # ← actuator listens here instead
  endpoints:
    web:
      exposure:
        include: health,info,sbom
```

Spring Boot spins up a **second servlet container** on `9083`. Actuators bind to that one. `/hello` stays on `8083`.

---

## Why this matters

| Concern | Without split | With split |
|---|---|---|
| Firewall rule | "Allow 8082 from anywhere" exposes actuators | "Allow 8083 from anywhere, 9083 from VPN only" |
| Reverse proxy | Strip `/actuator` paths manually | Just don't forward port `9083` |
| Container | One port published | Publish `8083`; keep `9083` internal |

---

## Verify the split

```bash
# App traffic — port 8083
http -h localhost:8083/hello | head -n1
# HTTP/1.1 200

# Actuator on app port — 404 (it's not there anymore)
http -h localhost:8083/actuator/sbom | head -n1
# HTTP/1.1 404

# Actuator on management port — 200
http -h localhost:9083/actuator/sbom | head -n1
# HTTP/1.1 200
```

---

## So what's still wrong?

The management port is reachable from anywhere that can route to it. **Anyone with VPN access can list your entire dependency tree.**

Sometimes that's fine. Sometimes it isn't.

That's Lab 4.

Notes:
- Don't oversell port isolation — defense in depth, not a security boundary by itself.
- Pivot quickly to "let's actually authenticate this."
