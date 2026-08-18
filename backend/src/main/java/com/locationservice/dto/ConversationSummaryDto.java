package com.locationservice.dto;

public class ConversationSummaryDto {

    private Long conversationId;
    private Long peerId;
    private String peerName;
    private String peerEmail;
    private String avatarInitials;
    private Boolean isOnline;
    private String statusMessage;
    private Integer batteryLevel;
    private String deviceModel;
    private Double latitude;
    private Double longitude;
    private String address;
    private Long unreadCount;
    private String lastMessageText;
    private String lastMessageType;
    private String lastMessageTime;

    public ConversationSummaryDto() {
    }

    public ConversationSummaryDto(Long conversationId, Long peerId, String peerName, String peerEmail, String avatarInitials, Boolean isOnline, String statusMessage, Integer batteryLevel, String deviceModel, Double latitude, Double longitude, String address, Long unreadCount, String lastMessageText, String lastMessageType, String lastMessageTime) {
        this.conversationId = conversationId;
        this.peerId = peerId;
        this.peerName = peerName;
        this.peerEmail = peerEmail;
        this.avatarInitials = avatarInitials;
        this.isOnline = isOnline;
        this.statusMessage = statusMessage;
        this.batteryLevel = batteryLevel;
        this.deviceModel = deviceModel;
        this.latitude = latitude;
        this.longitude = longitude;
        this.address = address;
        this.unreadCount = unreadCount;
        this.lastMessageText = lastMessageText;
        this.lastMessageType = lastMessageType;
        this.lastMessageTime = lastMessageTime;
    }

    public Long getConversationId() {
        return conversationId;
    }

    public void setConversationId(Long conversationId) {
        this.conversationId = conversationId;
    }

    public Long getPeerId() {
        return peerId;
    }

    public void setPeerId(Long peerId) {
        this.peerId = peerId;
    }

    public String getPeerName() {
        return peerName;
    }

    public void setPeerName(String peerName) {
        this.peerName = peerName;
    }

    public String getPeerEmail() {
        return peerEmail;
    }

    public void setPeerEmail(String peerEmail) {
        this.peerEmail = peerEmail;
    }

    public String getAvatarInitials() {
        return avatarInitials;
    }

    public void setAvatarInitials(String avatarInitials) {
        this.avatarInitials = avatarInitials;
    }

    public Boolean getIsOnline() {
        return isOnline;
    }

    public void setIsOnline(Boolean online) {
        isOnline = online;
    }

    public String getStatusMessage() {
        return statusMessage;
    }

    public void setStatusMessage(String statusMessage) {
        this.statusMessage = statusMessage;
    }

    public Integer getBatteryLevel() {
        return batteryLevel;
    }

    public void setBatteryLevel(Integer batteryLevel) {
        this.batteryLevel = batteryLevel;
    }

    public String getDeviceModel() {
        return deviceModel;
    }

    public void setDeviceModel(String deviceModel) {
        this.deviceModel = deviceModel;
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

    public Long getUnreadCount() {
        return unreadCount;
    }

    public void setUnreadCount(Long unreadCount) {
        this.unreadCount = unreadCount;
    }

    public String getLastMessageText() {
        return lastMessageText;
    }

    public void setLastMessageText(String lastMessageText) {
        this.lastMessageText = lastMessageText;
    }

    public String getLastMessageType() {
        return lastMessageType;
    }

    public void setLastMessageType(String lastMessageType) {
        this.lastMessageType = lastMessageType;
    }

    public String getLastMessageTime() {
        return lastMessageTime;
    }

    public void setLastMessageTime(String lastMessageTime) {
        this.lastMessageTime = lastMessageTime;
    }
}
