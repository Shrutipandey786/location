package com.locationservice.dto;

import java.util.List;

public class ConversationDetailResponse {

    private Long conversationId;
    private ConversationSummaryDto peer;
    private List<MessageDto> messages;

    public ConversationDetailResponse() {
    }

    public ConversationDetailResponse(Long conversationId, ConversationSummaryDto peer, List<MessageDto> messages) {
        this.conversationId = conversationId;
        this.peer = peer;
        this.messages = messages;
    }

    public Long getConversationId() {
        return conversationId;
    }

    public void setConversationId(Long conversationId) {
        this.conversationId = conversationId;
    }

    public ConversationSummaryDto getPeer() {
        return peer;
    }

    public void setPeer(ConversationSummaryDto peer) {
        this.peer = peer;
    }

    public List<MessageDto> getMessages() {
        return messages;
    }

    public void setMessages(List<MessageDto> messages) {
        this.messages = messages;
    }
}
