package com.locationservice.controller;

import com.locationservice.dto.ConversationDetailResponse;
import com.locationservice.dto.ConversationSummaryDto;
import com.locationservice.dto.LocationMessageRequest;
import com.locationservice.dto.MediaMessageRequest;
import com.locationservice.dto.MessageDto;
import com.locationservice.dto.SendMessageRequest;
import com.locationservice.entity.User;
import com.locationservice.service.ConversationService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/conversations")
public class ConversationController {

    private final ConversationService conversationService;

    public ConversationController(ConversationService conversationService) {
        this.conversationService = conversationService;
    }

    @GetMapping
    public ResponseEntity<List<ConversationSummaryDto>> getConversations(@AuthenticationPrincipal User user) {
        List<ConversationSummaryDto> conversations = conversationService.getConversations(user);
        return ResponseEntity.ok(conversations);
    }

    @GetMapping("/search")
    public ResponseEntity<List<ConversationSummaryDto>> searchConversations(
            @AuthenticationPrincipal User user,
            @RequestParam(name = "query", required = false) String query) {
        List<ConversationSummaryDto> results = conversationService.searchConversations(user, query);
        return ResponseEntity.ok(results);
    }

    @GetMapping("/{peerId}")
    public ResponseEntity<ConversationDetailResponse> getConversationDetail(
            @AuthenticationPrincipal User user,
            @PathVariable Long peerId) {
        ConversationDetailResponse detail = conversationService.getConversationDetail(user, peerId);
        return ResponseEntity.ok(detail);
    }

    @PostMapping("/{peerId}/messages")
    public ResponseEntity<MessageDto> sendMessage(
            @AuthenticationPrincipal User user,
            @PathVariable Long peerId,
            @RequestBody SendMessageRequest request) {
        MessageDto message = conversationService.sendMessage(user, peerId, request);
        return ResponseEntity.ok(message);
    }

    @PostMapping("/{peerId}/location")
    public ResponseEntity<MessageDto> sendLocationMessage(
            @AuthenticationPrincipal User user,
            @PathVariable Long peerId,
            @Valid @RequestBody LocationMessageRequest request) {
        MessageDto message = conversationService.sendLocationMessage(user, peerId, request);
        return ResponseEntity.ok(message);
    }

    @PostMapping("/{peerId}/media")
    public ResponseEntity<MessageDto> sendMediaMessage(
            @AuthenticationPrincipal User user,
            @PathVariable Long peerId,
            @Valid @RequestBody MediaMessageRequest request) {
        MessageDto message = conversationService.sendMediaMessage(user, peerId, request);
        return ResponseEntity.ok(message);
    }

    @PostMapping(value = "/{peerId}/voice", consumes = org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<MessageDto> sendVoiceMessage(
            @AuthenticationPrincipal User user,
            @PathVariable Long peerId,
            @RequestParam("file") org.springframework.web.multipart.MultipartFile file,
            @RequestParam(name = "pttDurationSeconds", required = false, defaultValue = "0") Integer pttDurationSeconds,
            @RequestParam(name = "latitude", required = false) Double latitude,
            @RequestParam(name = "longitude", required = false) Double longitude,
            @RequestParam(name = "address", required = false) String address) {
        MessageDto message = conversationService.sendVoiceMessage(user, peerId, file, pttDurationSeconds, latitude, longitude, address);
        return ResponseEntity.ok(message);
    }

    @PutMapping("/{peerId}/read")
    public ResponseEntity<Map<String, String>> markMessagesAsRead(
            @AuthenticationPrincipal User user,
            @PathVariable Long peerId) {
        conversationService.markMessagesAsRead(user, peerId);
        return ResponseEntity.ok(Map.of("message", "Messages marked as read"));
    }
}
