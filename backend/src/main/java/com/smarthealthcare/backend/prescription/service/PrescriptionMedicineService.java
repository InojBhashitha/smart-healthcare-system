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

            // OCR data
            medicine.setMedicineName(medicineInfo.getName());
            medicine.setStrength(medicineInfo.getStrength());
            medicine.setInstruction(medicineInfo.getInstruction());
            medicine.setVerified(false);

            // Check if medicine exists in master database using AI-matched generic/brand names first
            Medicine matchedMedicine = null;
            if (medicineInfo.getMatchedBrandName() != null) {
                matchedMedicine = validationService.findMatchingMedicine(medicineInfo.getMatchedBrandName());
            }
            if (matchedMedicine == null && medicineInfo.getMatchedGenericName() != null) {
                matchedMedicine = validationService.findMatchingMedicine(medicineInfo.getMatchedGenericName());
            }
            if (matchedMedicine == null) {
                matchedMedicine = validationService.findMatchingMedicine(medicineInfo.getName());
            }

            // Save relationship if found
            medicine.setMedicine(matchedMedicine);

            repository.save(medicine);
        }
    }
}