import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/patient_profile_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../providers/treatment_plan_provider.dart';
import '../../widgets/buttons/custom_button.dart';
import '../../screens/dashboard/widgets/recent_prescriptions_card.dart';
import 'widgets/active_prescription_tracker.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/next_dose_card.dart';
import 'widgets/overview_module_card.dart';
import 'widgets/weekly_analytics_chart.dart';
import '../pharmacy/pharmacy_map_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      context.read<PrescriptionProvider>().loadPrescriptionHistory(),
      context.read<TreatmentPlanProvider>().loadTodayDoses(),
      context.read<TreatmentPlanProvider>().loadAnalytics(),
      context.read<PatientProfileProvider>().loadProfile(),
      context.read<PharmacyProvider>().searchPharmacies(),
      context.read<NotificationProvider>().loadNotifications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final String displayName = authProvider.userName ?? "User";
    final String email = authProvider.userEmail ??
        "${displayName.toLowerCase().replaceAll(" ", "")}@gmail.com";

    // Select view body depending on current active index
    Widget bodyView;
    switch (_currentIndex) {
      case 0:
        bodyView = _buildHomeTab(context, displayName);
        break;
      case 1:
        bodyView = _buildPharmacyTab(context);
        break;
      case 2:
        bodyView = _buildAlertsTab(context);
        break;
      case 3:
        bodyView = _buildProfileTab(context, displayName, email);
        break;
      default:
        bodyView = _buildHomeTab(context, displayName);
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: bodyView,
        ),
      ),
      // Custom Interactive Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          border: const Border(
            top: BorderSide(
              color: Color(0xFF1E293B),
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home_rounded, "Home", _currentIndex == 0, () {
              setState(() => _currentIndex = 0);
            }),
            _buildNavItem(context, Icons.local_pharmacy_rounded, "Pharmacy", _currentIndex == 1, () {
              setState(() => _currentIndex = 1);
            }),
            
            // Circular Glowing Floating Scanner Button
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.uploadPrescription);
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.primary,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF2563EB),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            _buildNavItem(context, Icons.notifications_rounded, "Alerts", _currentIndex == 2, () {
              setState(() => _currentIndex = 2);
            }),
            _buildNavItem(context, Icons.person_rounded, "Profile", _currentIndex == 3, () {
              setState(() => _currentIndex = 3);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.secondary : AppColors.textDisabled,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.secondary : AppColors.textDisabled,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. HOME VIEW ---
  Widget _buildHomeTab(BuildContext context, String displayName) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: AppSpacing.sm),

                // Dynamic Header
                DashboardHeader(userName: displayName),

                const SizedBox(height: AppSpacing.lg),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                      width: 1.2,
                    ),
                  ),
                  child: const TextField(
                    readOnly: true,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Search medicines, pharmacies...",
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Upload Rx Document Banner
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.uploadPrescription);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                          const Color(0xFF0D9488).withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      border: Border.all(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.electric_bolt_rounded,
                                    color: AppColors.secondary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Upload Rx Document",
                                    style: AppTextStyles.title.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Our neural networks scan handwriting in real-time, matching nearest pharmacy inventory stock instantly.",
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Glowing Square Camera Button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: AppGradients.primary,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Section Label: OVERVIEW MODULES
                const Text(
                  "OVERVIEW MODULES",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDisabled,
                    letterSpacing: 1.0,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Responsive Overview Modules Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double moduleCardWidth =
                        (constraints.maxWidth - AppSpacing.md) / 2;
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        SizedBox(
                          width: moduleCardWidth,
                          child: OverviewModuleCard(
                            title: "OCR Scan",
                            subtitle: "Upload Prescription",
                            icon: Icons.document_scanner_rounded,
                            themeColor: const Color(0xFF3B82F6),
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.uploadPrescription);
                            },
                          ),
                        ),
                        SizedBox(
                          width: moduleCardWidth,
                          child: OverviewModuleCard(
                            title: "0",
                            subtitle: "Reservations",
                            icon: Icons.grid_view_rounded,
                            themeColor: const Color(0xFF8B5CF6),
                            onTap: () {
                              setState(() => _currentIndex = 2); // Switch to Alerts
                            },
                          ),
                        ),
                        SizedBox(
                          width: moduleCardWidth,
                          child: OverviewModuleCard(
                            title: "Medicines",
                            subtitle: "Intake Details",
                            icon: Icons.medication_rounded,
                            themeColor: const Color(0xFF0D9488),
                            onTap: () {},
                          ),
                        ),
                        SizedBox(
                          width: moduleCardWidth,
                          child: OverviewModuleCard(
                            title: "Pharmacies",
                            subtitle: "Locate Stock Map",
                            icon: Icons.map_rounded,
                            themeColor: const Color(0xFF16A34A),
                            onTap: () {
                              setState(() => _currentIndex = 1); // Switch to Pharmacy locator
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Weekly Adherence Analytics Chart with Real Data
                const WeeklyAnalyticsChart(),

                const SizedBox(height: AppSpacing.xl),

                // Section Label: TODAY'S DOSAGE ALARMS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TODAY'S DOSAGE ALARMS",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDisabled,
                        letterSpacing: 1.0,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.todaySchedule);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "View All",
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Next Dose Card
                const NextDoseCard(),

                const SizedBox(height: AppSpacing.lg),

                // Recent Prescriptions Card
                const RecentPrescriptionsCard(),

                const SizedBox(height: AppSpacing.lg),

                // Active Prescription Timeline Tracker
                const ActivePrescriptionTracker(),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. PHARMACY TAB ---
  Widget _buildPharmacyTab(BuildContext context) {
    return const PharmacyMapScreen();
  }

  // --- 3. ALERTS VIEW ---
  Widget _buildAlertsTab(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Alerts Center",
                        style: AppTextStyles.title.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      if (provider.notifications.isNotEmpty)
                        TextButton(
                          onPressed: () => provider.clearAll(),
                          child: const Text("Clear All", style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                "Dosage alarms, safety warnings, and reservation updates",
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),

              Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }

                  final list = provider.notifications;
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            const Icon(Icons.notifications_none_rounded, color: Colors.white38, size: 54),
                            const SizedBox(height: 12),
                            const Text(
                              "No New Alerts",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "You are all caught up! Dosage alarms and safety warnings will appear here.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final int notificationId = item['notificationId'] ?? 0;
                      final String title = item['title'] ?? 'Alert';
                      final String message = item['message'] ?? '';
                      final String type = (item['type'] ?? 'DOSE_REMINDER').toString().toUpperCase();
                      final bool isRead = item['isRead'] ?? false;
                      final String time = item['createdAt'] != null ? item['createdAt'].toString().substring(11, 16) : 'Now';

                      Color typeColor = AppColors.primary;
                      IconData typeIcon = Icons.notifications_active_rounded;

                      if (type == 'SAFETY_WARNING') {
                        typeColor = AppColors.danger;
                        typeIcon = Icons.warning_amber_rounded;
                      } else if (type == 'REFILL_NOTICE') {
                        typeColor = Colors.orangeAccent;
                        typeIcon = Icons.refresh_rounded;
                      } else if (type == 'RESERVATION_CONFIRMED') {
                        typeColor = AppColors.success;
                        typeIcon = Icons.check_circle_rounded;
                      }

                      return InkWell(
                        onTap: () => provider.markAsRead(notificationId),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isRead
                                ? AppColors.card.withValues(alpha: 0.4)
                                : typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.medium),
                            border: Border.all(
                              color: isRead
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : typeColor.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(typeIcon, color: typeColor, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          time,
                                          style: const TextStyle(color: AppColors.textDisabled, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // --- 4. PROFILE VIEW ---
  Widget _buildProfileTab(BuildContext context, String displayName, String email) {
    final nameParts = displayName.trim().split(" ");
    String initials = "JD";
    if (nameParts.isNotEmpty && nameParts.first.isNotEmpty) {
      if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
        initials = "${nameParts[0][0]}${nameParts[1][0]}".toUpperCase();
      } else {
        initials = nameParts[0][0].toUpperCase();
      }
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppSpacing.sm),
              // Profile Header Profile Card
              Consumer<PatientProfileProvider>(
                builder: (context, profileProvider, child) {
                  final allergiesCount = profileProvider.allergies.length;
                  final activeMedsCount = profileProvider.activeMedications.length;

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E293B).withValues(alpha: 0.8),
                          const Color(0xFF0F172A).withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppGradients.primary,
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  initials,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "PATIENT VERIFIED",
                                      style: TextStyle(color: AppColors.secondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  "$allergiesCount",
                                  style: TextStyle(
                                    color: allergiesCount > 0 ? AppColors.danger : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Drug Allergies",
                                  style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 24, color: Colors.white10),
                            Column(
                              children: [
                                Text(
                                  "$activeMedsCount",
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Active Meds",
                                  style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 24, color: Colors.white10),
                            Column(
                              children: [
                                const Text(
                                  "O+",
                                  style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Blood Group",
                                  style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              
              const Text(
                "PERSONAL HEALTH PROFILE",
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textDisabled, letterSpacing: 1.0),
              ),
              const SizedBox(height: AppSpacing.md),
              
              _buildSettingTile(
                Icons.picture_as_pdf_rounded,
                "Export Health Summary (PDF)",
                "Download doctor-ready PDF report of allergies & adherence",
                onTap: () {
                  context.read<NotificationProvider>().downloadPdfReport(context);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingTile(
                Icons.medical_services_rounded,
                "Personal Health Record",
                "Manage drug allergies, active meds, and safety profile",
                onTap: () => _showPersonalHealthRecordModal(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingTile(
                Icons.devices_rounded,
                "Connected Devices",
                "Smart pillbox, monitors, and Bluetooth status",
                onTap: () => _showConnectedDevicesModal(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingTile(
                Icons.history_rounded,
                "Prescription History",
                "Access scanned database history & verified Rx records",
                onTap: () => _showPrescriptionHistoryModal(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingTile(
                Icons.settings_rounded,
                "Account Preferences",
                "System styling, notifications, dark mode, language",
                onTap: () => _showAccountPreferencesModal(context),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Animated Logout Button
              CustomButton(
                text: "Sign Out",
                icon: Icons.logout_rounded,
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
              ),
              const SizedBox(height: 50),
            ]),
          ),
        ),
      ],
    );
  }

  // --- PROFILE MODAL HANDLERS ---
  void _showPersonalHealthRecordModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Consumer<PatientProfileProvider>(
              builder: (context, provider, child) {
                final allergies = provider.allergies;
                final activeMeds = provider.activeMedications;

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Personal Health Record",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Allergies Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "KNOWN DRUG ALLERGIES",
                          style: TextStyle(color: AppColors.textDisabled, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddAllergyDialog(context),
                          icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
                          label: const Text("Add Allergy", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (allergies.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "No drug allergies logged. Tap 'Add Allergy' if you have known medication reactions.",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      )
                    else
                      Column(
                        children: allergies.map((a) {
                          final int id = a['allergyId'] ?? 0;
                          final String name = a['allergenName'] ?? 'Unknown';
                          final String severity = a['severity'] ?? 'HIGH';
                          final Color sevColor = severity == 'HIGH' ? AppColors.danger : Colors.orangeAccent;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.card.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: sevColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: sevColor, size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: sevColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        severity,
                                        style: TextStyle(color: sevColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 18),
                                      onPressed: () => provider.deleteAllergy(id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 20),

                    // Active Medications Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "CURRENT ACTIVE MEDICATIONS",
                          style: TextStyle(color: AppColors.textDisabled, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (activeMeds.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "No active medications currently registered.",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      )
                    else
                      Column(
                        children: activeMeds.map((m) {
                          final int id = m['medicationId'] ?? 0;
                          final String name = m['medicineName'] ?? '';
                          final String strength = m['strength'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.card.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.medication_rounded, color: AppColors.primary, size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      "$name $strength",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 18),
                                  onPressed: () => provider.deleteMedication(id),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddAllergyDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String severity = "HIGH";

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("Add Drug Allergy", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Allergen Name (e.g. Penicillin, Aspirin)",
                  labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: severity,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Severity Level"),
                items: const [
                  DropdownMenuItem(value: "HIGH", child: Text("HIGH (Severe Reaction)")),
                  DropdownMenuItem(value: "MEDIUM", child: Text("MEDIUM (Moderate Rash)")),
                  DropdownMenuItem(value: "LOW", child: Text("LOW (Mild Sensitivity)")),
                ],
                onChanged: (val) {
                  if (val != null) severity = val;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  await context.read<PatientProfileProvider>().addAllergy(
                    allergenName: nameCtrl.text.trim(),
                    severity: severity,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _showConnectedDevicesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bluetooth_connected_rounded, color: AppColors.secondary, size: 48),
              const SizedBox(height: 12),
              const Text("MediSync Smart Pillbox", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Connected via Bluetooth LE 5.0 • Battery: 88%", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.card.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Auto Dose Dispenser", style: TextStyle(color: Colors.white, fontSize: 13)),
                    Text("ONLINE", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrescriptionHistoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) {
            return Consumer<PrescriptionProvider>(
              builder: (context, provider, child) {
                final list = provider.prescriptionSummaries;

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    const Text("Prescription Database History", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Scanned OCR database records", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 16),
                    if (list.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("No scanned prescriptions found.", style: TextStyle(color: Colors.white54))))
                    else
                      Column(
                        children: list.map((item) {
                          final String rxId = "Rx #${item.prescriptionId}";
                          final String date = item.readableUploadedAt;
                          final String status = item.status.isNotEmpty ? item.status : 'VERIFIED';
                          final int medCount = item.medicinesFound;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.card.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(rxId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text("$date • $medCount Medicines Found", style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(status, style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAccountPreferencesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Account Preferences", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.dark_mode_rounded, color: AppColors.primary),
                title: const Text("Dark Glassmorphism Theme", style: TextStyle(color: Colors.white, fontSize: 14)),
                trailing: const Text("ENABLED", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_rounded, color: AppColors.secondary),
                title: const Text("Push Alarms & Reminders", style: TextStyle(color: Colors.white, fontSize: 14)),
                trailing: const Text("ACTIVE", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              ListTile(
                leading: const Icon(Icons.language_rounded, color: Colors.purpleAccent),
                title: const Text("System Language", style: TextStyle(color: Colors.white, fontSize: 14)),
                trailing: const Text("English (US)", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                child: const Text("Done"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white70, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.textDisabled,
            size: 12,
          ),
        ],
      ),
    ),
    );
  }
}