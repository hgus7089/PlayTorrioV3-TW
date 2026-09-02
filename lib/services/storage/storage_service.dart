import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _kTraktAccessToken = 'trakt_access_token';
  static const _kTraktRefreshToken = 'trakt_refresh_token';
  static const _kTraktTokenExpiry = 'trakt_token_expiry_ms';
  static const _kTraktUsername = 'trakt_username';

  static const _kSimklAccessToken = 'simkl_access_token';
  static const _kSimklUsername = 'simkl_username';

  static final ValueNotifier<int> movieFinishedRevision = ValueNotifier<int>(0);

  // ── Trakt ─────────────────────────────────────────────────────────────────
  static Future<String?> getTraktAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTraktAccessToken);
  }

  static Future<void> setTraktAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTraktAccessToken, token);
  }

  static Future<String?> getTraktRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTraktRefreshToken);
  }

  static Future<void> setTraktRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTraktRefreshToken, token);
  }

  static Future<int?> getTraktTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTraktTokenExpiry);
  }

  static Future<void> setTraktTokenExpiry(int expiryMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTraktTokenExpiry, expiryMs);
  }

  static Future<String?> getTraktUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTraktUsername);
  }

  static Future<void> setTraktUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTraktUsername, username);
  }

  static Future<bool> clearTraktAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTraktAccessToken);
    await prefs.remove(_kTraktRefreshToken);
    await prefs.remove(_kTraktTokenExpiry);
    await prefs.remove(_kTraktUsername);
    return true;
  }

  // ── Simkl ─────────────────────────────────────────────────────────────────
  static Future<String?> getSimklAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSimklAccessToken);
  }

  static Future<void> setSimklAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSimklAccessToken, token);
  }

  static Future<String?> getSimklUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSimklUsername);
  }

  static Future<void> setSimklUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSimklUsername, username);
  }

  static Future<void> clearSimklAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSimklAccessToken);
    await prefs.remove(_kSimklUsername);
  }
}
