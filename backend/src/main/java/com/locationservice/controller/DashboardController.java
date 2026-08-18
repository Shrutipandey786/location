package com.locationservice.controller;

import com.locationservice.dto.DashboardResponse;
import com.locationservice.dto.DeviceStatusDto;
import com.locationservice.dto.DeviceStatusUpdateRequest;
import com.locationservice.dto.LocationDto;
import com.locationservice.dto.LocationUpdateRequest;
import com.locationservice.entity.User;
import com.locationservice.service.DashboardService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/dashboard")
    public ResponseEntity<DashboardResponse> getDashboard(@AuthenticationPrincipal User user) {
        DashboardResponse response = dashboardService.getDashboard(user);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/location/update")
    public ResponseEntity<LocationDto> updateLocation(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody LocationUpdateRequest request) {
        LocationDto response = dashboardService.updateLocation(user, request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/device/status")
    public ResponseEntity<DeviceStatusDto> updateDeviceStatus(
            @AuthenticationPrincipal User user,
            @RequestBody DeviceStatusUpdateRequest request) {
        DeviceStatusDto response = dashboardService.updateDeviceStatus(user, request);
        return ResponseEntity.ok(response);
    }
}
