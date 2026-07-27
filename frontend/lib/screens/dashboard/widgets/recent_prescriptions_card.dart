import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/prescription_provider.dart';

class RecentPrescriptionsCard extends StatefulWidget {
  const RecentPrescriptionsCard({super.key});

  @override
  State<RecentPrescriptionsCard> createState() =>
      _RecentPrescriptionsCardState();
}

class _RecentPrescriptionsCardState extends State<RecentPrescriptionsCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PrescriptionProvider>();
      if (provider.prescriptionSummaries.isEmpty) {
        provider.loadPrescriptionHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrescriptionProvider>(
      builder: (context, provider, child) {
        final prescriptions = provider.prescriptionSummaries.take(3).toList();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Prescriptions',
                    style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.prescriptionHistory,
                      );
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (prescriptions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'No prescriptions yet',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...prescriptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final prescription = entry.value;
                  final isLast = index == prescriptions.length - 1;

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await provider.loadPrescription(
                            prescription.prescriptionId,
                          );
                          if (!context.mounted) return;
                          Navigator.pushNamed(
                            context,
                            AppRoutes.prescriptionDetails,
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.description_rounded,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Prescription #${prescription.prescriptionId}',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${prescription.medicinesFound} items • ${prescription.status}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast) ...[
                        const SizedBox(height: AppSpacing.md),
                        Divider(
                          color: Colors.white.withValues(alpha: 0.08),
                          height: 1,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
