package com.smarthealthcare.backend.treatment.controller;

import com.smarthealthcare.backend.exception.ResourceNotFoundException;
import com.smarthealthcare.backend.treatment.dto.AdherenceAnalyticsResponse;
import com.smarthealthcare.backend.treatment.dto.DoseItemResponse;
import com.smarthealthcare.backend.treatment.entity.TreatmentPlan;
import com.smarthealthcare.backend.treatment.service.AdherenceAnalyticsService;
import com.smarthealthcare.backend.treatment.service.TreatmentPlanService;
import com.smarthealthcare.backend.user.entity.User;
import com.smarthealthcare.backend.user.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/treatment-plans")
public class TreatmentPlanController {

    private final TreatmentPlanService planService;
    private final AdherenceAnalyticsService analyticsService;
    private final UserRepository userRepository;

    public TreatmentPlanController(
            TreatmentPlanService planService,
            AdherenceAnalyticsService analyticsService,
            UserRepository userRepository) {

        this.planService = planService;
        this.analyticsService = analyticsService;
        this.userRepository = userRepository;
    }

    @PostMapping("/generate/{prescriptionId}")
    public ResponseEntity<TreatmentPlan> generatePlan(@PathVariable Long prescriptionId) {
        TreatmentPlan plan = planService.generatePlanFromPrescription(prescriptionId);
        return ResponseEntity.ok(plan);
    }

    @GetMapping("/today")
    public ResponseEntity<List<DoseItemResponse>> getTodayDoseChecklist(Authentication authentication) {
        User user = getUserFromAuth(authentication);
        List<DoseItemResponse> checklist = planService.getTodayDoseChecklist(user.getUserId());
        return ResponseEntity.ok(checklist);
    }

    @PostMapping("/doses/{scheduleId}/log")
    public ResponseEntity<DoseItemResponse> logDoseStatus(
            Authentication authentication,
            @PathVariable Long scheduleId,
            @RequestParam(defaultValue = "TAKEN") String status) {

        User user = getUserFromAuth(authentication);
        DoseItemResponse response = planService.logDoseStatus(user.getUserId(), scheduleId, status);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/analytics")
    public ResponseEntity<AdherenceAnalyticsResponse> getAdherenceAnalytics(Authentication authentication) {
        User user = getUserFromAuth(authentication);
        AdherenceAnalyticsResponse analytics = analyticsService.calculateAdherence(user.getUserId());
        return ResponseEntity.ok(analytics);
    }

    private User getUserFromAuth(Authentication authentication) {
        String email = authentication.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Authenticated user not found: " + email));
    }
}
