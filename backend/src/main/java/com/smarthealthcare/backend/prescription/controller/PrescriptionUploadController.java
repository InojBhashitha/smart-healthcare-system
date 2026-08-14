package com.smarthealthcare.backend.prescription.controller;

import com.smarthealthcare.backend.ocr.dto.AiPrescriptionResponse;
import com.smarthealthcare.backend.ocr.dto.MedicineInfo;
import com.smarthealthcare.backend.ocr.parser.MedicineParser;
import com.smarthealthcare.backend.ocr.service.AiServiceClient;
import com.smarthealthcare.backend.ocr.service.OcrService;
import com.smarthealthcare.backend.prescription.dto.UploadPrescriptionResponse;
import com.smarthealthcare.backend.prescription.entity.Prescription;
import com.smarthealthcare.backend.prescription.service.FileStorageService;
import com.smarthealthcare.backend.prescription.service.PrescriptionMedicineService;
import com.smarthealthcare.backend.prescription.service.PrescriptionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/prescriptions")
public class PrescriptionUploadController {

    private final FileStorageService fileStorageService;
    private final PrescriptionService prescriptionService;
    private final PrescriptionMedicineService prescriptionMedicineService;
    private final OcrService ocrService;
    private final MedicineParser medicineParser;
    private final AiServiceClient aiServiceClient;

    public PrescriptionUploadController(
            FileStorageService fileStorageService,
            PrescriptionService prescriptionService,
            PrescriptionMedicineService prescriptionMedicineService,
            OcrService ocrService,
            MedicineParser medicineParser,
            AiServiceClient aiServiceClient) {

        this.fileStorageService = fileStorageService;
        this.prescriptionService = prescriptionService;
        this.prescriptionMedicineService = prescriptionMedicineService;
        this.ocrService = ocrService;
        this.medicineParser = medicineParser;
        this.aiServiceClient = aiServiceClient;
    }

    @PostMapping("/upload")
    public ResponseEntity<UploadPrescriptionResponse> uploadPrescription(
            @RequestParam("file") MultipartFile file) {

        try {

            // Save uploaded image
            Path savedFile = fileStorageService.saveFile(file);
            String filename = savedFile.getFileName().toString();
            File imageFile = savedFile.toFile();

            String text;
            List<MedicineInfo> medicines = new ArrayList<>();

            // Check if Python AI Microservice is available
            if (aiServiceClient.isHealthy()) {
                log.info("Processing prescription via Python AI Microservice...");
                AiPrescriptionResponse aiResponse = aiServiceClient.processPrescription(imageFile);

                text = aiResponse.getRawText();
                if (aiResponse.getMedicines() != null) {
                    for (AiPrescriptionResponse.AiMedicineMatch m : aiResponse.getMedicines()) {
                        medicines.add(new MedicineInfo(
                                m.getName(),
                                m.getStrength(),
                                m.getInstruction(),
                                m.getConfidence()
                        ));
                    }
                }
            } else {
                log.warn("Python AI Service unavailable. Falling back to local Tesseract OCR.");
                text = ocrService.extractText(imageFile);
                medicines = medicineParser.parse(text);
            }

            // Save prescription record
            Prescription prescription =
                    prescriptionService.savePrescription(
                            filename,
                            text,
                            medicines.size()
                    );

            // Save extracted medicines
            prescriptionMedicineService.saveMedicines(
                    prescription,
                    medicines
            );

            log.info("Prescription uploaded — ID: {}, Medicines found: {}",
                    prescription.getPrescriptionId(), medicines.size());

            UploadPrescriptionResponse response =
                    new UploadPrescriptionResponse(
                            prescription.getPrescriptionId(),
                            filename,
                            prescription.getStatus(),
                            "Prescription uploaded and processed successfully"
                    );

            return ResponseEntity.ok(response);

        } catch (Exception e) {

            log.error("Prescription upload failed", e);

            return ResponseEntity.internalServerError().body(
                    new UploadPrescriptionResponse(
                            null,
                            null,
                            "FAILED",
                            "Upload failed: " + e.getMessage()
                    )
            );
        }
    }
}