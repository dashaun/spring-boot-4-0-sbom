<!-- .slide: data-background-color="#191e1e" -->

# Lab 1

### Production-ready Baseline

`labs/lab-1-baseline/` — port `8081`

Notes:
**~3 min** — set the framing: actuator is the baseline, not an extra. Don't dwell on the controller.

```bash
# In your lab-1 terminal:
cd labs/lab-1-baseline && ./mvnw spring-boot:run

# In your demo terminal:
http localhost:8081/hello
http localhost:8081/actuator/health      # the table-stakes check
http localhost:8081/actuator/info

# Look inside the jar — no SBOM yet (sets up Lab 2):
jar -tvf labs/lab-1-baseline/target/lab-1-baseline-0.0.1-SNAPSHOT.jar | grep -i sbom
```

---

## Health is table stakes

Going to production **without** `/actuator` should be the exception, not the rule.

- Load balancers want `/actuator/health` for traffic routing.
- Orchestrators want it for liveness/readiness probes.
- Ops wants `/actuator/info` for build provenance.

So the baseline isn't "plain web app" — it's **plain web app + actuator turned on**.

---

## What's in the box

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.0.6</version>
</parent>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
</dependencies>
```

---

## Expose the table-stakes endpoints

```properties
server.port=8081
spring.application.name=lab-1-baseline

management.endpoints.web.exposure.include=health,info
```

Spring Boot's default is to expose **only** `/actuator/health`. We're also opting `/actuator/info` in — both are safe to expose, both are useful in prod.

---

## The controller

```java
@RestController
class HelloController {

    @GetMapping("/hello")
    String hello() {
        return "Hello from lab-1-baseline. Production-ready: " +
               "/actuator/health and /actuator/info are live.";
    }
}
```

---

## Run it

```bash
cd labs/lab-1-baseline
./mvnw spring-boot:run
```

```bash
http localhost:8081/hello
# HTTP/1.1 200

http localhost:8081/actuator/health
# {"status":"UP"}

http localhost:8081/actuator/info
# {}
```

---

## Look inside the jar

```bash
./mvnw -DskipTests package
jar -tvf target/lab-1-baseline-0.0.1-SNAPSHOT.jar | grep -i sbom
# (no output)
```

No SBOM in here. We have a healthy, observable app — but if someone asks **"what's inside that jar?"** we can't answer.

That's Lab 2.

Notes:
- The `jar -tvf | grep sbom` returning nothing is the punchline — keep the terminal visible.
- Same command in Lab 2 will show the file appear.
