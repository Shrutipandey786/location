package com.locationservice.dto;

public class LocationDto {
    private Double latitude;
    private Double longitude;
    private String address;
    private String updatedAt;

    public LocationDto() {
    }

    public LocationDto(Double latitude, Double longitude, String address, String updatedAt) {
        this.latitude = latitude;
        this.longitude = longitude;
        this.address = address;
        this.updatedAt = updatedAt;
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

    public String getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(String updatedAt) {
        this.updatedAt = updatedAt;
    }
}
