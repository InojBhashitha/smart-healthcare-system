package com.smarthealthcare.web.service;

import com.smarthealthcare.web.entity.User;
import com.smarthealthcare.web.entity.Pharmacy;
import com.smarthealthcare.web.exception.UserNotFoundException;
import com.smarthealthcare.web.exception.PharmacyNotFoundException;
import com.smarthealthcare.web.repository.UserRepository;
import com.smarthealthcare.web.repository.PharmacyRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProfileService {

    private final UserRepository userRepository;
    private final PharmacyRepository pharmacyRepository;

    public ProfileService(UserRepository userRepository, PharmacyRepository pharmacyRepository) {
        this.userRepository = userRepository;
        this.pharmacyRepository = pharmacyRepository;
    }

    @Transactional(readOnly = true)
    public User getProfile(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));
    }

    @Transactional
    public Pharmacy updatePharmacyLocation(Long pharmacyId, Double latitude, Double longitude) {
        Pharmacy pharmacy = pharmacyRepository.findById(pharmacyId)
                .orElseThrow(() -> new PharmacyNotFoundException("Pharmacy not found with ID: " + pharmacyId));

        pharmacy.setLatitude(latitude);
        pharmacy.setLongitude(longitude);
        return pharmacyRepository.save(pharmacy);
    }

    @Transactional
    public User updateProfile(Long userId, com.smarthealthcare.web.dto.UpdateProfileRequest request) {
        if (userId == null) {
            throw new IllegalArgumentException("User ID must not be null");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + userId));

        if (request.getEmail() == null || !request.getEmail().contains("@")) {
            throw new IllegalArgumentException("Please enter a valid email address.");
        }
        if (request.getPharmacyName() == null || request.getPharmacyName().trim().isEmpty()) {
            throw new IllegalArgumentException("Pharmacy name is required.");
        }
        if (request.getAddress() == null || request.getAddress().trim().isEmpty()) {
            throw new IllegalArgumentException("Business address is required.");
        }

        if (!user.getEmail().equalsIgnoreCase(request.getEmail())) {
            if (userRepository.findByEmail(request.getEmail().trim().toLowerCase()).isPresent()) {
                throw new IllegalArgumentException("Email is already in use by another account.");
            }
            user.setEmail(request.getEmail().trim().toLowerCase());
        }

        user.setPhone(request.getPhone() != null ? request.getPhone().trim() : null);

        Pharmacy pharmacy = user.getPharmacy();
        if (pharmacy != null) {
            pharmacy.setName(request.getPharmacyName().trim());
            pharmacy.setAddress(request.getAddress().trim());
            if (request.getPhone() != null) {
                pharmacy.setContactNumber(request.getPhone().trim());
                pharmacy.setPhone(request.getPhone().trim());
            } else {
                pharmacy.setContactNumber(null);
                pharmacy.setPhone(null);
            }
            pharmacyRepository.save(pharmacy);
        }

        return userRepository.save(user);
    }
}
