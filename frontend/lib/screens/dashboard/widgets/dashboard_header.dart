import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;

  const DashboardHeader({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final nameParts = userName.trim().split(" ");
    String initials = "JD";
    if (nameParts.isNotEmpty && nameParts.first.isNotEmpty) {
      if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
        initials = "${nameParts[0][0]}${nameParts[1][0]}".toUpperCase();
      } else {
        initials = nameParts[0][0].toUpperCase();
      }
    }

    return Row(
      children: [
        // Initials Avatar
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primary,
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, $userName",
                style: AppTextStyles.headline.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                "Complete your dosage today",
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.divider,
              width: 1,
            ),
          ),
          child: IconButton(
            tooltip: "Patient Safety & Allergies",
            onPressed: () {
              Navigator.pushNamed(context, "/patient-profile");
            },
            icon: const Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.divider,
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

