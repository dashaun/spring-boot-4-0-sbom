<!-- .slide: data-background-color="#191e1e" -->

# Lab 2

### SBOM

`labs/lab-2-sbom/` — port `8082`

Notes:
**~8 min** — the "wow" moment. Stay in this lab a beat longer than the others.

```bash
# Start it (preflight already packaged):
cd labs/lab-2-sbom && ./mvnw spring-boot:run

# Live demo (HTTPie pretty-prints JSON — no jq needed for display):
http localhost:8082/actuator/sbom
http localhost:8082/actuator/sbom/application | jq '.bomFormat, (.components | length)'

# Show the SBOM was embedded at BUILD time:
unzip -l labs/lab-2-sbom/target/lab-2-sbom-0.0.1-SNAPSHOT.jar | grep sbom
```

After the demo, pivot to the security problem: "this is on your public port."

---

## The diff from Lab 1

Two adds: a dependency and a plugin.

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

```xml
<plugin>
    <groupId>org.cyclonedx</groupId>
    <artifactId>cyclonedx-maven-plugin</artifactId>
</plugin>
```

The CycloneDX plugin is **version-managed by the Spring Boot parent** — no version declaration needed.

---

## Expose the endpoint

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,sbom
```

That's the whole config change. Spring Boot's auto-configuration discovers the SBOM that the CycloneDX plugin embedded at `META-INF/sbom/application.cdx.json` and registers `/actuator/sbom`.

---

## Build and run

```bash
cd labs/lab-2-sbom
./mvnw -DskipTests package
java -jar target/lab-2-sbom-0.0.1-SNAPSHOT.jar
```

Then:

```bash
http localhost:8082/actuator/sbom
# HTTP/1.1 200
# Content-Type: application/vnd.spring-boot.actuator.v3+json
#
# {
#     "ids": [ "application" ]
# }

http localhost:8082/actuator/sbom/application | jq '.bomFormat'
# "CycloneDX"
```

---

## What's actually in the jar?

```bash
unzip -l target/lab-2-sbom-0.0.1-SNAPSHOT.jar | grep sbom
#  ...  META-INF/sbom/application.cdx.json
```

The SBOM ships **inside** the jar. The actuator just exposes what the build put there.

> No SBOM file on disk = no `/actuator/sbom`. The build step is the contract.

---

## So what's wrong with this?

Your dependency tree is now a publicly reachable HTTP endpoint on the **same port your app serves traffic on**.

If `/hello` is exposed to the internet, so is `/actuator/sbom`.

That's Lab 3.

Notes:
- This is the "wow" moment — `http` it live (HTTPie pretty-prints, no jq needed for display).
- Then pivot to the security problem.
