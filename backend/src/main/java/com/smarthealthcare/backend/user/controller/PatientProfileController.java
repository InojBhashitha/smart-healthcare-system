package com.smarthealthcare.backend.user.controller;

import com.smarthealthcare.backend.exception.ResourceNotFoundException;
import com.smarthealthcare.backend.user.dto.PatientProfileResponse;
import com.smarthealthcare.backend.user.entity.PatientAllergy;
import com.smarthealthcare.backend.user.entity.PatientMedication;
import com.smarthealthcare.backend.user.entity.User;
import com.smarthealthcare.backend.user.repository.PatientAllergyRepository;
import com.smarthealthcare.backend.user.repository.PatientMedicationRepository;
import com.smarthealthcare.backend.user.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/patient/profile")
public class PatientProfileController {

    private final UserRepository userRepository;
    private final PatientAllergyRepository allergyRepository;
    private final PatientMedicationRepository medicationRepository;

    public PatientProfileController(
            UserRepository userRepository,
            PatientAllergyRepository allergyRepository,
            PatientMedicationRepository medicationRepository) {

        this.userRepository = userRepository;
        this.allergyRepository = allergyRepository;
        this.medicationRepository = medicationRepository;
    }

    @GetMapping
    public ResponseEntity<PatientProfileResponse> getProfile(Authentication auth) {
        User user = getUser(auth);

        List<PatientAllergy> allergies = allergyRepository.findByUserUserId(user.getUserId());
        List<PatientMedication> activeMeds = medicationRepository.findByUserUserIdAndIsActiveTrue(user.getUserId());

        List<PatientProfileResponse.AllergyDto> allergyDtos = allergies.stream()
                .map(a -> new PatientProfileResponse.AllergyDto(a.getAllergyId(), a.getAllergenName(), a.getSeverity(), a.getNotes()))
                .collect(Collectors.toList());

        List<PatientProfileResponse.MedicationDto> medDtos = activeMeds.stream()
                .map(m -> new PatientProfileResponse.MedicationDto(m.getMedicationId(), m.getMedicineName(), m.getGenericName(), m.getStrength(), m.getIsActive()))
                .collect(Collectors.toList());

        return ResponseEntity.ok(new PatientProfileResponse(
                user.getUserId(),
                user.getName(),
                user.getEmail(),
                allergyDtos,
                medDtos
        ));
    }

    @PostMapping("/allergies")
    public ResponseEntity<PatientProfileResponse.AllergyDto> addAllergy(
            Authentication auth,
            @RequestBody PatientProfileResponse.AllergyDto req) {

        User user = getUser(auth);

        PatientAllergy allergy = new PatientAllergy(
                user,
                req.getAllergenName(),
                req.getSeverity() != null ? req.getSeverity() : "MODERATE",
                req.getNotes()
        );

        PatientAllergy saved = allergyRepository.save(allergy);
        return ResponseEntity.ok(new PatientProfileResponse.AllergyDto(
                saved.getAllergyId(), saved.getAllergenName(), saved.getSeverity(), saved.getNotes()
        ));
    }

    @DeleteMapping("/allergies/{id}")
    public ResponseEntity<Void> deleteAllergy(@PathVariable Long id) {
        allergyRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/medications")
    public ResponseEntity<PatientProfileResponse.MedicationDto> addMedication(
            Authentication auth,
            @RequestBody PatientProfileResponse.MedicationDto req) {

        User user = getUser(auth);

        PatientMedication med = new PatientMedication(
                user,
                req.getMedicineName(),
                req.getGenericName(),
                req.getStrength(),
                null
        );

        PatientMedication saved = medicationRepository.save(med);
        return ResponseEntity.ok(new PatientProfileResponse.MedicationDto(
                saved.getMedicationId(), saved.getMedicineName(), saved.getGenericName(), saved.getStrength(), saved.getIsActive()
        ));
    }

    @DeleteMapping("/medications/{id}")
    public ResponseEntity<Void> deleteMedication(@PathVariable Long id) {
        medicationRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    private User getUser(Authentication auth) {
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + email));
    }
}
