package com.smarthealthcare.backend.ocr.controller;

import com.smarthealthcare.backend.ocr.dto.MedicineInfo;
import com.smarthealthcare.backend.ocr.dto.OcrResponse;
import com.smarthealthcare.backend.ocr.parser.MedicineParser;
import com.smarthealthcare.backend.ocr.service.OcrService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.util.List;
import java.util.Objects;

@RestController
@RequestMapping("/api/ocr")
public class OcrController {

    private final OcrService ocrService;
    private final MedicineParser medicineParser;

    public OcrController(
            OcrService ocrService,
            MedicineParser medicineParser) {

        this.ocrService = ocrService;
        this.medicineParser = medicineParser;
    }

    @PostMapping("/test")
    public ResponseEntity<OcrResponse> testOcr(
            @RequestParam("file") MultipartFile file) {

        try {

            File tempFile = Objects.requireNonNull(File.createTempFile("ocr_", ".png"));

            file.transferTo(tempFile);

            String text = ocrService.extractText(tempFile);

            List<MedicineInfo> medicines =
                    medicineParser.parse(text);

            tempFile.delete();

            return ResponseEntity.ok(
                    new OcrResponse(text, medicines)
            );

        } catch (Exception e) {

            return ResponseEntity.internalServerError().body(
                    new OcrResponse(
                            "OCR Failed: " + e.getMessage(),
                            null
                    )
            );
        }
    }
}