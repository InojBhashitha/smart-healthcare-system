import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/treatment_plan_provider.dart';

class TodayDoseScheduleScreen extends StatefulWidget {
  const TodayDoseScheduleScreen({super.key});

  @override
  State<TodayDoseScheduleScreen> createState() => _TodayDoseScheduleScreenState();
}

class _TodayDoseScheduleScreenState extends State<TodayDoseScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TreatmentPlanProvider>().loadTodayDoses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      appBar: AppBar(
        title: const Text(
          "Today's Dosage Schedule",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF070B19),
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<TreatmentPlanProvider>(
        builder: (context, provider, child) {
          final doses = provider.todayDoses;

          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (doses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.alarm_off_rounded, color: Colors.white38, size: 54),
                  const SizedBox(height: 16),
                  const Text(
                    "No Scheduled Doses Today",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Upload a prescription to generate your daily dosage plan.",
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // Group doses by slot (MORNING, AFTERNOON, EVENING, NIGHT)
          final Map<String, List<dynamic>> grouped = {
            "MORNING": [],
            "AFTERNOON": [],
            "EVENING": [],
            "NIGHT": [],
          };

          for (final item in doses) {
            final slot = (item['doseSlot'] as String? ?? 'MORNING').toUpperCase();
            if (grouped.containsKey(slot)) {
              grouped[slot]!.add(item);
            } else {
              grouped.putIfAbsent("MORNING", () => []).add(item);
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSlotSection("🌅 MORNING (08:00 AM)", grouped["MORNING"]!, provider),
                _buildSlotSection("☀️ AFTERNOON (01:00 PM)", grouped["AFTERNOON"]!, provider),
                _buildSlotSection("🌆 EVENING (08:00 PM)", grouped["EVENING"]!, provider),
                _buildSlotSection("🌙 NIGHT (10:00 PM)", grouped["NIGHT"]!, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotSection(
    String title,
    List<dynamic> slotDoses,
    TreatmentPlanProvider provider,
  ) {
    if (slotDoses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: slotDoses.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = slotDoses[index];
            final bool isTaken = item['status'] == 'TAKEN';
            final String name = item['medicineName'] ?? 'Medication';
            final String strength = item['strength'] ?? '';
            final String instruction = item['instruction'] ?? '';
            final int scheduleId = item['scheduleId'] ?? 0;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isTaken
                    ? AppColors.success.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isTaken
                      ? AppColors.success.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isTaken
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTaken ? Icons.check_circle_rounded : Icons.alarm_rounded,
                      color: isTaken ? AppColors.success : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            decoration: isTaken ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (strength.isNotEmpty || instruction.isNotEmpty)
                          Text(
                            "$strength ${instruction.isNotEmpty ? '• $instruction' : ''}",
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final newStatus = isTaken ? "PENDING" : "TAKEN";
                      await provider.logDoseStatus(scheduleId, newStatus);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTaken
                          ? Colors.white10
                          : AppColors.success.withValues(alpha: 0.2),
                      foregroundColor: isTaken ? Colors.white70 : AppColors.success,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isTaken ? Colors.white24 : AppColors.success,
                        ),
                      ),
                    ),
                    child: Text(
                      isTaken ? "Undo" : "Take",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
