package com.smarthealthcare.backend.notification.service;

import com.smarthealthcare.backend.exception.ResourceNotFoundException;
import com.smarthealthcare.backend.notification.entity.PatientNotification;
import com.smarthealthcare.backend.notification.repository.PatientNotificationRepository;
import com.smarthealthcare.backend.user.entity.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
public class NotificationService {

    private final PatientNotificationRepository notificationRepository;

    public NotificationService(PatientNotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    public List<PatientNotification> getUserNotifications(Long userId) {
        return notificationRepository.findByUserUserIdOrderByCreatedAtDesc(userId);
    }

    public long getUnreadCount(Long userId) {
        return notificationRepository.countByUserUserIdAndIsReadFalse(userId);
    }

    @Transactional
    public PatientNotification createNotification(User user, String title, String message, String type) {
        PatientNotification notification = new PatientNotification();
        notification.setUser(user);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setType(type.toUpperCase());
        notification.setIsRead(false);
        notification.setCreatedAt(LocalDateTime.now());

        PatientNotification saved = notificationRepository.save(notification);
        log.info("Created Notification #{} ({}) for User #{}", saved.getNotificationId(), type, user.getUserId());
        return saved;
    }

    @Transactional
    public PatientNotification markAsRead(Long userId, Long notificationId) {
        PatientNotification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found: " + notificationId));

        notification.setIsRead(true);
        return notificationRepository.save(notification);
    }

    @Transactional
    public void clearAllNotifications(Long userId) {
        List<PatientNotification> notifications = notificationRepository.findByUserUserIdOrderByCreatedAtDesc(userId);
        notificationRepository.deleteAll(notifications);
        log.info("Cleared all notifications for User #{}", userId);
    }
}
