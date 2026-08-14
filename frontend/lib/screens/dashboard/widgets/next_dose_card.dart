import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/treatment_plan_provider.dart';

class NextDoseCard extends StatefulWidget {
  const NextDoseCard({super.key});

  @override
  State<NextDoseCard> createState() => _NextDoseCardState();
}

class _NextDoseCardState extends State<NextDoseCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TreatmentPlanProvider>().loadTodayDoses();
      context.read<TreatmentPlanProvider>().loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TreatmentPlanProvider>(
      builder: (context, provider, child) {
        final todayDoses = provider.todayDoses;

        if (provider.isLoading) {
          return Container(
            height: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: const CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (todayDoses.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "No Scheduled Doses Today",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        "Scan or upload a prescription to generate a smart daily dosage plan.",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final nextDose = todayDoses.firstWhere(
          (d) => d['status'] == 'PENDING',
          orElse: () => todayDoses.first,
        );

        final isTaken = nextDose['status'] == 'TAKEN';
        final String medName = nextDose['medicineName'] ?? 'Medication';
        final String strength = nextDose['strength'] ?? '';
        final String instruction = nextDose['instruction'] ?? '';
        final String slot = nextDose['doseSlot'] ?? 'MORNING';
        final int scheduleId = nextDose['scheduleId'] ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: isTaken
                  ? AppColors.success.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isTaken
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTaken ? Icons.check_circle_rounded : Icons.alarm_rounded,
                      color: isTaken ? AppColors.success : AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: isTaken
                          ? [
                              const Text(
                                "Dose Completed!",
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "You took $medName ($strength)",
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ]
                          : [
                              Wrap(
                                spacing: 8,
                                children: [
                                  Text(
                                    "Next Scheduled Dose ($slot)",
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                medName,
                                style: AppTextStyles.title.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (strength.isNotEmpty || instruction.isNotEmpty)
                                Text(
                                  "$strength ${instruction.isNotEmpty ? '• $instruction' : ''}",
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                    ),
                  ),
                  _buildActionButton(context, provider, scheduleId, isTaken),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    TreatmentPlanProvider provider,
    int scheduleId,
    bool isTaken,
  ) {
    if (isTaken) {
      return IconButton(
        onPressed: () async {
          await provider.logDoseStatus(scheduleId, "PENDING");
        },
        icon: const Icon(Icons.undo_rounded, color: AppColors.textSecondary),
      );
    }

    return ElevatedButton(
      onPressed: () async {
        await provider.logDoseStatus(scheduleId, "TAKEN");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Dose recorded as taken!"),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        foregroundColor: AppColors.success,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: const BorderSide(color: AppColors.success, width: 1),
        ),
      ),
      child: const Text("Take", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

