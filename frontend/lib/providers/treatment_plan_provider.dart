import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';

class TreatmentPlanProvider extends ChangeNotifier {
  final Dio _dio = DioClient.dio;

  List<dynamic> _todayDoses = [];
  List<dynamic> get todayDoses => _todayDoses;

  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? get analytics => _analytics;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadTodayDoses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.get("/api/treatment-plans/today");
      _todayDoses = response.data as List? ?? [];
    } catch (e) {
      debugPrint("Failed to load today doses: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generatePlan(int prescriptionId) async {
    try {
      await _dio.post("/api/treatment-plans/generate/$prescriptionId");
      await loadTodayDoses();
      await loadAnalytics();
    } catch (e) {
      debugPrint("Failed to generate treatment plan for Rx #$prescriptionId: $e");
    }
  }

  Future<void> logDoseStatus(int scheduleId, String status) async {
    try {
      await _dio.post(
        "/api/treatment-plans/doses/$scheduleId/log",
        queryParameters: {"status": status},
      );
      await loadTodayDoses();
      await loadAnalytics();
    } catch (e) {
      debugPrint("Failed to log dose status: $e");
    }
  }

  Future<void> loadAnalytics() async {
    try {
      final response = await _dio.get("/api/treatment-plans/analytics");
      _analytics = response.data as Map<String, dynamic>?;
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load adherence analytics: $e");
    }
  }
}
