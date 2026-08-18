package com.locationservice.dto;

public class DeviceStatusUpdateRequest {

    private Integer batteryLevel;
    private Boolean online;
    private Boolean isBroadcasting;
    private String statusMessage;

    public DeviceStatusUpdateRequest() {
    }

    public DeviceStatusUpdateRequest(Integer batteryLevel, Boolean online, Boolean isBroadcasting, String statusMessage) {
        this.batteryLevel = batteryLevel;
        this.online = online;
        this.isBroadcasting = isBroadcasting;
        this.statusMessage = statusMessage;
    }

    public Integer getBatteryLevel() {
        return batteryLevel;
    }

    public void setBatteryLevel(Integer batteryLevel) {
        this.batteryLevel = batteryLevel;
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

    public String getStatusMessage() {
        return statusMessage;
    }

    public void setStatusMessage(String statusMessage) {
        this.statusMessage = statusMessage;
    }
}
