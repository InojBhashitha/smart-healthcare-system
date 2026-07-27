package com.smarthealthcare.backend.prescription.service;

import com.smarthealthcare.backend.prescription.dto.PrescriptionMedicineUpdateResponse;
import com.smarthealthcare.backend.prescription.entity.PrescriptionMedicine;
import com.smarthealthcare.backend.prescription.repository.PrescriptionMedicineRepository;
import org.springframework.stereotype.Service;

import java.util.Objects;

@Service
public class PrescriptionMedicineManagementService {

    private final PrescriptionMedicineRepository repository;

    public PrescriptionMedicineManagementService(
            PrescriptionMedicineRepository repository) {

        this.repository = repository;
    }

    public PrescriptionMedicineUpdateResponse verifyMedicine(
            Long id,
            Boolean verified) {

        Objects.requireNonNull(id, "Medicine id must not be null");

        PrescriptionMedicine medicine =
                repository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException("Medicine not found"));

        medicine.setVerified(verified);

        PrescriptionMedicine updatedMedicine =
                repository.save(medicine);

        return new PrescriptionMedicineUpdateResponse(
                updatedMedicine.getId(),
                updatedMedicine.getMedicineName(),
                updatedMedicine.getStrength(),
                updatedMedicine.getInstruction(),
                updatedMedicine.getVerified()
        );
    }

    public PrescriptionMedicineUpdateResponse updateMedicine(
        Long id,
        String medicineName,
        String strength,
        String instruction,
        Boolean verified) {

        Objects.requireNonNull(id, "Medicine id must not be null");

        PrescriptionMedicine medicine =
                repository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException("Medicine not found"));

    medicine.setMedicineName(medicineName);
    medicine.setStrength(strength);
    medicine.setInstruction(instruction);
    medicine.setVerified(verified);

    PrescriptionMedicine updatedMedicine =
            repository.save(medicine);

    return new PrescriptionMedicineUpdateResponse(
            updatedMedicine.getId(),
            updatedMedicine.getMedicineName(),
            updatedMedicine.getStrength(),
            updatedMedicine.getInstruction(),
            updatedMedicine.getVerified()
    );
}
}