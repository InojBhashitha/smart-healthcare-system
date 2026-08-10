package com.smarthealthcare.backend.auth.controller;

import com.smarthealthcare.backend.auth.service.AuthService;
import com.smarthealthcare.backend.auth.dto.AuthResponse;
import com.smarthealthcare.backend.auth.dto.LoginRequest;
import com.smarthealthcare.backend.auth.dto.RegisterRequest;
import com.smarthealthcare.backend.auth.dto.UserProfileResponse;
import com.smarthealthcare.backend.auth.security.CustomUserDetails;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(
            @Valid @RequestBody RegisterRequest request) {

        AuthResponse response = authService.register(request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(
            @Valid @RequestBody LoginRequest request) {

        AuthResponse response = authService.login(request);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/profile")
    public ResponseEntity<UserProfileResponse> profile(
            Authentication authentication) {

        CustomUserDetails userDetails =
                (CustomUserDetails) authentication.getPrincipal();

        UserProfileResponse profile = new UserProfileResponse(
                userDetails.getUser().getName(),
                userDetails.getUser().getEmail(),
                userDetails.getUser().getRole()
        );

        return ResponseEntity.ok(profile);
    }
}