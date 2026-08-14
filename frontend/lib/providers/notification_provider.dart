import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';

class NotificationProvider extends ChangeNotifier {
  final Dio _dio = DioClient.dio;

  List<dynamic> _notifications = [];
  List<dynamic> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _dio.get("/api/notifications");
      _notifications = response.data as List? ?? [];
      _unreadCount = _notifications.where((n) => n['isRead'] == false).length;
    } catch (e) {
      debugPrint("Failed to load notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.put("/api/notifications/$notificationId/read");
      await loadNotifications();
    } catch (e) {
      debugPrint("Failed to mark notification read: $e");
    }
  }

  Future<void> clearAll() async {
    try {
      await _dio.delete("/api/notifications/clear");
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to clear notifications: $e");
    }
  }

  Future<void> downloadPdfReport(BuildContext context) async {
    try {
      final response = await _dio.get(
        "/api/reports/pdf/health-summary",
        options: Options(responseType: ResponseType.bytes),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Health Summary PDF generated! (${response.data.length} bytes)"),
            backgroundColor: const Color(0xFF0D9488),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to generate PDF: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
