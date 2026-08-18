package com.locationservice.dto;

import jakarta.validation.constraints.NotBlank;

public class MediaMessageRequest {

    @NotBlank(message = "Media type is required")
    private String type; // CAMERA or PTT_VOICE

    private String cameraImageUrl;
    private Integer pttDurationSeconds;
    private String text;

    public MediaMessageRequest() {
    }

    public MediaMessageRequest(String type, String cameraImageUrl, Integer pttDurationSeconds, String text) {
        this.type = type;
        this.cameraImageUrl = cameraImageUrl;
        this.pttDurationSeconds = pttDurationSeconds;
        this.text = text;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
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

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }
}
