package com.locationservice.dto;

import jakarta.validation.constraints.NotNull;

public class LocationMessageRequest {

    @NotNull(message = "Latitude is required")
    private Double latitude;

    @NotNull(message = "Longitude is required")
    private Double longitude;

    private String address;
    private String text;

    public LocationMessageRequest() {
    }

    public LocationMessageRequest(Double latitude, Double longitude, String address, String text) {
        this.latitude = latitude;
        this.longitude = longitude;
        this.address = address;
        this.text = text;
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

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }
}
