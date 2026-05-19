package dev.dashaun.sbom;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
class HelloController {

    @GetMapping("/hello")
    String hello() {
        return "Hello from lab-4-secured. Try /actuator/sbom on port 9084 with -a admin:changeme (HTTPie).";
    }
}
