package com.locationservice.service;

import com.locationservice.dto.ProfileResponse;
import com.locationservice.dto.TelemetryResponse;
import com.locationservice.dto.UserSettingsDto;
import com.locationservice.entity.DeviceStatus;
import com.locationservice.entity.Location;
import com.locationservice.entity.User;
import com.locationservice.entity.UserSettings;
import com.locationservice.repository.DeviceStatusRepository;
import com.locationservice.repository.LocationRepository;
import com.locationservice.repository.UserSettingsRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class ProfileService {

    private final LocationRepository locationRepository;
    private final DeviceStatusRepository deviceStatusRepository;
    private final UserSettingsRepository userSettingsRepository;

    public ProfileService(
            LocationRepository locationRepository,
            DeviceStatusRepository deviceStatusRepository,
            UserSettingsRepository userSettingsRepository) {
        this.locationRepository = locationRepository;
        this.deviceStatusRepository = deviceStatusRepository;
        this.userSettingsRepository = userSettingsRepository;
    }

    @Transactional(readOnly = true)
    public ProfileResponse getProfile(User user) {
        return new ProfileResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getRole() != null ? user.getRole() : "USER"
        );
    }

    @Transactional(readOnly = true)
    public TelemetryResponse getDeviceTelemetry(User user) {
        Optional<Location> locOpt = locationRepository.findTopByUserOrderByUpdatedAtDesc(user);
        Optional<DeviceStatus> deviceOpt = deviceStatusRepository.findByUser(user);

        Double latitude = locOpt.map(Location::getLatitude).orElse(28.6139);
        Double longitude = locOpt.map(Location::getLongitude).orElse(77.2090);
        String address = locOpt.map(Location::getAddress).orElse(String.format("%.4f, %.4f", latitude, longitude));
        Integer batteryLevel = deviceOpt.map(DeviceStatus::getBatteryLevel).orElse(95);

        return new TelemetryResponse(
                "Android",
                batteryLevel,
                latitude,
                longitude,
                120.5,
                0.0,
                address,
                18
        );
    }

    @Transactional
    public UserSettingsDto getUserSettings(User user) {
        UserSettings settings = userSettingsRepository.findByUser(user)
                .orElseGet(() -> userSettingsRepository.save(new UserSettings(
                        user, true, true, false, true, false, LocalDateTime.now()
                )));

        return mapToDto(settings);
    }

    @Transactional
    public UserSettingsDto updateUserSettings(User user, UserSettingsDto dto) {
        UserSettings settings = userSettingsRepository.findByUser(user)
                .orElseGet(() -> new UserSettings(user, true, true, false, true, false, LocalDateTime.now()));

        if (dto.getLocationSharing() != null) {
            settings.setLocationSharing(dto.getLocationSharing());
        }
        if (dto.getHighPrecisionGps() != null) {
            settings.setHighPrecisionGps(dto.getHighPrecisionGps());
        }
        if (dto.getDarkThemeMode() != null) {
            settings.setDarkThemeMode(dto.getDarkThemeMode());
        }
        if (dto.getAutoPlayPtt() != null) {
            settings.setAutoPlayPtt(dto.getAutoPlayPtt());
        }
        if (dto.getStealthMode() != null) {
            settings.setStealthMode(dto.getStealthMode());
        }
        settings.setUpdatedAt(LocalDateTime.now());

        UserSettings saved = userSettingsRepository.save(settings);
        return mapToDto(saved);
    }

    private UserSettingsDto mapToDto(UserSettings s) {
        return new UserSettingsDto(
                s.getLocationSharing(),
                s.getHighPrecisionGps(),
                s.getDarkThemeMode(),
                s.getAutoPlayPtt(),
                s.getStealthMode()
        );
    }
}
