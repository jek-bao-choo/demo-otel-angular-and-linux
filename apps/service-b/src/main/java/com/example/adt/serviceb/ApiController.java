package com.example.adt.serviceb;

import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;

@RestController
public class ApiController {

    private static final Logger log = LoggerFactory.getLogger(ApiController.class);

    private final RestClient serviceC;

    public ApiController(RestClient.Builder builder, @Value("${downstream.url}") String downstreamUrl) {
        this.serviceC = builder.baseUrl(downstreamUrl).build();
    }

    @GetMapping("/api/b")
    public Map<String, Object> b() {
        log.info("service-b received request, calling service-c");
        Map<String, Object> downstream = serviceC.get()
                .retrieve()
                .body(new ParameterizedTypeReference<Map<String, Object>>() {});
        return Map.of("service", "service-b", "downstream", downstream);
    }
}
