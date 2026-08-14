package com.smarthealthcare.backend.integration;

import com.smarthealthcare.backend.pharmacy.dto.PharmacySearchResponse;
import com.smarthealthcare.backend.pharmacy.service.HaversineDistanceCalculator;
import com.smarthealthcare.backend.pharmacy.service.PharmacyService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class PharmacyIntegrationTest {

    @Autowired
    private PharmacyService pharmacyService;

    @Autowired
    private HaversineDistanceCalculator distanceCalculator;

    @Test
    @DisplayName("Integration Test: Haversine Distance & Pharmacy Stock Proximity Search")
    void testHaversineDistanceAndStockSearch() {
        // Test Haversine distance calculation between Colombo 07 and Colombo 03
        double dist = distanceCalculator.calculateDistanceKm(6.9271, 79.8612, 6.9147, 79.8540);
        assertTrue(dist > 0.0 && dist < 5.0, "Calculated distance should be realistic");

        // Test pharmacy stock search
        List<PharmacySearchResponse> pharmacies = pharmacyService.searchNearbyPharmacies(6.9271, 79.8612, null);

        assertNotNull(pharmacies);
        assertFalse(pharmacies.isEmpty(), "Should return seeded partner pharmacies");
        assertTrue(pharmacies.get(0).getDistanceKm() <= pharmacies.get(pharmacies.size() - 1).getDistanceKm(),
                "Pharmacies should be sorted by distance nearest first");
    }
}
