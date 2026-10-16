package com.example.adt.adtservicea;

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

    private final RestClient serviceB;

    public ApiController(RestClient.Builder builder, @Value("${downstream.url}") String downstreamUrl) {
        this.serviceB = builder.baseUrl(downstreamUrl).build();
    }

    @GetMapping("/api/a")
    public Map<String, Object> a() {
        log.info("adt-service-a received request, calling service-b");
        Map<String, Object> downstream = serviceB.get()
                .retrieve()
                .body(new ParameterizedTypeReference<Map<String, Object>>() {});
        return Map.of("service", "adt-service-a", "downstream", downstream);
    }
}
