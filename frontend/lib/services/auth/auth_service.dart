import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../models/auth/auth_response.dart';
import '../../models/auth/login_request.dart';
import '../../models/auth/register_request.dart';
import '../../models/auth/auth_profile.dart';

class AuthService {
  final Dio _dio = DioClient.dio;

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["message"] ?? "Login failed",
      );
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: request.toJson(),
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["message"] ?? "Registration failed",
      );
    }
  }

  Future<AuthProfile> getProfile() async {
    try {
      final response = await _dio.get(
        ApiConstants.profile,
      );

      return AuthProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["message"] ?? "Failed to fetch profile",
      );
    }
  }
}
