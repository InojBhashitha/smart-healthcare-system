package com.smarthealthcare.backend.prescription.service;

import com.smarthealthcare.backend.medicine.entity.Medicine;
import com.smarthealthcare.backend.prescription.entity.Prescription;
import com.smarthealthcare.backend.prescription.entity.PrescriptionMedicine;
import com.smarthealthcare.backend.ocr.dto.MedicineInfo;
import com.smarthealthcare.backend.prescription.repository.PrescriptionMedicineRepository;
import org.springframework.stereotype.Service;
import com.smarthealthcare.backend.medicine.service.MedicineValidationService;


import java.util.List;

@Service
public class PrescriptionMedicineService {

    private final PrescriptionMedicineRepository repository;
    private final MedicineValidationService validationService;

    public PrescriptionMedicineService(
            PrescriptionMedicineRepository repository,
            MedicineValidationService validationService) {

        this.repository = repository;
        this.validationService = validationService;
    }

    public void saveMedicines(
            Prescription prescription,
            List<MedicineInfo> medicines) {

        for (MedicineInfo medicineInfo : medicines) {

            PrescriptionMedicine medicine =
                    new PrescriptionMedicine();

            // Link to the prescription
            medicine.setPrescription(prescription);

            // Set display name: Use AI matched brand name ONLY if confidence >= 70.0%
            double confidence = medicineInfo.getConfidence();
            String brandName = medicineInfo.getMatchedBrandName();
            if (confidence >= 70.0 && brandName != null && !brandName.trim().isEmpty()) {
                medicine.setMedicineName(brandName.trim());
            } else {
                medicine.setMedicineName(medicineInfo.getName() != null ? medicineInfo.getName().trim() : "");
            }

            medicine.setStrength(medicineInfo.getStrength() != null ? medicineInfo.getStrength() : "");
            medicine.setInstruction(medicineInfo.getInstruction() != null ? medicineInfo.getInstruction() : "");
            medicine.setVerified(false);
            medicine.setConfidence(confidence);

            // Link to master PostgreSQL drug entity ONLY if AI confidence >= 70.0%
            Medicine matchedMedicine = null;
            if (confidence >= 70.0) {
                if (medicineInfo.getMatchedBrandName() != null) {
                    matchedMedicine = validationService.findMatchingMedicine(medicineInfo.getMatchedBrandName());
                }
                if (matchedMedicine == null && medicineInfo.getMatchedGenericName() != null) {
                    matchedMedicine = validationService.findMatchingMedicine(medicineInfo.getMatchedGenericName());
                }
                if (matchedMedicine == null) {
                    matchedMedicine = validationService.findMatchingMedicine(medicineInfo.getName());
                }
            }

            // Save relationship if found
            medicine.setMedicine(matchedMedicine);

            repository.save(medicine);
        }
    }
}