package com.locationservice.service;

import com.locationservice.dto.ConversationDetailResponse;
import com.locationservice.dto.ConversationSummaryDto;
import com.locationservice.dto.LocationMessageRequest;
import com.locationservice.dto.MediaMessageRequest;
import com.locationservice.dto.MessageDto;
import com.locationservice.dto.SendMessageRequest;
import com.locationservice.entity.Conversation;
import com.locationservice.entity.DeviceStatus;
import com.locationservice.entity.Location;
import com.locationservice.entity.Message;
import com.locationservice.entity.User;
import com.locationservice.repository.ConversationRepository;
import com.locationservice.repository.DeviceStatusRepository;
import com.locationservice.repository.LocationRepository;
import com.locationservice.repository.MessageRepository;
import com.locationservice.repository.UserRepository;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ConversationService {

    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final LocationRepository locationRepository;
    private final DeviceStatusRepository deviceStatusRepository;
    private final SimpMessagingTemplate messagingTemplate;

    private static final DateTimeFormatter ISO_FORMATTER = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    public ConversationService(
            ConversationRepository conversationRepository,
            MessageRepository messageRepository,
            UserRepository userRepository,
            LocationRepository locationRepository,
            DeviceStatusRepository deviceStatusRepository,
            SimpMessagingTemplate messagingTemplate) {
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
        this.locationRepository = locationRepository;
        this.deviceStatusRepository = deviceStatusRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @Transactional(readOnly = true)
    public List<ConversationSummaryDto> getConversations(User currentUser) {
        List<Conversation> conversations = conversationRepository.findByUser1OrUser2OrderByUpdatedAtDesc(currentUser, currentUser);
        
        Set<Long> processedUserIds = new HashSet<>();
        List<ConversationSummaryDto> results = new ArrayList<>();

        if (conversations != null) {
            for (Conversation conv : conversations) {
                if (conv.getUser1() != null && conv.getUser2() != null) {
                    User peer = conv.getUser1().getId().equals(currentUser.getId()) ? conv.getUser2() : conv.getUser1();
                    processedUserIds.add(peer.getId());
                    results.add(buildSummaryDto(conv, currentUser));
                }
            }
        }

        List<User> allUsers = userRepository.findAll();
        for (User peer : allUsers) {
            if (!peer.getId().equals(currentUser.getId()) && !processedUserIds.contains(peer.getId())) {
                processedUserIds.add(peer.getId());
                results.add(buildUserSummaryDto(peer));
            }
        }

        return results;
    }

    @Transactional(readOnly = true)
    public List<ConversationSummaryDto> searchConversations(User currentUser, String query) {
        if (query == null || query.isBlank()) {
            return getConversations(currentUser);
        }

        String trimmed = query.trim().toLowerCase();

        List<Conversation> matchingConversations = messageRepository.searchConversationsForUser(currentUser, trimmed);

        Set<Long> conversationIds = new HashSet<>();
        List<ConversationSummaryDto> results = new ArrayList<>();

        if (matchingConversations != null) {
            for (Conversation conv : matchingConversations) {
                conversationIds.add(conv.getId());
                results.add(buildSummaryDto(conv, currentUser));
            }
        }

        List<User> matchingUsers = userRepository.findAll().stream()
                .filter(u -> !u.getId().equals(currentUser.getId()))
                .filter(u -> (u.getName() != null && u.getName().toLowerCase().contains(trimmed)) || 
                             (u.getEmail() != null && u.getEmail().toLowerCase().contains(trimmed)))
                .collect(Collectors.toList());

        for (User peer : matchingUsers) {
            Optional<Conversation> convOpt = conversationRepository.findBetweenUsers(currentUser, peer);
            if (convOpt.isPresent() && !conversationIds.contains(convOpt.get().getId())) {
                conversationIds.add(convOpt.get().getId());
                results.add(buildSummaryDto(convOpt.get(), currentUser));
            } else if (convOpt.isEmpty()) {
                results.add(buildUserSummaryDto(peer));
            }
        }

        return results;
    }

    @Transactional
    public ConversationDetailResponse getConversationDetail(User currentUser, Long peerId) {
        User peer = userRepository.findById(peerId)
                .orElseThrow(() -> new IllegalArgumentException("Peer user not found with id: " + peerId));

        Conversation conversation = conversationRepository.findBetweenUsers(currentUser, peer)
                .orElseGet(() -> conversationRepository.save(new Conversation(currentUser, peer, LocalDateTime.now())));

        List<Message> messages = messageRepository.findByConversationOrderByCreatedAtAsc(conversation);

        if (messages != null) {
            for (Message msg : messages) {
                if (msg.getRecipient() != null && msg.getRecipient().getId().equals(currentUser.getId()) && Boolean.FALSE.equals(msg.getIsRead())) {
                    msg.setIsRead(true);
                    messageRepository.save(msg);
                }
            }
        } else {
            messages = new ArrayList<>();
        }

        List<MessageDto> messageDtos = messages.stream()
                .map(this::mapToMessageDto)
                .collect(Collectors.toList());

        ConversationSummaryDto summaryDto = buildSummaryDto(conversation, currentUser);

        return new ConversationDetailResponse(conversation.getId(), summaryDto, messageDtos);
    }

    @Transactional
    public MessageDto sendMessage(User currentUser, Long peerId, SendMessageRequest request) {
        User peer = userRepository.findById(peerId)
                .orElseThrow(() -> new IllegalArgumentException("Peer user not found with id: " + peerId));

        LocalDateTime now = LocalDateTime.now();

        Conversation conversation = conversationRepository.findBetweenUsers(currentUser, peer)
                .orElseGet(() -> new Conversation(currentUser, peer, now));

        conversation.setUpdatedAt(now);
        conversation = conversationRepository.save(conversation);

        Message message = new Message(
                conversation,
                currentUser,
                peer,
                request.getText() != null ? request.getText() : "",
                request.getType() != null ? request.getType() : "TEXT",
                request.getLatitude(),
                request.getLongitude(),
                request.getAddress(),
                request.getCameraImageUrl(),
                request.getPttDurationSeconds(),
                false,
                now
        );

        Message savedMessage = messageRepository.save(message);
        MessageDto dto = mapToMessageDto(savedMessage);
        notifyWebSocketSubscribers(dto, peer.getId(), currentUser.getId());
        return dto;
    }

    @Transactional
    public MessageDto sendLocationMessage(User currentUser, Long peerId, LocationMessageRequest request) {
        User peer = userRepository.findById(peerId)
                .orElseThrow(() -> new IllegalArgumentException("Peer user not found with id: " + peerId));

        LocalDateTime now = LocalDateTime.now();

        Conversation conversation = conversationRepository.findBetweenUsers(currentUser, peer)
                .orElseGet(() -> new Conversation(currentUser, peer, now));

        conversation.setUpdatedAt(now);
        conversation = conversationRepository.save(conversation);

        Location location = locationRepository.findTopByUserOrderByUpdatedAtDesc(currentUser)
                .orElse(new Location());
        location.setUser(currentUser);
        location.setLatitude(request.getLatitude());
        location.setLongitude(request.getLongitude());
        location.setAddress(request.getAddress() != null && !request.getAddress().isBlank() 
                ? request.getAddress() 
                : String.format("%.4f, %.4f", request.getLatitude(), request.getLongitude()));
        location.setUpdatedAt(now);
        locationRepository.save(location);

        String text = request.getText() != null && !request.getText().isBlank() 
                ? request.getText() 
                : "Shared GPS Location Pin";

        Message message = new Message(
                conversation,
                currentUser,
                peer,
                text,
                "LOCATION",
                request.getLatitude(),
                request.getLongitude(),
                location.getAddress(),
                null,
                null,
                false,
                now
        );

        Message savedMessage = messageRepository.save(message);
        MessageDto dto = mapToMessageDto(savedMessage);
        notifyWebSocketSubscribers(dto, peer.getId(), currentUser.getId());
        return dto;
    }

    @Transactional
    public MessageDto sendMediaMessage(User currentUser, Long peerId, MediaMessageRequest request) {
        User peer = userRepository.findById(peerId)
                .orElseThrow(() -> new IllegalArgumentException("Peer user not found with id: " + peerId));

        LocalDateTime now = LocalDateTime.now();

        Conversation conversation = conversationRepository.findBetweenUsers(currentUser, peer)
                .orElseGet(() -> new Conversation(currentUser, peer, now));

        conversation.setUpdatedAt(now);
        conversation = conversationRepository.save(conversation);

        String text = request.getText() != null && !request.getText().isBlank() 
                ? request.getText() 
                : ("CAMERA".equalsIgnoreCase(request.getType()) ? "Live Camera Snapshot" : "Push-to-Talk Voice Message");

        Message message = new Message(
                conversation,
                currentUser,
                peer,
                text,
                request.getType() != null ? request.getType().toUpperCase() : "MEDIA",
                null,
                null,
                null,
                request.getCameraImageUrl(),
                request.getPttDurationSeconds(),
                false,
                now
        );

        Message savedMessage = messageRepository.save(message);
        MessageDto dto = mapToMessageDto(savedMessage);
        notifyWebSocketSubscribers(dto, peer.getId(), currentUser.getId());
        return dto;
    }

    @Transactional
    public MessageDto sendVoiceMessage(User currentUser, Long peerId, MultipartFile file, Integer pttDurationSeconds, Double latitude, Double longitude, String address) {
        User peer = userRepository.findById(peerId)
                .orElseThrow(() -> new IllegalArgumentException("Peer user not found with id: " + peerId));

        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Voice audio file cannot be empty");
        }

        String audioUrl;
        try {
            Path uploadDir = Paths.get("./uploads/voice");
            if (!Files.exists(uploadDir)) {
                Files.createDirectories(uploadDir);
            }

            String originalName = file.getOriginalFilename();
            String extension = ".m4a";
            if (originalName != null && originalName.contains(".")) {
                extension = originalName.substring(originalName.lastIndexOf("."));
            }

            String fileName = "voice_" + UUID.randomUUID().toString() + extension;
            Path targetPath = uploadDir.resolve(fileName);
            Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);

            audioUrl = "/uploads/voice/" + fileName;
        } catch (IOException e) {
            throw new RuntimeException("Failed to store voice audio file", e);
        }

        LocalDateTime now = LocalDateTime.now();

        Conversation conversation = conversationRepository.findBetweenUsers(currentUser, peer)
                .orElseGet(() -> new Conversation(currentUser, peer, now));

        conversation.setUpdatedAt(now);
        conversation = conversationRepository.save(conversation);

        int duration = pttDurationSeconds != null ? pttDurationSeconds : 0;
        String text = String.format("Voice memo stream (%02d:%02ds)", duration / 60, duration % 60);

        Message message = new Message(
                conversation,
                currentUser,
                peer,
                text,
                "PTT_VOICE",
                latitude,
                longitude,
                address,
                null,
                audioUrl,
                duration,
                false,
                now
        );

        Message savedMessage = messageRepository.save(message);
        MessageDto dto = mapToMessageDto(savedMessage);
        notifyWebSocketSubscribers(dto, peer.getId(), currentUser.getId());
        return dto;
    }

    private void notifyWebSocketSubscribers(MessageDto dto, Long recipientId, Long senderId) {
        try {
            messagingTemplate.convertAndSend("/topic/messages/" + recipientId, dto);
            messagingTemplate.convertAndSend("/topic/messages/" + senderId, dto);
        } catch (Exception e) {
            System.err.println("Failed to send WebSocket message: " + e.getMessage());
        }
    }

    @Transactional
    public void markMessagesAsRead(User currentUser, Long peerId) {
        User peer = userRepository.findById(peerId)
                .orElseThrow(() -> new IllegalArgumentException("Peer user not found with id: " + peerId));

        Optional<Conversation> convOpt = conversationRepository.findBetweenUsers(currentUser, peer);
        if (convOpt.isPresent()) {
            List<Message> messages = messageRepository.findByConversationOrderByCreatedAtAsc(convOpt.get());
            if (messages != null) {
                for (Message msg : messages) {
                    if (msg.getRecipient() != null && msg.getRecipient().getId().equals(currentUser.getId()) && Boolean.FALSE.equals(msg.getIsRead())) {
                        msg.setIsRead(true);
                        messageRepository.save(msg);
                    }
                }
            }
        }
    }

    private ConversationSummaryDto buildSummaryDto(Conversation conversation, User currentUser) {
        User peer = (conversation.getUser1() != null && conversation.getUser1().getId().equals(currentUser.getId())) 
                ? conversation.getUser2() 
                : conversation.getUser1();

        if (peer == null) {
            peer = currentUser;
        }

        return buildSummaryDtoForPeer(conversation, peer, currentUser);
    }

    private ConversationSummaryDto buildSummaryDtoForPeer(Conversation conversation, User peer, User currentUser) {
        Optional<Location> locOpt = locationRepository.findTopByUserOrderByUpdatedAtDesc(peer);
        Optional<DeviceStatus> statusOpt = deviceStatusRepository.findByUser(peer);
        Optional<Message> lastMsgOpt = messageRepository.findTopByConversationOrderByCreatedAtDesc(conversation);
        long unreadCount = messageRepository.countByConversationAndRecipientAndIsReadFalse(conversation, currentUser);

        String initials = getAvatarInitials(peer.getName());

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime timeToFormat = conversation.getUpdatedAt() != null ? conversation.getUpdatedAt() : now;
        if (lastMsgOpt.isPresent() && lastMsgOpt.get().getCreatedAt() != null) {
            timeToFormat = lastMsgOpt.get().getCreatedAt();
        }
        String formattedTimeStr = timeToFormat.format(ISO_FORMATTER);

        return new ConversationSummaryDto(
                conversation.getId() != null ? conversation.getId() : 0L,
                peer.getId(),
                peer.getName() != null ? peer.getName() : "User",
                peer.getEmail() != null ? peer.getEmail() : "",
                initials,
                statusOpt.map(DeviceStatus::getOnline).orElse(true),
                statusOpt.map(DeviceStatus::getStatusMessage).orElse("Active"),
                statusOpt.map(DeviceStatus::getBatteryLevel).orElse(100),
                "Android",
                locOpt.map(Location::getLatitude).orElse(null),
                locOpt.map(Location::getLongitude).orElse(null),
                locOpt.map(Location::getAddress).orElse(null),
                unreadCount,
                lastMsgOpt.map(Message::getText).orElse("No messages yet"),
                lastMsgOpt.map(Message::getType).orElse("TEXT"),
                formattedTimeStr
        );
    }

    private ConversationSummaryDto buildUserSummaryDto(User peer) {
        Optional<Location> locOpt = locationRepository.findTopByUserOrderByUpdatedAtDesc(peer);
        Optional<DeviceStatus> statusOpt = deviceStatusRepository.findByUser(peer);
        String initials = getAvatarInitials(peer.getName());

        return new ConversationSummaryDto(
                0L,
                peer.getId(),
                peer.getName() != null ? peer.getName() : "User",
                peer.getEmail() != null ? peer.getEmail() : "",
                initials,
                statusOpt.map(DeviceStatus::getOnline).orElse(true),
                statusOpt.map(DeviceStatus::getStatusMessage).orElse("Active"),
                statusOpt.map(DeviceStatus::getBatteryLevel).orElse(100),
                "Android",
                locOpt.map(Location::getLatitude).orElse(null),
                locOpt.map(Location::getLongitude).orElse(null),
                locOpt.map(Location::getAddress).orElse(null),
                0L,
                "Start conversation",
                "TEXT",
                LocalDateTime.now().format(ISO_FORMATTER)
        );
    }

    private MessageDto mapToMessageDto(Message msg) {
        LocalDateTime createdAt = msg.getCreatedAt() != null ? msg.getCreatedAt() : LocalDateTime.now();
        return new MessageDto(
                msg.getId(),
                msg.getSender() != null ? msg.getSender().getId() : null,
                msg.getSender() != null ? msg.getSender().getName() : "User",
                msg.getRecipient() != null ? msg.getRecipient().getId() : null,
                msg.getText() != null ? msg.getText() : "",
                msg.getType() != null ? msg.getType() : "TEXT",
                msg.getLatitude(),
                msg.getLongitude(),
                msg.getAddress(),
                msg.getCameraImageUrl(),
                msg.getAudioUrl(),
                msg.getPttDurationSeconds(),
                msg.getIsRead() != null ? msg.getIsRead() : false,
                createdAt.format(ISO_FORMATTER)
        );
    }

    private String getAvatarInitials(String name) {
        if (name == null || name.isBlank()) return "U";
        String[] parts = name.trim().split("\\s+");
        if (parts.length == 1) {
            return parts[0].substring(0, Math.min(2, parts[0].length())).toUpperCase();
        }
        return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1)).toUpperCase();
    }
}
