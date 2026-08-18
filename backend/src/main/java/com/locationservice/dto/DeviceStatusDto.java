package com.locationservice.dto;

public class DeviceStatusDto {
    private Boolean online;
    private Boolean isBroadcasting;
    private Integer batteryLevel;
    private String statusMessage;
    private String updatedAt;

    public DeviceStatusDto() {
    }

    public DeviceStatusDto(Boolean online, Boolean isBroadcasting, Integer batteryLevel, String statusMessage, String updatedAt) {
        this.online = online;
        this.isBroadcasting = isBroadcasting;
        this.batteryLevel = batteryLevel;
        this.statusMessage = statusMessage;
        this.updatedAt = updatedAt;
    }

    public Boolean getOnline() {
        return online;
    }

    public void setOnline(Boolean online) {
        this.online = online;
    }

    public Boolean getIsBroadcasting() {
        return isBroadcasting;
    }

    public void setIsBroadcasting(Boolean broadcasting) {
        isBroadcasting = broadcasting;
    }

    public Integer getBatteryLevel() {
        return batteryLevel;
    }

    public void setBatteryLevel(Integer batteryLevel) {
        this.batteryLevel = batteryLevel;
    }

    public String getStatusMessage() {
        return statusMessage;
    }

    public void setStatusMessage(String statusMessage) {
        this.statusMessage = statusMessage;
    }

    public String getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(String updatedAt) {
        this.updatedAt = updatedAt;
    }
}
