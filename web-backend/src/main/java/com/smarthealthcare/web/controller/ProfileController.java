package com.smarthealthcare.web.controller;

import com.smarthealthcare.web.service.ProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/web/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final ProfileService profileService;

}
