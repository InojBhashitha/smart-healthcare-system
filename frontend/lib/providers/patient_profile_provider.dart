import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';

class PatientProfileProvider extends ChangeNotifier {
  final Dio _dio = DioClient.dio;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;

  List<dynamic> _allergies = [];
  List<dynamic> get allergies => _allergies;

  List<dynamic> _activeMedications = [];
  List<dynamic> get activeMedications => _activeMedications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.get("/api/patient/profile");
      _profile = response.data as Map<String, dynamic>;
      _allergies = _profile?['allergies'] as List? ?? [];
      _activeMedications = _profile?['activeMedications'] as List? ?? [];
    } catch (e) {
      debugPrint("Failed to load patient profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAllergy({
    required String allergenName,
    required String severity,
    String? notes,
  }) async {
    try {
      await _dio.post(
        "/api/patient/profile/allergies",
        data: {
          "allergenName": allergenName,
          "severity": severity,
          "notes": notes ?? "",
        },
      );
      await loadProfile();
    } catch (e) {
      debugPrint("Failed to add allergy: $e");
      rethrow;
    }
  }

  Future<void> deleteAllergy(int allergyId) async {
    try {
      await _dio.delete("/api/patient/profile/allergies/$allergyId");
      await loadProfile();
    } catch (e) {
      debugPrint("Failed to delete allergy: $e");
    }
  }

  Future<void> addMedication({
    required String medicineName,
    String? genericName,
    String? strength,
  }) async {
    try {
      await _dio.post(
        "/api/patient/profile/medications",
        data: {
          "medicineName": medicineName,
          "genericName": genericName ?? medicineName,
          "strength": strength ?? "",
        },
      );
      await loadProfile();
    } catch (e) {
      debugPrint("Failed to add medication: $e");
      rethrow;
    }
  }

  Future<void> deleteMedication(int medicationId) async {
    try {
      await _dio.delete("/api/patient/profile/medications/$medicationId");
      await loadProfile();
    } catch (e) {
      debugPrint("Failed to delete medication: $e");
    }
  }
}
