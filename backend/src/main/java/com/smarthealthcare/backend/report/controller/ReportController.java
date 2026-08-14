package com.smarthealthcare.backend.report.controller;

import com.smarthealthcare.backend.exception.ResourceNotFoundException;
import com.smarthealthcare.backend.report.service.PdfReportService;
import com.smarthealthcare.backend.user.entity.User;
import com.smarthealthcare.backend.user.repository.UserRepository;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.ByteArrayInputStream;

@RestController
@RequestMapping("/api/reports")
public class ReportController {

    private final PdfReportService pdfReportService;
    private final UserRepository userRepository;

    public ReportController(PdfReportService pdfReportService, UserRepository userRepository) {
        this.pdfReportService = pdfReportService;
        this.userRepository = userRepository;
    }

    @GetMapping(value = "/pdf/health-summary", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<InputStreamResource> downloadHealthSummaryPdf(Authentication authentication) {
        User user = getUserFromAuth(authentication);
        ByteArrayInputStream bis = pdfReportService.generateHealthSummaryPdf(user);

        HttpHeaders headers = new HttpHeaders();
        headers.add("Content-Disposition", "inline; filename=medical_health_summary.pdf");

        return ResponseEntity
                .ok()
                .headers(headers)
                .contentType(MediaType.APPLICATION_PDF)
                .body(new InputStreamResource(bis));
    }

    private User getUserFromAuth(Authentication authentication) {
        String email = authentication.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + email));
    }
}
