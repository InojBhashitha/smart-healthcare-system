package com.smarthealthcare.backend.user.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class UserResponse {

    private Long userId;

    private String name;

    private String email;

    private String role;

    private Boolean enabled;
}
