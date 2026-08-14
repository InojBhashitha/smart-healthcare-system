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
