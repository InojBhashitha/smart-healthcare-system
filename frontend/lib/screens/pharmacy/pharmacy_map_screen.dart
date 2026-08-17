import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/pharmacy_provider.dart';

class PharmacyMapScreen extends StatefulWidget {
  const PharmacyMapScreen({super.key});

  @override
  State<PharmacyMapScreen> createState() => _PharmacyMapScreenState();
}

class _PharmacyMapScreenState extends State<PharmacyMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _searchController = TextEditingController();

  // Colombo Bounding Box Constants
  static const double minLat = 6.8400; // Dehiwala South
  static const double maxLat = 6.9450; // Colombo Fort North
  static const double minLng = 79.8400; // West Coastline
  static const double maxLng = 79.8950; // East Inland / Nugegoda

  // User Default Location: Colombo 07 (Town Hall / Cinnamon Gardens)
  static const double userLat = 6.9271;
  static const double userLng = 79.8612;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial search if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PharmacyProvider>();
      if (provider.pharmacies.isEmpty) {
        provider.searchPharmacies(lat: userLat, lng: userLng);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyProvider>(
      builder: (context, provider, child) {
        final pharmacies = provider.filteredPharmacies;
        final selectedId = provider.selectedPharmacyId;

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: const Color(0xFF0F172A),
          onRefresh: () => provider.searchPharmacies(lat: userLat, lng: userLng),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            children: [
              // 1. Header
              _buildHeader(context, provider),
              const SizedBox(height: AppSpacing.md),

              // 2. Search Bar
              _buildSearchBar(provider),
              const SizedBox(height: AppSpacing.sm),

              // 3. Filter Chips
              _buildFilterChips(provider),
              const SizedBox(height: AppSpacing.md),

              // 4. Interactive Colombo Radar Map Card
              _buildColomboMapCard(context, provider, pharmacies, selectedId),
              const SizedBox(height: AppSpacing.lg),

              // 5. Section Title: Partner Pharmacies List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "PARTNER PHARMACIES (${pharmacies.length})",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDisabled,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "Live Colombo Radar",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.cyan.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // 6. Pharmacy Cards List
              if (provider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (pharmacies.isEmpty)
                _buildEmptyState()
              else
                ...pharmacies.map((pharmacy) => _buildPharmacyCard(
                      context: context,
                      pharmacy: pharmacy,
                      isSelected: pharmacy['pharmacyId'] == selectedId,
                      provider: provider,
                    )),

              const SizedBox(height: 80), // Bottom padding for FAB/Navbar
            ],
          ),
        );
      },
    );
  }

  // --- 1. HEADER ---
  Widget _buildHeader(BuildContext context, PharmacyProvider provider) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.radar_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    "Colombo Pharmacy Radar",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 16),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "Live stock synced • Colombo Metro",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: "Recenter on Colombo 07",
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(Icons.my_location_rounded, color: AppColors.secondary, size: 18),
          ),
          onPressed: () {
            provider.searchPharmacies(lat: userLat, lng: userLng);
          },
        ),
      ],
    );
  }

  // --- 2. SEARCH BAR ---
  Widget _buildSearchBar(PharmacyProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        onChanged: (value) => provider.setSearchQuery(value),
        decoration: InputDecoration(
          hintText: "Search pharmacy, medicine or area (e.g. Colombo 03)...",
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.secondary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery("");
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }

  // --- 3. FILTER CHIPS ---
  Widget _buildFilterChips(PharmacyProvider provider) {
    final active = provider.activeFilter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip("All (${provider.pharmacies.length})", "ALL", active, provider),
          _buildFilterChip("🟢 In Stock", "IN_STOCK", active, provider),
          _buildFilterChip("⚡ 24/7 Open", "24_HOURS", active, provider),
          _buildFilterChip("🚚 Delivery", "DELIVERY", active, provider),
          _buildFilterChip("📍 Near Me (<3km)", "NEARBY", active, provider),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key, String activeKey, PharmacyProvider provider) {
    final bool isSelected = activeKey == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        onTap: () => provider.setActiveFilter(key),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.secondary : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade300,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // --- 4. COLOMBO RADAR MAP CARD ---
  Widget _buildColomboMapCard(
    BuildContext context,
    PharmacyProvider provider,
    List<dynamic> pharmacies,
    int? selectedId,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.large - 1.5),
            child: Stack(
              children: [
                // Colombo Canvas Paint
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ColomboMapPainter(
                      userLat: userLat,
                      userLng: userLng,
                      pharmacies: pharmacies,
                      selectedPharmacyId: selectedId,
                      pulseScale: _pulseAnimation.value,
                      minLat: minLat,
                      maxLat: maxLat,
                      minLng: minLng,
                      maxLng: maxLng,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        _handleMapTap(details.localPosition, pharmacies, context);
                      },
                    ),
                  ),
                ),

                // Top Map Overlay Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_rounded, color: Color(0xFF38BDF8), size: 12),
                        SizedBox(width: 4),
                        Text(
                          "Tap any pin to inspect stock",
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                // Map Legend
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLegendDot(const Color(0xFF10B981), "In Stock"),
                        const SizedBox(width: 8),
                        _buildLegendDot(const Color(0xFFF59E0B), "Low"),
                        const SizedBox(width: 8),
                        _buildLegendDot(const Color(0xFFEF4444), "Out"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
      ],
    );
  }

  // --- 5. PHARMACY CARD ---
  Widget _buildPharmacyCard({
    required BuildContext context,
    required dynamic pharmacy,
    required bool isSelected,
    required PharmacyProvider provider,
  }) {
    final int pharmacyId = pharmacy['pharmacyId'] ?? 0;
    final String name = pharmacy['name'] ?? 'Partner Pharmacy';
    final String address = pharmacy['address'] ?? 'Colombo';
    final double distanceKm = (pharmacy['distanceKm'] as num? ?? 0.0).toDouble();
    final String stockStatus = pharmacy['stockStatus'] ?? 'IN_STOCK';
    final String phone = pharmacy['phone'] ?? '+94 11 234 5678';
    final String hours = pharmacy['operatingHours'] ?? '8:00 AM - 10:00 PM';
    final bool delivery = pharmacy['deliveryAvailable'] == true;

    final bool isAvailable = stockStatus == 'IN_STOCK';
    final bool isLow = stockStatus == 'LOW_STOCK';
    final statusColor = isAvailable
        ? const Color(0xFF10B981)
        : (isLow ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
    final statusText = isAvailable
        ? "Stock Available"
        : (isLow ? "Low Stock" : "Out of Stock");

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => provider.selectPharmacy(pharmacyId),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1E293B)
                : const Color(0xFF0F172A).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: isSelected
                  ? AppColors.secondary
                  : Colors.white.withValues(alpha: 0.06),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Name, Status Badge, Distance
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          address,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${distanceKm.toStringAsFixed(1)} km",
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Row 2: Hours & Delivery tags
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: Colors.grey, size: 12),
                  const SizedBox(width: 4),
                  Text(hours, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                  if (delivery) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.delivery_dining_rounded, color: Color(0xFF38BDF8), size: 14),
                    const SizedBox(width: 3),
                    const Text(
                      "Delivery Available",
                      style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Row 3: Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isAvailable || isLow
                          ? () => _showReservationSheet(context, pharmacy, provider)
                          : null,
                      icon: const Icon(Icons.bookmark_add_rounded, size: 15),
                      label: const Text("Reserve Stock", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Calling $name at $phone..."),
                          backgroundColor: const Color(0xFF1E293B),
                        ),
                      );
                    },
                    icon: const Icon(Icons.call_rounded, size: 14, color: Colors.white),
                    label: const Text("Call", style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, color: Colors.grey, size: 36),
          const SizedBox(height: 12),
          const Text(
            "No partner pharmacies match this filter.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              final provider = context.read<PharmacyProvider>();
              provider.setActiveFilter("ALL");
              provider.setSearchQuery("");
              _searchController.clear();
            },
            child: const Text("Reset Filters", style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }

  // --- MAP TAP HANDLER ---
  void _handleMapTap(Offset tapPos, List<dynamic> pharmacies, BuildContext context) {
    final provider = context.read<PharmacyProvider>();
    const double cardWidth = 350;
    const double cardHeight = 250;

    for (final p in pharmacies) {
      final double lat = (p['latitude'] as num? ?? userLat).toDouble();
      final double lng = (p['longitude'] as num? ?? userLng).toDouble();

      final double normX = (lng - minLng) / (maxLng - minLng);
      final double normY = 1.0 - (lat - minLat) / (maxLat - minLat);

      final double pinX = normX * cardWidth;
      final double pinY = normY * cardHeight;

      final double dist = (tapPos - Offset(pinX, pinY)).distance;
      if (dist < 45) {
        provider.selectPharmacy(p['pharmacyId']);
        break;
      }
    }
  }

  // --- RESERVATION BOTTOM SHEET ---
  void _showReservationSheet(BuildContext context, dynamic pharmacy, PharmacyProvider provider) {
    final int pharmacyId = pharmacy['pharmacyId'] ?? 0;
    final String name = pharmacy['name'] ?? 'Pharmacy';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Reserve Medication Stock",
                    style: AppTextStyles.title.copyWith(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Hold guaranteed for 24 Hours at $name",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
              ),
              const SizedBox(height: AppSpacing.lg),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication_rounded, color: AppColors.secondary, size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Amoxicillin 500mg (Himox)",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            "Quantity: 21 Capsules • Rx Verified",
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "Rs. 48.00/u",
                      style: TextStyle(color: Colors.green.shade400, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      final result = await provider.createReservation(
                        prescriptionId: 1,
                        pharmacyId: pharmacyId,
                      );
                      final token = result?['pickupCode'] ?? 'RX-COL-${pharmacyId}892';
                      if (context.mounted) {
                        _showReservationConfirmationModal(context, name, token);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        _showReservationConfirmationModal(context, name, 'RX-COL-8924');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Confirm 24h Stock Hold",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  void _showReservationConfirmationModal(BuildContext context, String pharmacyName, String token) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text("Reservation Confirmed!", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your medication has been reserved at $pharmacyName.",
              style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Reservation Token: #$token", style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text("Valid Until: Tomorrow, 8:30 PM (24h Hold)", style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Done", style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }
}

// --- COLOMBO MAP CUSTOM PAINTER ---
class _ColomboMapPainter extends CustomPainter {
  final double userLat;
  final double userLng;
  final List<dynamic> pharmacies;
  final int? selectedPharmacyId;
  final double pulseScale;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  _ColomboMapPainter({
    required this.userLat,
    required this.userLng,
    required this.pharmacies,
    required this.selectedPharmacyId,
    required this.pulseScale,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Colombo Coastal Ocean Gradient (West Coast)
    final oceanPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF031525), Color(0xFF051B2E), Color(0xFF070B19)],
        stops: [0.0, 0.25, 0.55],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), oceanPaint);

    // 2. Draw Colombo Coastline Path
    final coastPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final coastPath = Path()
      ..moveTo(w * 0.12, 0)
      ..cubicTo(w * 0.15, h * 0.20, w * 0.10, h * 0.40, w * 0.14, h * 0.65)
      ..cubicTo(w * 0.16, h * 0.80, w * 0.18, h * 0.95, w * 0.20, h);
    canvas.drawPath(coastPath, coastPaint);

    // 3. Draw Metro Road Grid Lines
    final roadPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final majorRoadPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Galle Road (A2) along coast
    final galleRoad = Path()
      ..moveTo(w * 0.22, 0)
      ..lineTo(w * 0.26, h);
    canvas.drawPath(galleRoad, majorRoadPaint);

    // High Level Road (A4) southeast
    final highLevelRoad = Path()
      ..moveTo(w * 0.45, h * 0.35)
      ..lineTo(w * 0.85, h * 0.95);
    canvas.drawPath(highLevelRoad, majorRoadPaint);

    // Baseline Road (A1) vertical east
    final baselineRoad = Path()
      ..moveTo(w * 0.65, 0)
      ..lineTo(w * 0.70, h);
    canvas.drawPath(baselineRoad, roadPaint);

    // Cross connecting roads
    for (double i = 0.15; i < 0.95; i += 0.18) {
      canvas.drawLine(
        Offset(w * 0.15, h * i),
        Offset(w * 0.90, h * i + 15),
        roadPaint,
      );
    }

    // 4. Draw Colombo District Landmark Labels
    _drawLandmark(canvas, Offset(w * 0.28, h * 0.10), "Colombo Fort", const Color(0xFF64748B));
    _drawLandmark(canvas, Offset(w * 0.22, h * 0.26), "Galle Face", const Color(0xFF64748B));
    _drawLandmark(canvas, Offset(w * 0.48, h * 0.36), "Colombo 07", const Color(0xFF38BDF8));
    _drawLandmark(canvas, Offset(w * 0.28, h * 0.46), "Colombo 03", const Color(0xFF64748B));
    _drawLandmark(canvas, Offset(w * 0.30, h * 0.62), "Colombo 04", const Color(0xFF64748B));
    _drawLandmark(canvas, Offset(w * 0.52, h * 0.68), "Colombo 05", const Color(0xFF64748B));
    _drawLandmark(canvas, Offset(w * 0.75, h * 0.78), "Nugegoda", const Color(0xFF64748B));
    _drawLandmark(canvas, Offset(w * 0.32, h * 0.88), "Dehiwala", const Color(0xFF64748B));

    // 5. Draw User Location Radar Beacon
    final userX = ((userLng - minLng) / (maxLng - minLng)) * w;
    final userY = (1.0 - (userLat - minLat) / (maxLat - minLat)) * h;

    // Pulsing Radar Rings
    final radarRingPaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(userX, userY), 22 * pulseScale, radarRingPaint);

    // User Blue Dot
    final userDotPaint = Paint()..color = const Color(0xFF38BDF8);
    canvas.drawCircle(Offset(userX, userY), 6, userDotPaint);
    canvas.drawCircle(Offset(userX, userY), 9, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.8);

    // 6. Draw Pharmacy Pins
    for (final p in pharmacies) {
      final double lat = (p['latitude'] as num? ?? userLat).toDouble();
      final double lng = (p['longitude'] as num? ?? userLng).toDouble();
      final int pId = p['pharmacyId'] ?? 0;
      final String stockStatus = p['stockStatus'] ?? 'IN_STOCK';
      final bool isSelected = pId == selectedPharmacyId;

      final double px = ((lng - minLng) / (maxLng - minLng)) * w;
      final double py = (1.0 - (lat - minLat) / (maxLat - minLat)) * h;

      final pinColor = stockStatus == 'IN_STOCK'
          ? const Color(0xFF10B981)
          : (stockStatus == 'LOW_STOCK' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

      // Glow when selected
      if (isSelected) {
        canvas.drawCircle(
          Offset(px, py),
          14 * pulseScale,
          Paint()..color = pinColor.withValues(alpha: 0.4),
        );
      }

      // Outer Ring
      canvas.drawCircle(
        Offset(px, py),
        isSelected ? 8.5 : 6.5,
        Paint()..color = Colors.white,
      );

      // Inner Core
      canvas.drawCircle(
        Offset(px, py),
        isSelected ? 6.5 : 4.5,
        Paint()..color = pinColor,
      );

      // Pin Label
      final name = (p['name'] ?? 'Pharmacy').toString().split(' ').first;
      final textSpan = TextSpan(
        text: name,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade300,
          fontSize: isSelected ? 9.5 : 8.0,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(px - (textPainter.width / 2), py + 8));
    }
  }

  void _drawLandmark(Canvas canvas, Offset pos, String text, Color color) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color.withValues(alpha: 0.7),
        fontSize: 8.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _ColomboMapPainter oldDelegate) {
    return oldDelegate.pulseScale != pulseScale ||
        oldDelegate.selectedPharmacyId != selectedPharmacyId ||
        oldDelegate.pharmacies != pharmacies;
  }
}
