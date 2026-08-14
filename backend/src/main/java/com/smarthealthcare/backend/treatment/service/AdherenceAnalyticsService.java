package com.smarthealthcare.backend.treatment.service;

import com.smarthealthcare.backend.treatment.dto.AdherenceAnalyticsResponse;
import com.smarthealthcare.backend.treatment.entity.DoseLog;
import com.smarthealthcare.backend.treatment.entity.DoseSchedule;
import com.smarthealthcare.backend.treatment.repository.DoseLogRepository;
import com.smarthealthcare.backend.treatment.repository.DoseScheduleRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class AdherenceAnalyticsService {

    private final DoseScheduleRepository scheduleRepository;
    private final DoseLogRepository logRepository;

    public AdherenceAnalyticsService(
            DoseScheduleRepository scheduleRepository,
            DoseLogRepository logRepository) {

        this.scheduleRepository = scheduleRepository;
        this.logRepository = logRepository;
    }

    public AdherenceAnalyticsResponse calculateAdherence(Long userId) {
        List<DoseSchedule> activeSchedules = scheduleRepository.findActiveSchedulesByUserId(userId);
        int dailyScheduleCount = activeSchedules.size();

        LocalDate today = LocalDate.now();
        LocalDate sevenDaysAgo = today.minusDays(6);

        List<DoseLog> logs = logRepository.findLogsByUserAndDateRange(userId, sevenDaysAgo, today);

        Map<LocalDate, List<DoseLog>> logsByDate = logs.stream()
                .collect(Collectors.groupingBy(DoseLog::getLogDate));

        int totalScheduled = dailyScheduleCount * 7;
        int totalTaken = 0;
        int totalSkipped = 0;

        List<AdherenceAnalyticsResponse.DailyAdherence> weekly = new ArrayList<>();

        for (int i = 0; i < 7; i++) {
            LocalDate date = sevenDaysAgo.plusDays(i);
            List<DoseLog> dayLogs = logsByDate.getOrDefault(date, new ArrayList<>());

            int dayTaken = (int) dayLogs.stream().filter(l -> "TAKEN".equalsIgnoreCase(l.getStatus())).count();
            int daySkipped = (int) dayLogs.stream().filter(l -> "SKIPPED".equalsIgnoreCase(l.getStatus())).count();

            totalTaken += dayTaken;
            totalSkipped += daySkipped;

            double dayPct = dailyScheduleCount > 0 ? ((double) dayTaken / dailyScheduleCount) * 100 : 100.0;

            AdherenceAnalyticsResponse.DailyAdherence daily = new AdherenceAnalyticsResponse.DailyAdherence();
            daily.setDate(date.toString());
            daily.setDayOfWeek(date.getDayOfWeek().name().substring(0, 3));
            daily.setScheduledCount(dailyScheduleCount);
            daily.setTakenCount(dayTaken);
            daily.setPercentage(Math.round(dayPct * 10.0) / 10.0);

            weekly.add(daily);
        }

        double overallPct = totalScheduled > 0 ? ((double) totalTaken / totalScheduled) * 100 : 100.0;
        overallPct = Math.round(overallPct * 10.0) / 10.0;

        // Calculate consecutive streak days
        int streak = 0;
        for (int i = 6; i >= 0; i--) {
            LocalDate date = sevenDaysAgo.plusDays(i);
            List<DoseLog> dayLogs = logsByDate.getOrDefault(date, new ArrayList<>());
            long taken = dayLogs.stream().filter(l -> "TAKEN".equalsIgnoreCase(l.getStatus())).count();
            if (dailyScheduleCount > 0 && taken >= dailyScheduleCount) {
                streak++;
            } else if (date.equals(today)) {
                // Ignore today if not finished yet
            } else {
                break;
            }
        }

        AdherenceAnalyticsResponse response = new AdherenceAnalyticsResponse();
        response.setAdherenceScore(overallPct);
        response.setCurrentStreakDays(streak);
        response.setTotalDosesScheduled(totalScheduled);
        response.setTotalDosesTaken(totalTaken);
        response.setTotalDosesSkipped(totalSkipped);
        response.setWeeklyBreakdown(weekly);

        return response;
    }
}
