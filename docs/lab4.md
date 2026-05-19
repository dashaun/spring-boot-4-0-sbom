<!-- .slide: data-background-color="#191e1e" -->

# Lab 4

### Secured

`labs/lab-4-secured/` — app `8084`, mgmt `9084`

Notes:
**~10 min** — this is where the audience leans in. Copy-pasteable security config.

```bash
# Start it:
cd labs/lab-4-secured && ./mvnw spring-boot:run

# Show the auth gate (status line only):
http -h localhost:9084/actuator/health | head -n1                       # → 200 (open)
http -h localhost:9084/actuator/sbom   | head -n1                       # → 401 (gated)
http -h -a admin:changeme GET localhost:9084/actuator/sbom | head -n1   # → 200 (auth + role)
http -h -a admin:wrong    GET localhost:9084/actuator/sbom | head -n1   # → 401
```

Reminder: HTTPie defaults to POST when `-a` is set — always pass an explicit `GET`.

Tease the next section: "now that it's locked down, let's actually USE the SBOM."

---

## The diff: add Spring Security

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

```yaml
spring:
  security:
    user:
      name: admin
      password: ${ACTUATOR_PASSWORD:changeme}
      roles: ACTUATOR_ADMIN
```

The role-based piece is what we'll enforce next.

---

## The security configuration

```java
@Bean
@Order(Ordered.HIGHEST_PRECEDENCE)
SecurityFilterChain actuatorChain(HttpSecurity http) throws Exception {
    http
        .securityMatcher(EndpointRequest.toAnyEndpoint())
        .authorizeHttpRequests(auth -> auth
            .requestMatchers(EndpointRequest.to("health", "info")).permitAll()
            .anyRequest().hasRole("ACTUATOR_ADMIN"))
        .httpBasic(Customizer.withDefaults())
        .csrf(csrf -> csrf.disable());
    return http.build();
}
```

`EndpointRequest` matchers know the actuator base path — they keep working if you move it.

---

## And one for the main app

```java
@Bean
SecurityFilterChain appChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(a -> a.anyRequest().permitAll())
        .csrf(c -> c.disable());
    return http.build();
}
```

`/hello` stays open. Order matters: the actuator chain matches first (highest precedence), and the app chain catches everything else.

---

## Show the gate

```bash
# Liveness checks stay public
http -h localhost:9084/actuator/health | head -n1
# HTTP/1.1 200

# SBOM is gated
http -h localhost:9084/actuator/sbom | head -n1
# HTTP/1.1 401

# Auth with the right role (explicit GET — HTTPie defaults to POST when -a is set)
http -h -a admin:changeme GET localhost:9084/actuator/sbom | head -n1
# HTTP/1.1 200
```

---

## Why role-based, not just authenticated?

Once you have credentials, you can scope them.

- A **monitoring agent** gets only the role for `/health`, `/metrics`.
- A **security scanner** gets `ACTUATOR_ADMIN` and can read `/sbom`.
- A **human operator** might get everything but with audit logging.

The `EndpointRequest.to(...)` matchers make these splits a one-line change.

Notes:
- This is where the audience leans in — concrete, copy-pasteable security config.
- Tease the next section: "now that it's locked down, let's actually USE the SBOM."
