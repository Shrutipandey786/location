package com.locationservice.dto;

public class UserSettingsDto {

    private Boolean locationSharing;
    private Boolean highPrecisionGps;
    private Boolean darkThemeMode;
    private Boolean autoPlayPtt;
    private Boolean stealthMode;

    public UserSettingsDto() {
    }

    public UserSettingsDto(Boolean locationSharing, Boolean highPrecisionGps, Boolean darkThemeMode, Boolean autoPlayPtt, Boolean stealthMode) {
        this.locationSharing = locationSharing;
        this.highPrecisionGps = highPrecisionGps;
        this.darkThemeMode = darkThemeMode;
        this.autoPlayPtt = autoPlayPtt;
        this.stealthMode = stealthMode;
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
}
