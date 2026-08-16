package com.smarthealthcare.web.controller;

import com.smarthealthcare.web.service.ProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.smarthealthcare.web.security.SecurityUtils;
import com.smarthealthcare.web.entity.User;
import com.smarthealthcare.web.entity.Pharmacy;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;

@RestController
@RequestMapping("/api/web/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileService profileService;

    @GetMapping
    public ResponseEntity<User> getProfile() {
        Long userId = SecurityUtils.getAuthenticatedUserId();
        User user = profileService.getProfile(userId);
        return ResponseEntity.ok(user);
    }

    @PutMapping("/location")
    public ResponseEntity<Pharmacy> updateLocation(
            @RequestParam("latitude") Double latitude,
            @RequestParam("longitude") Double longitude) {
        Long pharmacyId = SecurityUtils.getAuthenticatedPharmacyId();
        Pharmacy pharmacy = profileService.updatePharmacyLocation(pharmacyId, latitude, longitude);
        return ResponseEntity.ok(pharmacy);
    }

}
