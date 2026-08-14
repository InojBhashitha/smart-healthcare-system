package com.smarthealthcare.backend.notification.controller;

import com.smarthealthcare.backend.exception.ResourceNotFoundException;
import com.smarthealthcare.backend.notification.entity.PatientNotification;
import com.smarthealthcare.backend.notification.service.NotificationService;
import com.smarthealthcare.backend.user.entity.User;
import com.smarthealthcare.backend.user.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;
    private final UserRepository userRepository;

    public NotificationController(NotificationService notificationService, UserRepository userRepository) {
        this.notificationService = notificationService;
        this.userRepository = userRepository;
    }

    @GetMapping
    public ResponseEntity<List<PatientNotification>> getNotifications(Authentication authentication) {
        User user = getUserFromAuth(authentication);
        List<PatientNotification> notifications = notificationService.getUserNotifications(user.getUserId());
        return ResponseEntity.ok(notifications);
    }

    @GetMapping("/unread-count")
    public ResponseEntity<Long> getUnreadCount(Authentication authentication) {
        User user = getUserFromAuth(authentication);
        long count = notificationService.getUnreadCount(user.getUserId());
        return ResponseEntity.ok(count);
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<PatientNotification> markAsRead(
            Authentication authentication,
            @PathVariable Long id) {

        User user = getUserFromAuth(authentication);
        PatientNotification updated = notificationService.markAsRead(user.getUserId(), id);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/clear")
    public ResponseEntity<Void> clearAll(Authentication authentication) {
        User user = getUserFromAuth(authentication);
        notificationService.clearAllNotifications(user.getUserId());
        return ResponseEntity.noContent().build();
    }

    private User getUserFromAuth(Authentication authentication) {
        String email = authentication.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + email));
    }
}
