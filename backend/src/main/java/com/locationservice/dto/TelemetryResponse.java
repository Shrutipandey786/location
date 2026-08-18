package com.locationservice.dto;

public class TelemetryResponse {

    private String deviceModel;
    private Integer batteryLevel;
    private Double latitude;
    private Double longitude;
    private Double altitude;
    private Double speed;
    private String address;
    private Integer networkLatencyMs;

    public TelemetryResponse() {
    }

    public TelemetryResponse(String deviceModel, Integer batteryLevel, Double latitude, Double longitude, Double altitude, Double speed, String address, Integer networkLatencyMs) {
        this.deviceModel = deviceModel;
        this.batteryLevel = batteryLevel;
        this.latitude = latitude;
        this.longitude = longitude;
        this.altitude = altitude;
        this.speed = speed;
        this.address = address;
        this.networkLatencyMs = networkLatencyMs;
    }

    public String getDeviceModel() {
        return deviceModel;
    }

    public void setDeviceModel(String deviceModel) {
        this.deviceModel = deviceModel;
    }

    public Integer getBatteryLevel() {
        return batteryLevel;
    }

    public void setBatteryLevel(Integer batteryLevel) {
        this.batteryLevel = batteryLevel;
    }

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    public Double getAltitude() {
        return altitude;
    }

    public void setAltitude(Double altitude) {
        this.altitude = altitude;
    }

    public Double getSpeed() {
        return speed;
    }

    public void setSpeed(Double speed) {
        this.speed = speed;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public Integer getNetworkLatencyMs() {
        return networkLatencyMs;
    }

    public void setNetworkLatencyMs(Integer networkLatencyMs) {
        this.networkLatencyMs = networkLatencyMs;
    }
}
