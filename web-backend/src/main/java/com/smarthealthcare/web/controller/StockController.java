package com.smarthealthcare.web.controller;

import com.smarthealthcare.web.service.StockService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/web/stocks")
@RequiredArgsConstructor
public class StockController {

    private final StockService stockService;

}
