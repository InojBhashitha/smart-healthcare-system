package com.smarthealthcare.web.service;

import com.smarthealthcare.web.dto.AuthResponseDto;
import com.smarthealthcare.web.entity.User;
import com.smarthealthcare.web.entity.Role;
import com.smarthealthcare.web.exception.UserNotFoundException;
import com.smarthealthcare.web.exception.InactiveUserException;
import com.smarthealthcare.web.exception.UnauthorizedRoleException;
import com.smarthealthcare.web.repository.UserRepository;
import com.smarthealthcare.web.security.JwtService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional(readOnly = true)
    public AuthResponseDto authenticate(String email, String password) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("User not found with email: " + email));

        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new BadCredentialsException("Invalid password");
        }

        if (Boolean.FALSE.equals(user.getEnabled())) {
            throw new InactiveUserException("User account is disabled.");
        }

        if (user.getRole() != Role.PHARMACIST) {
            throw new UnauthorizedRoleException("Access denied. Only pharmacists can access the Web Dashboard.");
        }

        String token = jwtService.generateToken(user);

        return AuthResponseDto.builder()
                .token(token)
                .userId(user.getUserId())
                .email(user.getEmail())
                .name(user.getName())
                .role(user.getRole())
                .pharmacyId(user.getPharmacy() != null ? user.getPharmacy().getPharmacyId() : null)
                .build();
    }
}
