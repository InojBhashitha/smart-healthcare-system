import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/prescription_provider.dart';
import '../../../models/prescription/prescription_summary.dart';

class PrescriptionHistoryScreen extends StatefulWidget {
  const PrescriptionHistoryScreen({super.key});

  @override
  State<PrescriptionHistoryScreen> createState() => _PrescriptionHistoryScreenState();
}

class _PrescriptionHistoryScreenState extends State<PrescriptionHistoryScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Prescription History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFF070B19).withValues(alpha: 0.95),
        elevation: 0,
      ),
      body: Consumer<PrescriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isHistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.prescriptionSummaries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No prescriptions found yet. Upload a prescription to get started.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadPrescriptionHistory,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: provider.prescriptionSummaries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final prescription = provider.prescriptionSummaries[index];
                return _PrescriptionHistoryTile(
                  prescription: prescription,
                  onTap: () async {
                    await provider.loadPrescription(prescription.prescriptionId);
                    if (!context.mounted) return;
                    Navigator.pushNamed(
                      context,
                      AppRoutes.prescriptionDetails,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PrescriptionHistoryTile extends StatelessWidget {
  final PrescriptionSummary prescription;
  final VoidCallback onTap;

  const _PrescriptionHistoryTile({
    required this.prescription,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Container(
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
              children: [
                Expanded(
                  child: Text(
                    'Prescription #${prescription.prescriptionId}',
                    style: AppTextStyles.title.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    prescription.readableUploadedAt,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              prescription.status,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${prescription.medicinesFound} medicines',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.secondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
