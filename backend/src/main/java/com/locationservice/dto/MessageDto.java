package com.locationservice.dto;

public class MessageDto {

    private Long id;
    private Long senderId;
    private String senderName;
    private Long recipientId;
    private String text;
    private String type;
    private Double latitude;
    private Double longitude;
    private String address;
    private String cameraImageUrl;
    private String audioUrl;
    private Integer pttDurationSeconds;
    private Boolean isRead;
    private String createdAt;

    public MessageDto() {
    }

    public MessageDto(Long id, Long senderId, String senderName, Long recipientId, String text, String type, Double latitude, Double longitude, String address, String cameraImageUrl, Integer pttDurationSeconds, Boolean isRead, String createdAt) {
        this.id = id;
        this.senderId = senderId;
        this.senderName = senderName;
        this.recipientId = recipientId;
        this.text = text;
        this.type = type;
        this.latitude = latitude;
        this.longitude = longitude;
        this.address = address;
        this.cameraImageUrl = cameraImageUrl;
        this.pttDurationSeconds = pttDurationSeconds;
        this.isRead = isRead;
        this.createdAt = createdAt;
    }

    public MessageDto(Long id, Long senderId, String senderName, Long recipientId, String text, String type, Double latitude, Double longitude, String address, String cameraImageUrl, String audioUrl, Integer pttDurationSeconds, Boolean isRead, String createdAt) {
        this.id = id;
        this.senderId = senderId;
        this.senderName = senderName;
        this.recipientId = recipientId;
        this.text = text;
        this.type = type;
        this.latitude = latitude;
        this.longitude = longitude;
        this.address = address;
        this.cameraImageUrl = cameraImageUrl;
        this.audioUrl = audioUrl;
        this.pttDurationSeconds = pttDurationSeconds;
        this.isRead = isRead;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getSenderId() {
        return senderId;
    }

    public void setSenderId(Long senderId) {
        this.senderId = senderId;
    }

    public String getSenderName() {
        return senderName;
    }

    public void setSenderName(String senderName) {
        this.senderName = senderName;
    }

    public Long getRecipientId() {
        return recipientId;
    }

    public void setRecipientId(Long recipientId) {
        this.recipientId = recipientId;
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

    public String getAudioUrl() {
        return audioUrl;
    }

    public void setAudioUrl(String audioUrl) {
        this.audioUrl = audioUrl;
    }

    public Integer getPttDurationSeconds() {
        return pttDurationSeconds;
    }

    public void setPttDurationSeconds(Integer pttDurationSeconds) {
        this.pttDurationSeconds = pttDurationSeconds;
    }

    public Boolean getIsRead() {
        return isRead;
    }

    public void setIsRead(Boolean read) {
        isRead = read;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }
}
