package com.smarthealthcare.backend.ocr.service;

import com.smarthealthcare.backend.ocr.dto.AiPrescriptionResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.io.File;

/**
 * HTTP client for the Python AI microservice.
 * Sends prescription images and receives structured AI processing results.
 */
@Slf4j
@Service
public class AiServiceClient {

    @Value("${ai-service.url}")
    private String aiServiceUrl;

    private final RestTemplate restTemplate;

    public AiServiceClient() {
        this.restTemplate = new RestTemplate();
    }

    /**
     * Send a prescription image to the AI service for processing.
     *
     * @param imageFile the prescription image file
     * @return AI processing result with quality report, OCR text, and matched medicines
     */
    public AiPrescriptionResponse processPrescription(File imageFile) {

        String url = aiServiceUrl + "/api/ai/process-prescription";

        log.info("Calling AI service: {} with file: {}",
                url, imageFile.getName());

        // Build multipart request
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);

        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("file", new FileSystemResource(imageFile));

        HttpEntity<MultiValueMap<String, Object>> requestEntity =
                new HttpEntity<>(body, headers);

        ResponseEntity<AiPrescriptionResponse> response =
                restTemplate.exchange(
                        url,
                        HttpMethod.POST,
                        requestEntity,
                        AiPrescriptionResponse.class
                );

        AiPrescriptionResponse result = response.getBody();

        if (result != null) {
            log.info("AI service response — medicines: {}, text length: {}",
                    result.getMedicinesFound(),
                    result.getRawText() != null
                            ? result.getRawText().length() : 0);
        }

        return result;
    }

    /**
     * Check if the AI service is healthy and reachable.
     *
     * @return true if the service responds with 200
     */
    public boolean isHealthy() {
        try {
            String url = aiServiceUrl + "/health";
            ResponseEntity<String> response =
                    restTemplate.getForEntity(url, String.class);
            return response.getStatusCode() == HttpStatus.OK;
        } catch (Exception e) {
            log.warn("AI service health check failed: {}", e.getMessage());
            return false;
        }
    }
}
