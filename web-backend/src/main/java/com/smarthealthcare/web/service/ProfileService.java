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
}
