package com.smarthealthcare.web.controller;

import com.smarthealthcare.web.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.smarthealthcare.web.security.SecurityUtils;
import com.smarthealthcare.web.dto.DashboardStatsDto;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;

@RestController
@RequestMapping("/api/web/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/stats")
    public ResponseEntity<DashboardStatsDto> getStats() {
        Long pharmacyId = SecurityUtils.getAuthenticatedPharmacyId();
        DashboardStatsDto stats = dashboardService.getDashboardStats(pharmacyId);
        return ResponseEntity.ok(stats);
    }

}
