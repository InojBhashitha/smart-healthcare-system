import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/treatment_plan_provider.dart';

class WeeklyAnalyticsChart extends StatelessWidget {
  const WeeklyAnalyticsChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TreatmentPlanProvider>(
      builder: (context, provider, child) {
        final analytics = provider.analytics;
        final double adherenceScore = analytics?['adherenceScore']?.toDouble() ?? 100.0;
        final int streak = analytics?['currentStreakDays'] ?? 0;
        final List breakdown = analytics?['weeklyBreakdown'] as List? ?? [];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Adherence Analytics",
                        style: AppTextStyles.title.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "7-Day Medication Compliance",
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "🔥 $streak d",
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.stars_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Score: ${adherenceScore.toStringAsFixed(1)}%",
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: breakdown.isEmpty
                    ? _buildPlaceholderBars()
                    : breakdown.map<Widget>((item) {
                        final String day = item['dayOfWeek'] ?? '';
                        final double pct = (item['percentage'] as num? ?? 0).toDouble();
                        final bool isFull = pct >= 90.0;
                        final double barHeight = (pct / 100.0) * 80.0;

                        return Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  width: 14,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                Container(
                                  width: 14,
                                  height: barHeight < 8 ? 8 : barHeight,
                                  decoration: BoxDecoration(
                                    color: isFull ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              day,
                              style: TextStyle(
                                color: isFull ? Colors.white : AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPlaceholderBars() {
    final days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
    return days.map((d) => Column(
      children: [
        Container(
          width: 14,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(d, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    )).toList();
  }
}

