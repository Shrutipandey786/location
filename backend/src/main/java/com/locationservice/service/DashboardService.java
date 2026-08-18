package com.locationservice.service;

import com.locationservice.dto.ActivityDto;
import com.locationservice.dto.DashboardResponse;
import com.locationservice.dto.DeviceStatusDto;
import com.locationservice.dto.DeviceStatusUpdateRequest;
import com.locationservice.dto.LocationDto;
import com.locationservice.dto.LocationUpdateRequest;
import com.locationservice.dto.UserDto;
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
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class DashboardService {

    private final LocationRepository locationRepository;
    private final DeviceStatusRepository deviceStatusRepository;
    private final ActivityRepository activityRepository;

    private static final DateTimeFormatter ISO_FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    public DashboardService(
            LocationRepository locationRepository,
            DeviceStatusRepository deviceStatusRepository,
            ActivityRepository activityRepository) {
        this.locationRepository = locationRepository;
        this.deviceStatusRepository = deviceStatusRepository;
        this.activityRepository = activityRepository;
    }

    @Transactional(readOnly = true)
    public DashboardResponse getDashboard(User user) {
        UserDto userDto = new UserDto(user.getId(), user.getName(), user.getEmail(), user.getRole());

        Optional<Location> locationOpt = locationRepository.findTopByUserOrderByUpdatedAtDesc(user);
        LocationDto locationDto = locationOpt.map(this::mapToLocationDto).orElse(null);

        Optional<DeviceStatus> deviceStatusOpt = deviceStatusRepository.findByUser(user);
        DeviceStatusDto deviceStatusDto = deviceStatusOpt.map(this::mapToDeviceStatusDto).orElse(null);

        List<Activity> activities = activityRepository.findByUserOrderByCreatedAtDesc(user);
        List<ActivityDto> activityDtos = activities.stream()
                .map(this::mapToActivityDto)
                .collect(Collectors.toList());

        return new DashboardResponse(userDto, locationDto, deviceStatusDto, activityDtos);
    }

    @Transactional
    public LocationDto updateLocation(User user, LocationUpdateRequest request) {
        LocalDateTime now = LocalDateTime.now();

        Location location = locationRepository.findTopByUserOrderByUpdatedAtDesc(user)
                .orElse(new Location());

        location.setUser(user);
        location.setLatitude(request.getLatitude());
        location.setLongitude(request.getLongitude());
        location.setAddress(request.getAddress() != null && !request.getAddress().isBlank() 
                ? request.getAddress() 
                : String.format("%.4f, %.4f", request.getLatitude(), request.getLongitude()));
        location.setUpdatedAt(now);

        Location savedLocation = locationRepository.save(location);

        // Record Activity
        Activity activity = new Activity(
                user,
                "Live GPS Sync",
                "Coordinates updated to " + String.format("%.4f, %.4f", request.getLatitude(), request.getLongitude()),
                "LOCATION_UPDATE",
                request.getLatitude(),
                request.getLongitude(),
                now
        );
        activityRepository.save(activity);

        return mapToLocationDto(savedLocation);
    }

    @Transactional
    public DeviceStatusDto updateDeviceStatus(User user, DeviceStatusUpdateRequest request) {
        LocalDateTime now = LocalDateTime.now();

        DeviceStatus status = deviceStatusRepository.findByUser(user)
                .orElse(new DeviceStatus(user, true, true, 100, "Active & Broadcast Mode On", now));

        if (request.getBatteryLevel() != null) {
            status.setBatteryLevel(request.getBatteryLevel());
        }
        if (request.getOnline() != null) {
            status.setOnline(request.getOnline());
        }
        if (request.getIsBroadcasting() != null) {
            status.setIsBroadcasting(request.getIsBroadcasting());
        }
        if (request.getStatusMessage() != null && !request.getStatusMessage().isBlank()) {
            status.setStatusMessage(request.getStatusMessage());
        } else {
            status.setStatusMessage(status.getOnline() 
                    ? (status.getIsBroadcasting() ? "Active & Broadcast Mode On" : "Active (Broadcasting Off)") 
                    : "Offline");
        }
        status.setUpdatedAt(now);

        DeviceStatus savedStatus = deviceStatusRepository.save(status);

        // Record Activity
        Activity activity = new Activity(
                user,
                "Device Status Updated",
                "Battery: " + savedStatus.getBatteryLevel() + "%, Status: " + (savedStatus.getOnline() ? "Online" : "Offline"),
                "STATUS_CHANGE",
                null,
                null,
                now
        );
        activityRepository.save(activity);

        return mapToDeviceStatusDto(savedStatus);
    }

    private LocationDto mapToLocationDto(Location loc) {
        return new LocationDto(
                loc.getLatitude(),
                loc.getLongitude(),
                loc.getAddress(),
                loc.getUpdatedAt() != null ? loc.getUpdatedAt().format(ISO_FORMATTER) : null
        );
    }

    private DeviceStatusDto mapToDeviceStatusDto(DeviceStatus ds) {
        return new DeviceStatusDto(
                ds.getOnline(),
                ds.getIsBroadcasting(),
                ds.getBatteryLevel(),
                ds.getStatusMessage(),
                ds.getUpdatedAt() != null ? ds.getUpdatedAt().format(ISO_FORMATTER) : null
        );
    }

    private ActivityDto mapToActivityDto(Activity act) {
        return new ActivityDto(
                act.getId(),
                act.getTitle(),
                act.getDetails(),
                act.getType(),
                act.getLatitude(),
                act.getLongitude(),
                act.getCreatedAt() != null ? act.getCreatedAt().format(ISO_FORMATTER) : null
        );
    }
}
