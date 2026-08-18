package com.locationservice.repository;

import com.locationservice.entity.Conversation;
import com.locationservice.entity.Message;
import com.locationservice.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {

    List<Message> findByConversationOrderByCreatedAtAsc(Conversation conversation);

    Optional<Message> findTopByConversationOrderByCreatedAtDesc(Conversation conversation);

    long countByConversationAndRecipientAndIsReadFalse(Conversation conversation, User recipient);

    @Query("SELECT DISTINCT m.conversation FROM Message m WHERE (m.conversation.user1 = :user OR m.conversation.user2 = :user) AND (LOWER(m.text) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(m.sender.name) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(m.recipient.name) LIKE LOWER(CONCAT('%', :query, '%')))")
    List<Conversation> searchConversationsForUser(@Param("user") User user, @Param("query") String query);
}
