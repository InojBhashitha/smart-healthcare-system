package com.smarthealthcare.backend.pharmacy.controller;

import com.smarthealthcare.backend.exception.ResourceNotFoundException;
import com.smarthealthcare.backend.pharmacy.dto.PharmacySearchResponse;
import com.smarthealthcare.backend.pharmacy.dto.ReservationRequest;
import com.smarthealthcare.backend.pharmacy.entity.PrescriptionReservation;
import com.smarthealthcare.backend.pharmacy.service.PharmacyService;
import com.smarthealthcare.backend.user.entity.User;
import com.smarthealthcare.backend.user.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/pharmacies")
public class PharmacyController {

    private final PharmacyService pharmacyService;
    private final UserRepository userRepository;

    public PharmacyController(PharmacyService pharmacyService, UserRepository userRepository) {
        this.pharmacyService = pharmacyService;
        this.userRepository = userRepository;
    }

    @GetMapping("/search-stock")
    public ResponseEntity<List<PharmacySearchResponse>> searchNearbyPharmacies(
            @RequestParam(defaultValue = "6.9271") double lat,
            @RequestParam(defaultValue = "79.8612") double lng,
            @RequestParam(required = false) Long prescriptionId) {

        List<PharmacySearchResponse> pharmacies = pharmacyService.searchNearbyPharmacies(lat, lng, prescriptionId);
        return ResponseEntity.ok(pharmacies);
    }

    @PostMapping("/reservations/create")
    public ResponseEntity<PrescriptionReservation> createReservation(
            Authentication authentication,
            @RequestBody ReservationRequest request) {

        User user = getUserFromAuth(authentication);
        PrescriptionReservation reservation = pharmacyService.createReservation(user, request);
        return ResponseEntity.ok(reservation);
    }

    @GetMapping("/reservations/my-reservations")
    public ResponseEntity<List<PrescriptionReservation>> getMyReservations(Authentication authentication) {
        User user = getUserFromAuth(authentication);
        List<PrescriptionReservation> reservations = pharmacyService.getUserReservations(user.getUserId());
        return ResponseEntity.ok(reservations);
    }

    private User getUserFromAuth(Authentication authentication) {
        String email = authentication.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + email));
    }
}
