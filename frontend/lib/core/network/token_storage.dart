import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _tokenKey = "jwt_token";
  static const String _userNameKey = "user_name";
  static const String _userEmailKey = "user_email";

  static Future<void> saveToken(String token) async {
    await _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<bool> hasToken() async {
    return await _storage.containsKey(
      key: _tokenKey,
    );
  }

  static Future<void> saveUserName(String name) async {
    await _storage.write(
      key: _userNameKey,
      value: name,
    );
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  static Future<void> deleteUserName() async {
    await _storage.delete(key: _userNameKey);
  }

  static Future<void> saveUserEmail(String email) async {
    await _storage.write(
      key: _userEmailKey,
      value: email,
    );
  }

  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  static Future<void> deleteUserEmail() async {
    await _storage.delete(key: _userEmailKey);
  }
}

