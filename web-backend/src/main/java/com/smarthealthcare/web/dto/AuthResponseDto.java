package com.smarthealthcare.web.dto;

import com.smarthealthcare.web.entity.Role;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuthResponseDto {
    private String token;
    private Long userId;
    private String email;
    private String name;
    private Role role;
    private Long pharmacyId;
}
