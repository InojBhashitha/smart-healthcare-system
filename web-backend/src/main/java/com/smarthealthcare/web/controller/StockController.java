package com.smarthealthcare.web.controller;

import com.smarthealthcare.web.service.StockService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.smarthealthcare.web.security.SecurityUtils;
import com.smarthealthcare.web.dto.StockDto;
import com.smarthealthcare.web.entity.PharmacyStock;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/web/stocks")
@RequiredArgsConstructor
public class StockController {

    private final StockService stockService;

    @GetMapping
    public ResponseEntity<List<StockDto>> getStockByPharmacy() {
        Long pharmacyId = SecurityUtils.getAuthenticatedPharmacyId();
        List<StockDto> dtoList = stockService.getStockByPharmacy(pharmacyId).stream()
                .map(stockService::convertToDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtoList);
    }

    @PostMapping
    public ResponseEntity<StockDto> addStock(
            @RequestParam("medicineId") Integer medicineId,
            @RequestBody PharmacyStock stockData) {
        Long pharmacyId = SecurityUtils.getAuthenticatedPharmacyId();
        PharmacyStock saved = stockService.addStock(pharmacyId, medicineId, stockData);
        return ResponseEntity.ok(stockService.convertToDto(saved));
    }

    @PutMapping("/{stockId}")
    public ResponseEntity<StockDto> updateStock(
            @PathVariable("stockId") Long stockId,
            @RequestBody PharmacyStock stockData) {
        Long pharmacyId = SecurityUtils.getAuthenticatedPharmacyId();
        PharmacyStock updated = stockService.updateStock(pharmacyId, stockId, stockData);
        return ResponseEntity.ok(stockService.convertToDto(updated));
    }

    @DeleteMapping("/{stockId}")
    public ResponseEntity<Void> deleteStock(
            @PathVariable("stockId") Long stockId) {
        Long pharmacyId = SecurityUtils.getAuthenticatedPharmacyId();
        stockService.deleteStock(pharmacyId, stockId);
        return ResponseEntity.noContent().build();
    }

}
