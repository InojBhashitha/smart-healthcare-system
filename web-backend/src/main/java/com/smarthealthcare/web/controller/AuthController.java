package com.smarthealthcare.web.controller;

import com.smarthealthcare.web.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.smarthealthcare.web.dto.AuthResponseDto;
import com.smarthealthcare.web.dto.LoginRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@RestController
@RequestMapping("/api/web/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponseDto> login(@RequestBody LoginRequest loginRequest) {
        AuthResponseDto response = authService.authenticate(loginRequest.getEmail(), loginRequest.getPassword());
        return ResponseEntity.ok(response);
    }

}
