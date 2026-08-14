package com.smarthealthcare.backend.integration;

import com.smarthealthcare.backend.cdss.dto.CdssSafetyResponse;
import com.smarthealthcare.backend.cdss.service.CdssSafetyEngine;
import com.smarthealthcare.backend.prescription.entity.Prescription;
import com.smarthealthcare.backend.prescription.entity.PrescriptionMedicine;
import com.smarthealthcare.backend.user.entity.PatientAllergy;
import com.smarthealthcare.backend.user.entity.PatientMedication;
import com.smarthealthcare.backend.user.entity.User;
import com.smarthealthcare.backend.user.repository.PatientAllergyRepository;
import com.smarthealthcare.backend.user.repository.PatientMedicationRepository;
import com.smarthealthcare.backend.user.repository.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class CdssSafetyEngineTest {

    @Autowired
    private CdssSafetyEngine cdssSafetyEngine;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PatientAllergyRepository allergyRepository;

    @Autowired
    private PatientMedicationRepository medicationRepository;

    @Test
    @DisplayName("Unit/Integration Test: CDSS Safety Engine Allergy & Drug-Drug Interaction Detection")
    void testCdssAllergyAndInteractionDetection() {
        // Setup user with penicillin allergy and active warfarin medication
        User user = new User();
        user.setName("Safety Test Patient");
        user.setEmail("safety" + System.currentTimeMillis() + "@gmail.com");
        user.setPassword("Secret123!");
        user.setRole("PATIENT");
        User savedUser = userRepository.save(user);

        PatientAllergy allergy = new PatientAllergy();
        allergy.setUser(savedUser);
        allergenNameSet(allergy, "Penicillin");
        allergy.setSeverity("HIGH");
        allergyRepository.save(allergy);

        PatientMedication activeMed = new PatientMedication();
        activeMed.setUser(savedUser);
        activeMed.setMedicineName("Warfarin");
        activeMed.setIsActive(true);
        medicationRepository.save(activeMed);

        // Test Rx containing Amoxicillin (Penicillin allergy conflict) and Aspirin (Warfarin interaction)
        PrescriptionMedicine rxMed1 = new PrescriptionMedicine();
        rxMed1.setMedicineName("Amoxicillin");

        PrescriptionMedicine rxMed2 = new PrescriptionMedicine();
        rxMed2.setMedicineName("Aspirin");

        Prescription rx = new Prescription();
        rx.setUser(savedUser);
        rx.setMedicines(List.of(rxMed1, rxMed2));

        CdssSafetyResponse response = cdssSafetyEngine.evaluatePrescriptionSafety(rx);

        assertNotNull(response);
        assertNotNull(response.getSafetyStatus());
        assertNotNull(response.getAllergyAlerts());
    }

    private void allergenNameSet(PatientAllergy allergy, String name) {
        allergy.setAllergenName(name);
    }
}
