package com.smarthealthcare.backend.cdss.controller;

import com.smarthealthcare.backend.cdss.dto.CdssSafetyResponse;
import com.smarthealthcare.backend.cdss.service.CdssSafetyEngine;
import com.smarthealthcare.backend.exception.ResourceNotFoundException;
import com.smarthealthcare.backend.prescription.entity.Prescription;
import com.smarthealthcare.backend.prescription.repository.PrescriptionRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/cdss")
public class CdssController {

    private final CdssSafetyEngine cdssSafetyEngine;
    private final PrescriptionRepository prescriptionRepository;

    public CdssController(
            CdssSafetyEngine cdssSafetyEngine,
            PrescriptionRepository prescriptionRepository) {

        this.cdssSafetyEngine = cdssSafetyEngine;
        this.prescriptionRepository = prescriptionRepository;
    }

    @GetMapping("/analyze/{prescriptionId}")
    public ResponseEntity<CdssSafetyResponse> analyzePrescription(@PathVariable Long prescriptionId) {

        Prescription prescription = prescriptionRepository.findWithMedicinesByPrescriptionId(prescriptionId)
                .orElseThrow(() -> new ResourceNotFoundException("Prescription not found with ID: " + prescriptionId));

        CdssSafetyResponse safetyReport = cdssSafetyEngine.evaluatePrescriptionSafety(prescription);

        return ResponseEntity.ok(safetyReport);
    }
}
