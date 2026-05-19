<!-- .slide: data-background-color="#191e1e" -->

# Lab 1

### Baseline

`labs/lab-1-baseline/` — port `8081`

Notes:
**~3 min** — establishes the diff baseline; don't dwell.

```bash
# In your lab-1 terminal:
cd labs/lab-1-baseline && ./mvnw spring-boot:run

# In your demo terminal:
http localhost:8081/hello
```

---

## What's in the box

A plain Spring Boot 4 web app. One controller. No actuator, no SBOM, nothing fancy.

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.0.5</version>
</parent>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>
</dependencies>
```

---

## The controller

```java
@RestController
class HelloController {

    @GetMapping("/hello")
    String hello() {
        return "Hello from lab-1-baseline. No SBOM here yet.";
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
# Content-Type: text/plain;charset=UTF-8
#
# Hello from lab-1-baseline. No SBOM here yet.
```

Notes:
- This lab establishes the diff baseline. From here, each lab adds exactly one capability.
- 30-second demo — don't dwell here.
