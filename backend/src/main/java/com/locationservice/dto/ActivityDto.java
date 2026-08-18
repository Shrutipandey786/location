package com.locationservice.dto;

public class ActivityDto {

    private Long id;
    private String title;
    private String details;
    private String type;
    private Double latitude;
    private Double longitude;
    private String address;
    private String peerName;
    private String deviceModel;
    private Integer batteryLevel;
    private String createdAt;

    public ActivityDto() {
    }

    public ActivityDto(Long id, String title, String details, String type, Double latitude, Double longitude, String createdAt) {
        this.id = id;
        this.title = title;
        this.details = details;
        this.type = type;
        this.latitude = latitude;
        this.longitude = longitude;
        this.createdAt = createdAt;
    }

    public ActivityDto(Long id, String title, String details, String type, Double latitude, Double longitude, String address, String peerName, String deviceModel, Integer batteryLevel, String createdAt) {
        this.id = id;
        this.title = title;
        this.details = details;
        this.type = type;
        this.latitude = latitude;
        this.longitude = longitude;
        this.address = address;
        this.peerName = peerName;
        this.deviceModel = deviceModel;
        this.batteryLevel = batteryLevel;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDetails() {
        return details;
    }

    public void setDetails(String details) {
        this.details = details;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
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

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getPeerName() {
        return peerName;
    }

    public void setPeerName(String peerName) {
        this.peerName = peerName;
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

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }
}
