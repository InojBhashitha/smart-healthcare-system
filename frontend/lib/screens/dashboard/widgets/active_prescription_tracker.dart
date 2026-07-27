import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class ActivePrescriptionTracker extends StatelessWidget {
  const ActivePrescriptionTracker({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo steps data
    final List<Map<String, dynamic>> steps = [
      {"title": "Uploaded", "status": StepStatus.completed},
      {"title": "OCR Scanned", "status": StepStatus.completed},
      {"title": "Drug Check", "status": StepStatus.active},
      {"title": "Verified", "status": StepStatus.pending},
    ];

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Latest Scan Status",
                      style: AppTextStyles.title.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Prescription #3892 • General Hospital",
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Processing",
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final String title = step["title"];
              final StepStatus status = step["status"];

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Left connection line
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color: index == 0
                                ? Colors.transparent
                                : (status == StepStatus.completed ||
                                        status == StepStatus.active
                                    ? AppColors.primary
                                    : AppColors.divider),
                          ),
                        ),
                        // Circular node indicator
                        _buildNode(status),
                        // Right connection line
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color: index == steps.length - 1
                                ? Colors.transparent
                                : (steps[index + 1]["status"] ==
                                            StepStatus.completed
                                    ? AppColors.primary
                                    : AppColors.divider),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: status == StepStatus.active
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: status == StepStatus.pending
                            ? AppColors.textDisabled
                            : (status == StepStatus.active
                                ? AppColors.warning
                                : Colors.white),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNode(StepStatus status) {
    if (status == StepStatus.completed) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 14,
        ),
      );
    } else if (status == StepStatus.active) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Outer glowing ring
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
          ),
          // Intermediate ring
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          // Inner core dot
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      );
    } else {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.divider,
            width: 2,
          ),
        ),
      );
    }
  }
}

enum StepStatus {
  completed,
  active,
  pending,
}
