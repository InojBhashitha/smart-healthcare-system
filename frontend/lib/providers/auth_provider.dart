import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../models/auth/auth_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../services/auth/auth_service.dart';
import '../core/network/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  AuthResponse? _authResponse;

  AuthResponse? get authResponse => _authResponse;

  String? _userName;
  String? _userEmail;

  String? get userName => _userName;
  String? get userEmail => _userEmail;

  AuthProvider() {
    loadUserData();
  }

  Future<void> loadUserData() async {
    final token = await TokenStorage.getToken();

    if (token != null && token.isNotEmpty) {
      try {
        final profile = await _authService.getProfile();
        _userName = profile.name;
        _userEmail = profile.email;
        await TokenStorage.saveUserName(_userName!);
        await TokenStorage.saveUserEmail(_userEmail!);
      } catch (_) {
        await logout();
      }
    } else {
      _userName = await TokenStorage.getUserName();
      _userEmail = await TokenStorage.getUserEmail();
    }

    notifyListeners();
  }



  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _authResponse = await _authService.login(
        LoginRequest(
          email: email,
          password: password,
        ),
      );

      await TokenStorage.saveToken(
        _authResponse!.token,
      );
      _userName = _authResponse!.name;
      _userEmail = _authResponse!.email;
      await TokenStorage.saveUserName(_userName!);
      await TokenStorage.saveUserEmail(_userEmail!);

      debugPrint("JWT Saved: ${_authResponse!.token}");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _authResponse = await _authService.register(
        RegisterRequest(
          name: name,
          email: email,
          password: password,
          role: AppConstants.pharmacistRole,
        ),
      );

      await TokenStorage.saveToken(
        _authResponse!.token,
      );
      _userName = _authResponse!.name;
      _userEmail = _authResponse!.email;
      await TokenStorage.saveUserName(_userName!);
      await TokenStorage.saveUserEmail(_userEmail!);

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await TokenStorage.deleteToken();
    await TokenStorage.deleteUserName();
    await TokenStorage.deleteUserEmail();
    _userName = null;
    _userEmail = null;
    _authResponse = null;

    notifyListeners();
  }

Future<bool> isLoggedIn() async {
  return await TokenStorage.hasToken();
}
}