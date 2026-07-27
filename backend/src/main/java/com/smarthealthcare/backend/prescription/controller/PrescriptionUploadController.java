package com.smarthealthcare.backend.prescription.controller;

import com.smarthealthcare.backend.prescription.dto.UploadPrescriptionResponse;
import com.smarthealthcare.backend.prescription.entity.Prescription;
import com.smarthealthcare.backend.ocr.dto.MedicineInfo;
import com.smarthealthcare.backend.ocr.parser.MedicineParser;
import com.smarthealthcare.backend.ocr.service.OcrService;
import com.smarthealthcare.backend.prescription.service.FileStorageService;
import com.smarthealthcare.backend.prescription.service.PrescriptionMedicineService;
import com.smarthealthcare.backend.prescription.service.PrescriptionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.nio.file.Path;

@RestController
@RequestMapping("/api/prescriptions")
public class PrescriptionUploadController {

    private final FileStorageService fileStorageService;
    private final PrescriptionService prescriptionService;
    private final PrescriptionMedicineService prescriptionMedicineService;
    private final OcrService ocrService;
    private final MedicineParser medicineParser;

    public PrescriptionUploadController(
            FileStorageService fileStorageService,
            PrescriptionService prescriptionService,
            PrescriptionMedicineService prescriptionMedicineService,
            OcrService ocrService,
            MedicineParser medicineParser) {

        this.fileStorageService = fileStorageService;
        this.prescriptionService = prescriptionService;
        this.prescriptionMedicineService = prescriptionMedicineService;
        this.ocrService = ocrService;
        this.medicineParser = medicineParser;
    }

    @PostMapping("/upload")
    public ResponseEntity<UploadPrescriptionResponse> uploadPrescription(
            @RequestParam("file") MultipartFile file) {

        try {

            // Save uploaded image
            Path savedFile = fileStorageService.saveFile(file);

String filename = savedFile.getFileName().toString();

String text = ocrService.extractText(savedFile.toFile());


            // Extract medicines
            List<MedicineInfo> medicines = medicineParser.parse(text);

            // Save prescription
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

            System.out.println("========== OCR TEXT ==========");
            System.out.println(text);

            System.out.println("====== MEDICINES FOUND ======");

            for (MedicineInfo medicine : medicines) {
                System.out.println(
                        medicine.getName()
                                + " "
                                + medicine.getStrength()
                                + " -> "
                                + medicine.getInstruction()
                );
            }

            UploadPrescriptionResponse response =
                    new UploadPrescriptionResponse(
                            prescription.getPrescriptionId(),
                            filename,
                            prescription.getStatus(),
                            "Prescription uploaded successfully"
                    );

            return ResponseEntity.ok(response);

        } catch (Exception e) {

            e.printStackTrace();

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