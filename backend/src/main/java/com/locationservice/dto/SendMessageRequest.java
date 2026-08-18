package com.locationservice.dto;

public class SendMessageRequest {

    private String text;
    private String type; // TEXT, LOCATION, CAMERA, PTT_VOICE, SOS_ALERT, STATUS_PRESET
    private Double latitude;
    private Double longitude;
    private String address;
    private String cameraImageUrl;
    private Integer pttDurationSeconds;

    public SendMessageRequest() {
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
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

    public String getCameraImageUrl() {
        return cameraImageUrl;
    }

    public void setCameraImageUrl(String cameraImageUrl) {
        this.cameraImageUrl = cameraImageUrl;
    }

    public Integer getPttDurationSeconds() {
        return pttDurationSeconds;
    }

    public void setPttDurationSeconds(Integer pttDurationSeconds) {
        this.pttDurationSeconds = pttDurationSeconds;
    }
}
