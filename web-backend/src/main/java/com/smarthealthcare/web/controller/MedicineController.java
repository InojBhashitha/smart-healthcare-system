package com.smarthealthcare.web.controller;

import com.smarthealthcare.web.service.MedicineService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/web/medicines")
@RequiredArgsConstructor
public class MedicineController {

    private final MedicineService medicineService;

}
