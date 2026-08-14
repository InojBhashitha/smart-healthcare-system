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
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                "Find Pharmacies",
                style: AppTextStyles.title.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Locate partner stocks in your area",
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Map Search Input
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
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: "Search pharmacy by name or location...",
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.secondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Glowing Interactive Map Mockup Card
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.large - 1.5),
                  child: Stack(
                    children: [
                      // Stylized Map Canvas grid lines
                      Container(
                        color: const Color(0xFF070B19),
                        child: CustomPaint(
                          painter: const _MapGridPainter(),
                          child: Container(),
                        ),
                      ),
                      // Mock Pin drops
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.my_location_rounded, color: Colors.blue, size: 22),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on_rounded, color: AppColors.danger, size: 30),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                                  ),
                                  child: const Text(
                                    "Ceylon Pharma Partner - 0.8km",
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              const Text(
                "PARTNER PHARMACIES NEARBY",
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textDisabled, letterSpacing: 1.0),
              ),
              const SizedBox(height: AppSpacing.md),
              
              Consumer<PharmacyProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }

                  final pharmacies = provider.pharmacies;
                  if (pharmacies.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          "No partner pharmacies found nearby.",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pharmacies.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final item = pharmacies[index];
                      final int pharmacyId = item['pharmacyId'] ?? 0;
                      final String name = item['name'] ?? 'Pharmacy';
                      final String address = item['address'] ?? '';
                      final double distanceKm = (item['distanceKm'] as num? ?? 0.0).toDouble();
                      final String stockStatus = item['stockStatus'] ?? 'IN_STOCK';
                      final String phone = item['phone'] ?? '';

                      return _buildPharmacyCard(
                        context: context,
                        pharmacyId: pharmacyId,
                        name: name,
                        address: address,
                        distance: "${distanceKm.toStringAsFixed(1)} km",
                        stockStatus: stockStatus,
                        phone: phone,
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

  Widget _buildPharmacyCard({
    required BuildContext context,
    required int pharmacyId,
    required String name,
    required String address,
    required String distance,
    required String stockStatus,
    required String phone,
  }) {
    final bool isAvailable = stockStatus == 'IN_STOCK';
    final bool isLow = stockStatus == 'LOW_STOCK';
    final statusColor = isAvailable
        ? AppColors.success
        : (isLow ? Colors.amber : AppColors.danger);
    final statusText = isAvailable
        ? "Stock Available"
        : (isLow ? "Low Stock" : "Out of Stock");

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, color: AppColors.textDisabled, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: const TextStyle(color: AppColors.textDisabled, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    distance,
                    style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMiniActionBtn(Icons.call_rounded, () {}),
                      const SizedBox(width: 6),
                      _buildMiniActionBtn(Icons.directions_rounded, () {}),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: stockStatus == 'OUT_OF_STOCK'
                  ? null
                  : () => _handleReservePrescription(context, pharmacyId, name),
              icon: const Icon(Icons.bookmark_add_rounded, size: 16),
              label: const Text("Reserve Prescription", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleReservePrescription(BuildContext context, int pharmacyId, String pharmacyName) async {
    final rxProvider = context.read<PrescriptionProvider>();
    final rxList = rxProvider.prescriptionSummaries;

    if (rxList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No prescription available to reserve. Please upload a prescription first."),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final latestRxId = rxList.first.prescriptionId;

    try {
      final reservation = await context.read<PharmacyProvider>().createReservation(
        prescriptionId: latestRxId,
        pharmacyId: pharmacyId,
      );

      if (context.mounted && reservation != null) {
        _showDigitalPickupPassDialog(context, reservation, pharmacyName);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to reserve: $e"), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showDigitalPickupPassDialog(BuildContext context, Map<String, dynamic> reservation, String pharmacyName) {
    final code = reservation['pickupCode'] ?? 'RX-RES-8492';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
            SizedBox(height: 8),
            Text(
              "Reservation Confirmed!",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Your medicines have been reserved at $pharmacyName.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Column(
                children: [
                  const Text(
                    "DIGITAL PICKUP CODE",
                    style: TextStyle(color: AppColors.textDisabled, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    code,
                    style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Show this code at the pharmacy counter to collect your medicines.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniActionBtn(IconData icon, VoidCallback onTap) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 14),
        onPressed: onTap,
      ),
    );
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
              Container(
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
                child: Row(
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
              _buildSettingTile(Icons.medical_services_rounded, "Personal Health Record", "Blood group, conditions, and diagnoses"),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingTile(Icons.devices_rounded, "Connected Devices", "Smart pillbox, monitors, and sensors"),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingTile(Icons.history_rounded, "Prescription History", "Access scanned database history"),
              const SizedBox(height: AppSpacing.sm),
              _buildSettingTile(Icons.settings_rounded, "Account Preferences", "System styling, dark mode, language"),
              
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

// --- MAP BACKGROUND GRID PAINTER ---
class _MapGridPainter extends CustomPainter {
  const _MapGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 25) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 25) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    final pathPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    final road = Path();
    road.moveTo(0, size.height * 0.2);
    road.quadraticBezierTo(size.width * 0.4, size.height * 0.1, size.width * 0.5, size.height * 0.5);
    road.quadraticBezierTo(size.width * 0.6, size.height * 0.9, size.width, size.height * 0.8);
    canvas.drawPath(road, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}