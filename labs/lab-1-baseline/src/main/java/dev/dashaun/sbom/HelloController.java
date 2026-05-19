package dev.dashaun.sbom;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
class HelloController {

    @GetMapping("/hello")
    String hello() {
        return "Hello from lab-1-baseline. Production-ready: /actuator/health and /actuator/info are live.";
    }
}
