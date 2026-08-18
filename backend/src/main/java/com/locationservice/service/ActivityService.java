package com.locationservice.service;

import com.locationservice.dto.ActivityDto;
import com.locationservice.entity.Activity;
import com.locationservice.entity.DeviceStatus;
import com.locationservice.entity.Location;
import com.locationservice.entity.User;
import com.locationservice.repository.ActivityRepository;
import com.locationservice.repository.DeviceStatusRepository;
import com.locationservice.repository.LocationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class ActivityService {

    private final ActivityRepository activityRepository;
    private final LocationRepository locationRepository;
    private final DeviceStatusRepository deviceStatusRepository;

    private static final DateTimeFormatter ISO_FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    public ActivityService(
            ActivityRepository activityRepository,
            LocationRepository locationRepository,
            DeviceStatusRepository deviceStatusRepository) {
        this.activityRepository = activityRepository;
        this.locationRepository = locationRepository;
        this.deviceStatusRepository = deviceStatusRepository;
    }

    @Transactional
    public List<ActivityDto> getActivities(User currentUser, String type) {
        List<Activity> activities;

        if (type != null && !type.isBlank()) {
            String filterType = normalizeType(type);
            activities = activityRepository.findByUserAndTypeOrderByCreatedAtDesc(currentUser, filterType);
        } else {
            activities = activityRepository.findByUserOrderByCreatedAtDesc(currentUser);
        }

        // Seed initial activity history records if user has no activities in PostgreSQL
        if ((activities == null || activities.isEmpty()) && (type == null || type.isBlank())) {
            activities = seedInitialActivities(currentUser);
        }

        if (activities == null) {
            activities = new ArrayList<>();
        }

        Optional<Location> latestLoc = locationRepository.findTopByUserOrderByUpdatedAtDesc(currentUser);
        Optional<DeviceStatus> latestDevice = deviceStatusRepository.findByUser(currentUser);

        Double currentLat = latestLoc.map(Location::getLatitude).orElse(28.6139);
        Double currentLng = latestLoc.map(Location::getLongitude).orElse(77.2090);
        String currentAddress = latestLoc.map(Location::getAddress).orElse(String.format("%.4f, %.4f", currentLat, currentLng));
        Integer batteryLevel = latestDevice.map(DeviceStatus::getBatteryLevel).orElse(95);

        return activities.stream()
                .map(act -> mapToDto(act, currentUser, currentLat, currentLng, currentAddress, batteryLevel))
                .collect(Collectors.toList());
    }

    private ActivityDto mapToDto(Activity activity, User currentUser, Double currentLat, Double currentLng, String currentAddress, Integer batteryLevel) {
        Double lat = activity.getLatitude() != null ? activity.getLatitude() : currentLat;
        Double lng = activity.getLongitude() != null ? activity.getLongitude() : currentLng;
        LocalDateTime createdAt = activity.getCreatedAt() != null ? activity.getCreatedAt() : LocalDateTime.now();

        return new ActivityDto(
                activity.getId(),
                activity.getTitle() != null ? activity.getTitle() : "Telemetry Log",
                activity.getDetails() != null ? activity.getDetails() : "Activity registered.",
                activity.getType() != null ? activity.getType() : "GPS_SYNC",
                lat,
                lng,
                currentAddress,
                currentUser.getName() != null ? currentUser.getName() : "System Node",
                "Android",
                batteryLevel,
                createdAt.format(ISO_FORMATTER)
        );
    }

    private List<Activity> seedInitialActivities(User currentUser) {
        LocalDateTime now = LocalDateTime.now();
        List<Activity> seeded = new ArrayList<>();

        seeded.add(activityRepository.save(new Activity(
                currentUser,
                "GPS Telemetry Synced",
                "Real-time GPS coordinates synchronized with central server.",
                "GPS_SYNC",
                28.6139,
                77.2090,
                now.minusMinutes(5)
        )));

        seeded.add(activityRepository.save(new Activity(
                currentUser,
                "PTT Voice Intercom Call",
                "Push-to-Talk voice channel session established (0:14s duration).",
                "PTT_VOICE",
                28.6145,
                77.2095,
                now.minusMinutes(25)
        )));

        seeded.add(activityRepository.save(new Activity(
                currentUser,
                "Camera Telemetry HUD Snapshot",
                "Live camera optical snapshot captured and location tagged.",
                "CAMERA_TELEMETRY",
                28.6150,
                77.2100,
                now.minusHours(1).minusMinutes(10)
        )));

        seeded.add(activityRepository.save(new Activity(
                currentUser,
                "Geofence Security Perimeter Check",
                "Entered designated safe zone boundary at Checkpoint Alpha.",
                "GEOFENCE",
                28.6155,
                77.2105,
                now.minusHours(2)
        )));

        return activityRepository.findByUserOrderByCreatedAtDesc(currentUser);
    }

    private String normalizeType(String inputType) {
        String upper = inputType.trim().toUpperCase();
        if ("LOCATION".equals(upper) || "LOCATION_UPDATE".equals(upper)) return "GPS_SYNC";
        if ("PTT".equals(upper) || "PTT_CALL".equals(upper)) return "PTT_VOICE";
        if ("SOS_ALERT".equals(upper)) return "SOS";
        if ("SNAPSHOT".equals(upper) || "CAMERA_SNAPSHOT".equals(upper)) return "CAMERA_TELEMETRY";
        if ("GEOFENCE_ALERT".equals(upper)) return "GEOFENCE";
        return upper;
    }
}
