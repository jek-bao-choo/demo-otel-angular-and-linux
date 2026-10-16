package com.example.adt.adtservicea;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;

/**
 * Backend for the Shipping Express website. Every endpoint calls service-b (which calls
 * service-c), so each browser action becomes one adt-service-a -> service-b -> service-c trace.
 */
@RestController
@RequestMapping("/api")
public class ShippingController {

    private static final Logger log = LoggerFactory.getLogger(ShippingController.class);

    private static final String[] TRACKING_STATUSES = {
        "Shipment picked up", "Processed at Singapore hub", "In transit", "Arrived at destination facility",
        "Out for delivery", "Delivered"
    };

    private final RestClient serviceB;

    public ShippingController(RestClient.Builder builder, @Value("${downstream.url}") String downstreamUrl) {
        this.serviceB = builder.baseUrl(downstreamUrl).build();
    }

    @PostMapping("/shipments")
    public Map<String, Object> createShipment(@RequestBody Map<String, String> request) {
        log.info("Creating shipment from {} ({}) to {} ({})", request.get("from"), request.get("fromCountry"),
                request.get("to"), request.get("toCountry"));
        callDownstream();
        String shipmentId = "SE" + ThreadLocalRandom.current().nextLong(1_000_000_000L, 9_999_999_999L);
        log.info("Created shipment {}", shipmentId);
        return Map.of("shipmentId", shipmentId, "status", "CREATED");
    }

    @PostMapping("/quotes")
    public Map<String, Object> quote(@RequestBody Map<String, String> request) {
        log.info("Quoting {} -> {}", request.get("fromCountry"), request.get("toCountry"));
        callDownstream();
        double price = ThreadLocalRandom.current().nextDouble(25, 180);
        int days = ThreadLocalRandom.current().nextInt(1, 5);
        return Map.of("price", Math.round(price * 100) / 100.0, "currency", "SGD",
                "eta", LocalDate.now().plusDays(days).format(DateTimeFormatter.ISO_LOCAL_DATE));
    }

    @PostMapping("/pickups")
    public Map<String, Object> schedulePickup(@RequestBody Map<String, String> request) {
        log.info("Scheduling pickup at {} on {}", request.get("address"), request.get("date"));
        callDownstream();
        String pickupId = "PU" + ThreadLocalRandom.current().nextInt(100_000, 999_999);
        return Map.of("pickupId", pickupId, "window", "09:00 - 13:00");
    }

    @GetMapping("/track/{id}")
    public Map<String, Object> track(@PathVariable String id) {
        log.info("Tracking shipment {}", id);
        callDownstream();
        String status = TRACKING_STATUSES[ThreadLocalRandom.current().nextInt(TRACKING_STATUSES.length)];
        return Map.of("id", id, "status", status, "lastScan", "Singapore - SG");
    }

    private Map<String, Object> callDownstream() {
        return serviceB.get()
                .retrieve()
                .body(new ParameterizedTypeReference<Map<String, Object>>() {});
    }
}
