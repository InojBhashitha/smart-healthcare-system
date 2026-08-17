package com.smarthealthcare.backend.medicine.service;

import com.smarthealthcare.backend.medicine.dto.MedicineValidationResponse;
import com.smarthealthcare.backend.medicine.entity.Medicine;
import com.smarthealthcare.backend.medicine.repository.MedicineRepository;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class MedicineValidationService {

    private final MedicineRepository repository;

    public MedicineValidationService(
            MedicineRepository repository) {

        this.repository = repository;
    }

    public MedicineValidationResponse validate(String medicineName) {

        java.util.List<Medicine> generic =
                repository.findByGenericNameIgnoreCase(medicineName);

        if (!generic.isEmpty()) {

            Medicine medicine = generic.get(0);

            return new MedicineValidationResponse(
                    true,
                    medicine.getMedicineId(),
                    "GENERIC",
                    medicine.getGenericName(),
                    medicine.getBrandName()
            );
        }

        java.util.List<Medicine> brand =
                repository.findByBrandNameIgnoreCase(medicineName);

        if (!brand.isEmpty()) {

            Medicine medicine = brand.get(0);

            return new MedicineValidationResponse(
                    true,
                    medicine.getMedicineId(),
                    "BRAND",
                    medicine.getGenericName(),
                    medicine.getBrandName()
            );
        }

        return new MedicineValidationResponse(
                false,
                null,
                "NONE",
                null,
                null
        );
    }
    public Medicine findMatchingMedicine(String medicineName) {
        if (medicineName == null || medicineName.isBlank()) {
            return null;
        }
        java.util.List<Medicine> generics = repository.findByGenericNameIgnoreCase(medicineName.trim());
        if (!generics.isEmpty()) {
            return generics.get(0);
        }
        java.util.List<Medicine> brands = repository.findByBrandNameIgnoreCase(medicineName.trim());
        if (!brands.isEmpty()) {
            return brands.get(0);
        }
        return null;
    }
}