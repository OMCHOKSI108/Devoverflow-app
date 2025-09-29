import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Use flutter_secure_storage where available; fallback to SharedPreferences for
// platforms without secure storage.
final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

class AuthService {
  static const _tokenKey = 'auth_token';

  // Read token
  static Future<String?> getToken() async {
    try {
      // Prefer secure storage
      final value = await _secureStorage.read(key: _tokenKey);
      if (value != null) return value;
    } catch (_) {
      // ignore and fall back
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Store token
  static Future<void> setToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      return;
    } catch (_) {
      // ignore and fall back
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Remove token
  static Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {
      // ignore and fall back
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
