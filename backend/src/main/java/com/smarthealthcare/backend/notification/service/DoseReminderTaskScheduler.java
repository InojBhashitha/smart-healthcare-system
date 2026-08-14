package com.smarthealthcare.backend.notification.service;

import com.smarthealthcare.backend.treatment.entity.DoseSchedule;
import com.smarthealthcare.backend.treatment.repository.DoseScheduleRepository;
import com.smarthealthcare.backend.user.entity.User;
import com.smarthealthcare.backend.user.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

@Slf4j
@Component
public class DoseReminderTaskScheduler {

    private final DoseScheduleRepository scheduleRepository;
    private final NotificationService notificationService;
    private final UserRepository userRepository;

    public DoseReminderTaskScheduler(
            DoseScheduleRepository scheduleRepository,
            NotificationService notificationService,
            UserRepository userRepository) {

        this.scheduleRepository = scheduleRepository;
        this.notificationService = notificationService;
        this.userRepository = userRepository;
    }

    /**
     * Checks active schedules and generates reminders on startup and periodically.
     */
    @Scheduled(fixedRate = 3600000) // Runs every hour
    public void generateDoseReminders() {
        log.info("Running DoseReminderTaskScheduler background check...");

        List<User> users = userRepository.findAll();
        for (User user : users) {
            List<DoseSchedule> activeSchedules = scheduleRepository.findActiveSchedulesByUserId(user.getUserId());
            if (activeSchedules.isEmpty()) continue;

            long existingCount = notificationService.getUnreadCount(user.getUserId());
            if (existingCount == 0) {
                for (DoseSchedule ds : activeSchedules) {
                    notificationService.createNotification(
                            user,
                            "Dose Reminder: " + ds.getMedicineName() + " (" + ds.getDoseSlot() + ")",
                            "Time to take " + ds.getMedicineName() + " " + (ds.getStrength() != null ? ds.getStrength() : "") + ". Instruction: " + (ds.getInstruction() != null ? ds.getInstruction() : "Take as directed."),
                            "DOSE_REMINDER"
                    );
                }

                // Add a sample CDSS interaction notice if multiple active schedules
                if (activeSchedules.size() > 1) {
                    notificationService.createNotification(
                            user,
                            "Safety Reminder: Water & Food Intake",
                            "Remember to take your prescribed medication with plenty of water after meals to prevent gastric irritation.",
                            "SAFETY_WARNING"
                    );
                }
            }
        }
    }
}
