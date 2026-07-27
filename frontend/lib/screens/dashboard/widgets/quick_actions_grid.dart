import 'package:flutter/material.dart';

import 'quick_action_card.dart';

import '../../../core/routes/app_routes.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      crossAxisCount: 2,

      crossAxisSpacing: 16,

      mainAxisSpacing: 16,

      childAspectRatio: 1.3,

      children: [
        QuickActionCard(
          title: "Upload",
          icon: Icons.upload_file_rounded,
          color: const Color(0xFF3B82F6),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.uploadPrescription,
            );
          },
        ),

        QuickActionCard(
          title: "Prescriptions",
          icon: Icons.description_rounded,
          color: const Color(0xFF10B981),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.prescriptionHistory,
            );
          },
        ),

        QuickActionCard(
          title: "Interactions",
          icon: Icons.medication_liquid_rounded,
          color: const Color(0xFFF59E0B),
          onTap: () {},
        ),

        QuickActionCard(
          title: "Profile",
          icon: Icons.person_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () {},
        ),
      ],

    );
  }
}