package com.example.adt.servicec;

import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
public class ApiController {

    private static final Logger log = LoggerFactory.getLogger(ApiController.class);

    private static final double ERROR_RATE = 0.10;

    @GetMapping("/api/c")
    public Map<String, Object> c() throws InterruptedException {
        // Random latency and occasional failures so APM has something to show
        long latencyMs = ThreadLocalRandom.current().nextLong(20, 201);
        Thread.sleep(latencyMs);

        if (ThreadLocalRandom.current().nextDouble() < ERROR_RATE) {
            log.error("service-c simulated failure after {} ms", latencyMs);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "simulated failure");
        }

        log.info("service-c handled request in {} ms", latencyMs);
        return Map.of("service", "service-c", "latency_ms", latencyMs);
    }
}
