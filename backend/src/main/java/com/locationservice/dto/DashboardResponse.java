package com.locationservice.dto;

import java.util.List;

public class DashboardResponse {
    private UserDto user;
    private LocationDto location;
    private DeviceStatusDto deviceStatus;
    private List<ActivityDto> recentActivities;

    public DashboardResponse() {
    }

    public DashboardResponse(UserDto user, LocationDto location, DeviceStatusDto deviceStatus, List<ActivityDto> recentActivities) {
        this.user = user;
        this.location = location;
        this.deviceStatus = deviceStatus;
        this.recentActivities = recentActivities;
    }

    public UserDto getUser() {
        return user;
    }

    public void setUser(UserDto user) {
        this.user = user;
    }

    public LocationDto getLocation() {
        return location;
    }

    public void setLocation(LocationDto location) {
        this.location = location;
    }

    public DeviceStatusDto getDeviceStatus() {
        return deviceStatus;
    }

    public void setDeviceStatus(DeviceStatusDto deviceStatus) {
        this.deviceStatus = deviceStatus;
    }

    public List<ActivityDto> getRecentActivities() {
        return recentActivities;
    }

    public void setRecentActivities(List<ActivityDto> recentActivities) {
        this.recentActivities = recentActivities;
    }
}
