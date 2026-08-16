package com.smarthealthcare.web.controller;

import com.smarthealthcare.web.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/web/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

}
