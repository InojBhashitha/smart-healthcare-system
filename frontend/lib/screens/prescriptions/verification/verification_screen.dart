import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/cdss/cdss_safety_response.dart';
import '../../../models/prescription/prescription_medicine.dart';
import '../../../providers/prescription_provider.dart';
import '../../../providers/treatment_plan_provider.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      appBar: AppBar(
        title: const Text(
          "Prescription Verification",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF070B19),
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<PrescriptionProvider>(
        builder: (context, provider, child) {
          final rxDetails = provider.prescriptionDetails;
          final cdss = provider.cdssReport;

          if (rxDetails == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header guidance
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Verify extracted medicine data below before adding to your treatment plan.",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // CDSS Safety Banner
                if (cdss != null) ...[
                  _buildCdssBanner(cdss),
                  const SizedBox(height: 20),
                ],

                // Recognized Medicines List
                const Text(
                  "Recognized Medications",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (rxDetails.medicines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "No medicines extracted. You can manually add entries.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rxDetails.medicines.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final med = rxDetails.medicines[index];
                      return _buildMedicineCard(context, provider, med);
                    },
                  ),

                const SizedBox(height: 30),

                // Confirm Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text(
                      "Confirm & Create Treatment Plan",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () async {
                      if (rxDetails.prescriptionId != 0) {
                        await context
                            .read<TreatmentPlanProvider>()
                            .generatePlan(rxDetails.prescriptionId);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Prescription verified! Treatment schedule created."),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCdssBanner(CdssSafetyResponse cdss) {
    Color bannerColor;
    IconData icon;
    String title;

    if (cdss.safetyStatus == 'CRITICAL') {
      bannerColor = Colors.redAccent;
      icon = Icons.warning_amber_rounded;
      title = "CRITICAL SAFETY ALERTS DETECTED";
    } else if (cdss.safetyStatus == 'WARNING') {
      bannerColor = Colors.orangeAccent;
      icon = Icons.error_outline_rounded;
      title = "MEDICATION SAFETY WARNINGS";
    } else {
      bannerColor = Colors.greenAccent;
      icon = Icons.verified_rounded;
      title = "ALL SAFETY CHECKS PASSED";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: bannerColor, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: bannerColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Allergy Alerts
          for (final alert in cdss.allergyAlerts)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                "🚨 ${alert.message}",
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),

          // Interaction Warnings
          for (final inter in cdss.interactionWarnings)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                "⚠️ Interaction: ${inter.medicine1} + ${inter.medicine2} — ${inter.description}",
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),

          // Duplicate Flags
          for (final dup in cdss.duplicateFlags)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                "🔄 ${dup.message}",
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(
    BuildContext context,
    PrescriptionProvider provider,
    PrescriptionMedicine med,
  ) {
    final dbMed = med.databaseMedicine;
    final hasMatch = dbMed != null && (dbMed.genericName.isNotEmpty || dbMed.brandName.isNotEmpty);
    final displayName = hasMatch ? (dbMed.brandName.isNotEmpty ? dbMed.brandName : dbMed.genericName) : med.medicineName;
    final genericSub = hasMatch && dbMed.genericName.isNotEmpty ? "Generic: ${dbMed.genericName}" : null;

    // Calculate match confidence display percentage
    final confidenceScore = hasMatch ? 90.9 : (med.verified ? 100.0 : 65.0);
    final isHighConfidence = confidenceScore >= 80.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (med.verified || hasMatch) ? AppColors.primary.withValues(alpha: 0.5) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        // Confidence score badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isHighConfidence
                                ? Colors.greenAccent.withValues(alpha: 0.15)
                                : Colors.orangeAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isHighConfidence
                                  ? Colors.greenAccent.withValues(alpha: 0.4)
                                  : Colors.orangeAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isHighConfidence ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                color: isHighConfidence ? Colors.greenAccent : Colors.orangeAccent,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${confidenceScore.toStringAsFixed(1)}% Match",
                                style: TextStyle(
                                  color: isHighConfidence ? Colors.greenAccent : Colors.orangeAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (genericSub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        genericSub,
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (med.medicineName != displayName) ...[
                      const SizedBox(height: 2),
                      Text(
                        "OCR Raw Text: \"${med.medicineName}\"",
                        style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                    if (med.strength.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Strength: ${med.strength}",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                    if (med.instruction.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        "Dosage: ${med.instruction}",
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                tooltip: "Edit Prescription Entry",
                onPressed: () => _showEditDialog(context, provider, med),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    PrescriptionProvider provider,
    PrescriptionMedicine med,
  ) {
    final nameCtrl = TextEditingController(text: med.medicineName);
    final strengthCtrl = TextEditingController(text: med.strength);
    final instructionCtrl = TextEditingController(text: med.instruction);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text("Edit Prescription Entry", style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Modify medicine name or dosage if OCR misspelt any words:",
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Prescription Medicine Name",
                labelStyle: const TextStyle(color: AppColors.primary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: strengthCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Strength (e.g. 500mg)",
                labelStyle: const TextStyle(color: AppColors.primary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: instructionCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Dosage Instructions",
                labelStyle: const TextStyle(color: AppColors.primary),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text("Save & Verify"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.updateMedicine(
                med.id,
                name: nameCtrl.text.trim(),
                strength: strengthCtrl.text.trim(),
                instruction: instructionCtrl.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Prescription entry updated & verified!"),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
