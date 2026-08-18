package com.locationservice.controller;

import com.locationservice.dto.ActivityDto;
import com.locationservice.entity.User;
import com.locationservice.service.ActivityService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/activities")
public class ActivityController {

    private final ActivityService activityService;

    public ActivityController(ActivityService activityService) {
        this.activityService = activityService;
    }

    @GetMapping
    public ResponseEntity<List<ActivityDto>> getActivities(
            @AuthenticationPrincipal User user,
            @RequestParam(name = "type", required = false) String type) {
        List<ActivityDto> activities = activityService.getActivities(user, type);
        return ResponseEntity.ok(activities);
    }
}
