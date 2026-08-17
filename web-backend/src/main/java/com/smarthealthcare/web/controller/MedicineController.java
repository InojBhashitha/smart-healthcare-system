package com.smarthealthcare.web.controller;

import com.smarthealthcare.web.service.MedicineService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.smarthealthcare.web.entity.Medicine;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import java.util.List;

@RestController
@RequestMapping("/api/web/medicines")
@RequiredArgsConstructor
public class MedicineController {

    private final MedicineService medicineService;

    @GetMapping
    public ResponseEntity<List<Medicine>> getMedicines(@RequestParam(value = "query", required = false) String query) {
        if (query != null && !query.trim().isEmpty()) {
            return ResponseEntity.ok(medicineService.searchMedicines(query));
        }
        return ResponseEntity.ok(medicineService.getAllMedicines());
    }

}
