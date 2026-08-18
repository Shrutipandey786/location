package com.locationservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_settings")
public class UserSettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false)
    private Boolean locationSharing = true;

    @Column(nullable = false)
    private Boolean highPrecisionGps = true;

    @Column(nullable = false)
    private Boolean darkThemeMode = false;

    @Column(nullable = false)
    private Boolean autoPlayPtt = true;

    @Column(nullable = false)
    private Boolean stealthMode = false;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    public UserSettings() {
    }

    public UserSettings(User user, Boolean locationSharing, Boolean highPrecisionGps, Boolean darkThemeMode, Boolean autoPlayPtt, Boolean stealthMode, LocalDateTime updatedAt) {
        this.user = user;
        this.locationSharing = locationSharing;
        this.highPrecisionGps = highPrecisionGps;
        this.darkThemeMode = darkThemeMode;
        this.autoPlayPtt = autoPlayPtt;
        this.stealthMode = stealthMode;
        this.updatedAt = updatedAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Boolean getLocationSharing() {
        return locationSharing;
    }

    public void setLocationSharing(Boolean locationSharing) {
        this.locationSharing = locationSharing;
    }

    public Boolean getHighPrecisionGps() {
        return highPrecisionGps;
    }

    public void setHighPrecisionGps(Boolean highPrecisionGps) {
        this.highPrecisionGps = highPrecisionGps;
    }

    public Boolean getDarkThemeMode() {
        return darkThemeMode;
    }

    public void setDarkThemeMode(Boolean darkThemeMode) {
        this.darkThemeMode = darkThemeMode;
    }

    public Boolean getAutoPlayPtt() {
        return autoPlayPtt;
    }

    public void setAutoPlayPtt(Boolean autoPlayPtt) {
        this.autoPlayPtt = autoPlayPtt;
    }

    public Boolean getStealthMode() {
        return stealthMode;
    }

    public void setStealthMode(Boolean stealthMode) {
        this.stealthMode = stealthMode;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
