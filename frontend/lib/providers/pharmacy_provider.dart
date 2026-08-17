import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';

class PharmacyProvider extends ChangeNotifier {
  final Dio _dio = DioClient.dio;

  List<dynamic> _pharmacies = [];
  List<dynamic> get pharmacies => _pharmacies;

  List<dynamic> _myReservations = [];
  List<dynamic> get myReservations => _myReservations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int? _selectedPharmacyId;
  int? get selectedPharmacyId => _selectedPharmacyId;

  String _searchQuery = "";
  String get searchQuery => _searchQuery;

  String _activeFilter = "ALL"; // ALL, IN_STOCK, 24_HOURS, DELIVERY, NEARBY
  String get activeFilter => _activeFilter;

  List<dynamic> get filteredPharmacies {
    return _pharmacies.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final address = (item['address'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase().trim();

      if (query.isNotEmpty && !name.contains(query) && !address.contains(query)) {
        return false;
      }

      switch (_activeFilter) {
        case 'IN_STOCK':
          return item['stockStatus'] == 'IN_STOCK';
        case '24_HOURS':
          final hours = (item['operatingHours'] ?? '').toString().toLowerCase();
          return hours.contains('24');
        case 'DELIVERY':
          return item['deliveryAvailable'] == true;
        case 'NEARBY':
          final distance = (item['distanceKm'] as num? ?? 99.0).toDouble();
          return distance <= 3.0;
        default:
          return true;
      }
    }).toList();
  }

  void selectPharmacy(int? pharmacyId) {
    _selectedPharmacyId = pharmacyId;
    notifyListeners();
  }

  void setActiveFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> searchPharmacies({
    double lat = 6.9271,
    double lng = 79.8612,
    int? prescriptionId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {
        "lat": lat,
        "lng": lng,
      };
      if (prescriptionId != null) {
        queryParams["prescriptionId"] = prescriptionId;
      }

      final response = await _dio.get(
        "/api/pharmacies/search-stock",
        queryParameters: queryParams,
      );
      _pharmacies = response.data as List? ?? [];

      if (_pharmacies.isNotEmpty && _selectedPharmacyId == null) {
        _selectedPharmacyId = _pharmacies.first['pharmacyId'];
      }
    } catch (e) {
      debugPrint("Failed to search pharmacies: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createReservation({
    required int prescriptionId,
    required int pharmacyId,
  }) async {
    try {
      final response = await _dio.post(
        "/api/pharmacies/reservations/create",
        data: {
          "prescriptionId": prescriptionId,
          "pharmacyId": pharmacyId,
        },
      );
      await loadMyReservations();
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint("Failed to create reservation: $e");
      rethrow;
    }
  }

  Future<void> loadMyReservations() async {
    try {
      final response = await _dio.get("/api/pharmacies/reservations/my-reservations");
      _myReservations = response.data as List? ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load my reservations: $e");
    }
  }
}

