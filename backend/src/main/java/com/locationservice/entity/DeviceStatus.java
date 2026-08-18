package com.locationservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "device_status")
public class DeviceStatus {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false)
    private Boolean online = true;

    @Column(nullable = false)
    private Boolean isBroadcasting = true;

    @Column(nullable = false)
    private Integer batteryLevel = 100;

    private String statusMessage;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    public DeviceStatus() {
    }

    public DeviceStatus(User user, Boolean online, Boolean isBroadcasting, Integer batteryLevel, String statusMessage, LocalDateTime updatedAt) {
        this.user = user;
        this.online = online;
        this.isBroadcasting = isBroadcasting;
        this.batteryLevel = batteryLevel;
        this.statusMessage = statusMessage;
        this.updatedAt = updatedAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
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

    public Integer getBatteryLevel() {
        return batteryLevel;
    }

    public void setBatteryLevel(Integer batteryLevel) {
        this.batteryLevel = batteryLevel;
    }

    public String getStatusMessage() {
        return statusMessage;
    }

    public void setStatusMessage(String statusMessage) {
        this.statusMessage = statusMessage;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
