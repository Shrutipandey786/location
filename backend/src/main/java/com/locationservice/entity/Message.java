package com.locationservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "messages")
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "conversation_id", nullable = false)
    private Conversation conversation;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;

    @Column(nullable = false, length = 1000)
    private String text;

    @Column(nullable = false, length = 50)
    private String type; // TEXT, LOCATION, CAMERA, PTT_VOICE, SOS_ALERT, STATUS_PRESET

    private Double latitude;
    private Double longitude;
    private String address;

    private String cameraImageUrl;
    private String audioUrl;
    private Integer pttDurationSeconds;

    @Column(nullable = false)
    private Boolean isRead = false;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    public Message() {
    }

    public Message(Conversation conversation, User sender, User recipient, String text, String type, Double latitude, Double longitude, String address, String cameraImageUrl, Integer pttDurationSeconds, Boolean isRead, LocalDateTime createdAt) {
        this.conversation = conversation;
        this.sender = sender;
        this.recipient = recipient;
        this.text = text;
        this.type = type;
        this.latitude = latitude;
        this.longitude = longitude;
        this.address = address;
        this.cameraImageUrl = cameraImageUrl;
        this.pttDurationSeconds = pttDurationSeconds;
        this.isRead = isRead != null ? isRead : false;
        this.createdAt = createdAt;
    }

    public Message(Conversation conversation, User sender, User recipient, String text, String type, Double latitude, Double longitude, String address, String cameraImageUrl, String audioUrl, Integer pttDurationSeconds, Boolean isRead, LocalDateTime createdAt) {
        this.conversation = conversation;
        this.sender = sender;
        this.recipient = recipient;
        this.text = text;
        this.type = type;
        this.latitude = latitude;
        this.longitude = longitude;
        this.address = address;
        this.cameraImageUrl = cameraImageUrl;
        this.audioUrl = audioUrl;
        this.pttDurationSeconds = pttDurationSeconds;
        this.isRead = isRead != null ? isRead : false;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Conversation getConversation() {
        return conversation;
    }

    public void setConversation(Conversation conversation) {
        this.conversation = conversation;
    }

    public User getSender() {
        return sender;
    }

    public void setSender(User sender) {
        this.sender = sender;
    }

    public User getRecipient() {
        return recipient;
    }

    public void setRecipient(User recipient) {
        this.recipient = recipient;
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

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
