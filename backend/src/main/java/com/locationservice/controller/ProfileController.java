package com.locationservice.controller;

import com.locationservice.dto.ProfileResponse;
import com.locationservice.dto.TelemetryResponse;
import com.locationservice.dto.UserSettingsDto;
import com.locationservice.entity.User;
import com.locationservice.service.ProfileService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class ProfileController {

    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping("/profile")
    public ResponseEntity<ProfileResponse> getProfile(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(profileService.getProfile(user));
    }

    @GetMapping("/device/telemetry")
    public ResponseEntity<TelemetryResponse> getDeviceTelemetry(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(profileService.getDeviceTelemetry(user));
    }

    @GetMapping("/settings")
    public ResponseEntity<UserSettingsDto> getSettings(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(profileService.getUserSettings(user));
    }

    @PutMapping("/settings")
    public ResponseEntity<UserSettingsDto> updateSettings(
            @AuthenticationPrincipal User user,
            @RequestBody UserSettingsDto dto) {
        return ResponseEntity.ok(profileService.updateUserSettings(user, dto));
    }
}
