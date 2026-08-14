package com.smarthealthcare.backend.treatment.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class AdherenceAnalyticsResponse {

    private double adherenceScore; // Percentage e.g. 92.5
    private int currentStreakDays;
    private int totalDosesScheduled;
    private int totalDosesTaken;
    private int totalDosesSkipped;
    private List<DailyAdherence> weeklyBreakdown = new ArrayList<>();

    @Getter
    @Setter
    @AllArgsConstructor
    @NoArgsConstructor
    public static class DailyAdherence {
        private String dayOfWeek; // MON, TUE, WED, etc.
        private String date; // YYYY-MM-DD
        private int scheduledCount;
        private int takenCount;
        private double percentage;
    }
}
