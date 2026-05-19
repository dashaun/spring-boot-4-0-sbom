<!-- .slide: data-background-color="#191e1e" -->

# Lab 2

### SBOM

`labs/lab-2-sbom/` — port `8082`

Notes:
**~8 min** — the "wow" moment. Stay in this lab a beat longer than the others. Note how *small* the diff is now that Lab 1 already had actuator.

```bash
# Start it (preflight already packaged):
cd labs/lab-2-sbom && ./mvnw spring-boot:run

# Live demo (HTTPie pretty-prints JSON automatically):
http localhost:8082/actuator/sbom
http localhost:8082/actuator/sbom/application | jq '.bomFormat, (.components | length)'

# Same jar -tvf as Lab 1 — but now the SBOM IS there:
jar -tvf labs/lab-2-sbom/target/lab-2-sbom-0.0.1-SNAPSHOT.jar | grep -i sbom
```

After the demo, pivot to the security problem: "this is on your public port."

---

## The diff from Lab 1

**One plugin. One property.**

```xml
<plugin>
    <groupId>org.cyclonedx</groupId>
    <artifactId>cyclonedx-maven-plugin</artifactId>
</plugin>
```

The plugin is **version-managed by the Spring Boot parent** — no version declaration needed. It runs during `package` and embeds `META-INF/sbom/application.cdx.json` into the jar.

---

## The property change

```properties
# Lab 1 had:
management.endpoints.web.exposure.include=health,info

# Lab 2 has:
management.endpoints.web.exposure.include=health,info,sbom
```

That's it. Spring Boot auto-discovers the embedded SBOM and registers `/actuator/sbom`.

---

## Build and look inside

```bash
cd labs/lab-2-sbom
./mvnw -DskipTests package

# Same command as Lab 1 — different answer:
jar -tvf target/lab-2-sbom-0.0.1-SNAPSHOT.jar | grep -i sbom
#  ...  META-INF/sbom/application.cdx.json
```

The SBOM ships **inside** the jar. The actuator just exposes what the build put there.

> No SBOM file on disk = no `/actuator/sbom`. The build step is the contract.

---

## Run and curl

```bash
java -jar target/lab-2-sbom-0.0.1-SNAPSHOT.jar
```

```bash
http localhost:8082/actuator/sbom
# {
#     "ids": [ "application" ]
# }

http localhost:8082/actuator/sbom/application | jq '.bomFormat'
# "CycloneDX"
```

---

## So what's wrong with this?

Your dependency tree is now a publicly reachable HTTP endpoint on the **same port your app serves traffic on**.

If `/hello` is exposed to the internet, so is `/actuator/sbom`.

That's Lab 3.

Notes:
- This is the "wow" moment — `http` it live (HTTPie pretty-prints, no jq needed for display).
- Then pivot to the security problem.
