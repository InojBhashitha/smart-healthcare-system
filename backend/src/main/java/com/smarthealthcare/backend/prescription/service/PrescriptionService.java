package com.smarthealthcare.backend.prescription.service;

import com.smarthealthcare.backend.auth.security.CustomUserDetails;
import com.smarthealthcare.backend.medicine.dto.DrugInteractionResult;
import com.smarthealthcare.backend.prescription.dto.DatabaseMedicineResponse;
import com.smarthealthcare.backend.prescription.dto.PrescriptionDetailsResponse;
import com.smarthealthcare.backend.prescription.dto.PrescriptionMedicineResponse;
import com.smarthealthcare.backend.prescription.dto.PrescriptionSummaryResponse;
import com.smarthealthcare.backend.prescription.entity.Prescription;
import com.smarthealthcare.backend.prescription.entity.PrescriptionMedicine;
import com.smarthealthcare.backend.prescription.repository.PrescriptionRepository;
import com.smarthealthcare.backend.user.entity.User;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import com.smarthealthcare.backend.medicine.service.DrugInteractionService;


import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class PrescriptionService {

    private final PrescriptionRepository prescriptionRepository;
    private final DrugInteractionService drugInteractionService;

    public PrescriptionService(
            PrescriptionRepository prescriptionRepository,
            DrugInteractionService drugInteractionService) {

        this.prescriptionRepository = prescriptionRepository;
        this.drugInteractionService = drugInteractionService;
    }

    public List<PrescriptionSummaryResponse> getAllPrescriptions() {
        // Get current authenticated user
        CustomUserDetails userDetails = (CustomUserDetails) SecurityContextHolder
                .getContext()
                .getAuthentication()
                .getPrincipal();

        User user = userDetails.getUser();

        return prescriptionRepository.findByUserUserIdOrderByUploadedAtDesc(user.getUserId())
                .stream()
                .map(prescription -> new PrescriptionSummaryResponse(
                        prescription.getPrescriptionId(),
                        prescription.getStatus(),
                        prescription.getMedicinesFound(),
                        prescription.getUploadedAt()
                ))
                .collect(Collectors.toList());
    }

    public Prescription savePrescription(
            String imagePath,
            String extractedText,
            int medicinesFound) {

        Prescription prescription = new Prescription();

        // Get current authenticated user
        CustomUserDetails userDetails = (CustomUserDetails) SecurityContextHolder
                .getContext()
                .getAuthentication()
                .getPrincipal();

        User user = userDetails.getUser();

        prescription.setImagePath(imagePath);
        prescription.setExtractedText(extractedText);
        prescription.setMedicinesFound(medicinesFound);
        prescription.setStatus("OCR_COMPLETED");
        prescription.setUploadedAt(LocalDateTime.now());
        prescription.setUser(user);

        return prescriptionRepository.save(prescription);
    }

    public PrescriptionDetailsResponse getPrescription(Long id) {

        Prescription prescription =
                prescriptionRepository
                        .findWithMedicinesByPrescriptionId(id)
                        .orElseThrow(() ->
                                new com.smarthealthcare.backend.exception.ResourceNotFoundException("Prescription not found"));

        PrescriptionDetailsResponse response =
                new PrescriptionDetailsResponse();

        response.setPrescriptionId(prescription.getPrescriptionId());
        response.setImagePath(prescription.getImagePath());
        response.setExtractedText(prescription.getExtractedText());
        response.setMedicinesFound(prescription.getMedicinesFound());
        response.setStatus(prescription.getStatus());
        response.setUploadedAt(prescription.getUploadedAt());

        List<PrescriptionMedicineResponse> medicineResponses =
                prescription.getMedicines()
                        .stream()
                        .map(this::mapMedicine)
                        .collect(Collectors.toList());

        response.setMedicines(medicineResponses);

        // Check drug interactions
        List<String> medicineNames =
                prescription.getMedicines()
                        .stream()
                        .map(medicine -> medicine.getMedicineName())
                        .toList();

        List<DrugInteractionResult> interactions =
                drugInteractionService.checkInteractions(medicineNames);

        response.setDrugInteractions(interactions);

        return response;
    }

    private PrescriptionMedicineResponse mapMedicine(
            PrescriptionMedicine medicine) {

        DatabaseMedicineResponse databaseMedicine = null;

        if (medicine.getMedicine() != null) {

            databaseMedicine = new DatabaseMedicineResponse(
                    medicine.getMedicine().getMedicineId(),
                    medicine.getMedicine().getGenericName(),
                    medicine.getMedicine().getBrandName(),
                    medicine.getMedicine().getCategory(),
                    medicine.getMedicine().getDescription(),
                    medicine.getMedicine().getSideEffects()
            );
        }

        return new PrescriptionMedicineResponse(
                medicine.getId(),
                medicine.getMedicineName(),
                medicine.getStrength(),
                medicine.getInstruction(),
                medicine.getVerified(),
                medicine.getConfidence(),
                databaseMedicine
        );
    }
}