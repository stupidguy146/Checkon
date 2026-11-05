import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/api_error.dart';
import '../models/auth_user.dart';
import 'token_store.dart';

/// Talks to the gateway auth endpoints and holds the current session.
/// Exposes a [ChangeNotifier] so the UI (AuthGate) can react to login/logout.
class AuthService extends ChangeNotifier {
  final http.Client _client;
  final TokenStore tokens;

  AuthUser? _user;
  bool _initializing = true;
  bool _requiresPinSetup = false;
  Future<bool>? _refreshFuture;

  AuthService({http.Client? client, TokenStore? store})
      : _client = client ?? http.Client(),
        tokens = store ?? TokenStore();

  AuthUser? get user => _user;
  bool get isAuthenticated => tokens.hasTokens;
  bool get initializing => _initializing;
  bool get requiresPinSetup => _requiresPinSetup;

  void completePinSetup() {
    _requiresPinSetup = false;
  }

  Uri _auth(String path) =>
      Uri.parse('${AppConfig.gatewayBaseUrl}${AppConfig.authPrefix}$path');

  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json'};

  /// Load persisted tokens, then validate the session without blocking startup.
  Future<void> bootstrap() async {
    await tokens.load();
    _initializing = false;
    notifyListeners();
    if (tokens.hasTokens) unawaited(_validateSession());
  }

  Future<void> _validateSession() async {
    try {
      await fetchMe();
    } catch (_) {
      // An expired access token may still be recoverable with the refresh token.
      final refreshed = await tryRefresh();
      if (!refreshed) await logout();
    }
  }

  /// Step 1 of registration: create a pending account and email an OTP.
  /// Returns how long the OTP is valid for (seconds). No session yet.
  Future<int> register({
    required String email,
    required String title,
    required String username,
    required String firstName,
    required String lastName,
  }) async {
    final res = await _client.post(
      _auth('/register'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'email': email,
        'title': title,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );
    _ensureOk(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['otpExpiresInSec'] as num?)?.toInt() ?? 600;
  }

  /// Step 2: verify the emailed OTP. Returns a short-lived setup ticket
  /// required to set the password.
  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final res = await _client.post(
      _auth('/verify-otp'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    _ensureOk(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['setupTicket'] as String;
  }

  /// Re-send a fresh OTP for an in-progress registration.
  Future<int> resendOtp(String email) async {
    final res = await _client.post(
      _auth('/resend-otp'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email}),
    );
    _ensureOk(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['otpExpiresInSec'] as num?)?.toInt() ?? 600;
  }

  /// Step 3: set the password, completing the account and logging in.
  Future<void> setPassword({
    required String email,
    required String setupTicket,
    required String password,
  }) async {
    final res = await _client.post(
      _auth('/set-password'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'email': email,
        'setupTicket': setupTicket,
        'password': password,
      }),
    );
    _ensureOk(res);
    _requiresPinSetup = true;
    await _applyAuthResult(res.body);
  }

  /// Login with an email or a username.
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    final res = await _client.post(
      _auth('/login'),
      headers: _jsonHeaders,
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );
    _ensureOk(res);
    await _applyAuthResult(res.body);
  }

  Future<void> fetchMe() async {
    final res = await _client.get(
      _auth('/me'),
      headers: {'Authorization': 'Bearer ${tokens.accessToken}'},
    );
    _ensureOk(res);
    _user = AuthUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    notifyListeners();
  }

  /// Ask the backend to re-send the verification email.
  Future<void> resendVerification() async {
    Future<http.Response> send() => _client.post(
          _auth('/resend-verification'),
          headers: {'Authorization': 'Bearer ${tokens.accessToken}'},
        );
    var res = await send();
    if (res.statusCode == 401) {
      final refreshed = await tryRefresh();
      if (refreshed) res = await send();
    }
    _ensureOk(res);
  }

  /// Start the forgot-password flow (always succeeds; email sent if account exists).
  Future<void> forgotPassword(String email) async {
    final res = await _client.post(
      _auth('/forgot-password'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email}),
    );
    _ensureOk(res);
  }

  /// Complete a password reset with the token from the email link.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final res = await _client.post(
      _auth('/reset-password'),
      headers: _jsonHeaders,
      body: jsonEncode({'token': token, 'newPassword': newPassword}),
    );
    _ensureOk(res);
  }

  /// Change the signed-in user's password (requires the old password).
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    Future<http.Response> send() => _client.post(
          _auth('/change-password'),
          headers: {
            ..._jsonHeaders,
            'Authorization': 'Bearer ${tokens.accessToken}',
          },
          body: jsonEncode({
            'oldPassword': oldPassword,
            'newPassword': newPassword,
          }),
        );
    var res = await send();
    if (res.statusCode == 401) {
      final refreshed = await tryRefresh();
      if (refreshed) res = await send();
    }
    _ensureOk(res);
  }

  /// Exchange refresh token for a new pair. Returns false on failure.
  Future<bool> tryRefresh() {
    final pendingRefresh = _refreshFuture;
    if (pendingRefresh != null) return pendingRefresh;

    final refreshFuture = _refreshTokens();
    _refreshFuture = refreshFuture;
    return refreshFuture.whenComplete(() {
      if (identical(_refreshFuture, refreshFuture)) _refreshFuture = null;
    });
  }

  Future<bool> _refreshTokens() async {
    final rt = tokens.refreshToken;
    if (rt == null || rt.isEmpty) return false;
    try {
      final res = await _client.post(
        _auth('/refresh'),
        headers: _jsonHeaders,
        body: jsonEncode({'refreshToken': rt}),
      );
      if (res.statusCode >= 400) return false;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final pair = AuthTokens.fromJson(json);
      await tokens.save(
        accessToken: pair.accessToken,
        refreshToken: pair.refreshToken,
      );
      await fetchMe();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await tokens.clear();
    _user = null;
    _requiresPinSetup = false;
    notifyListeners();
  }

  Future<void> _applyAuthResult(String body) async {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final pair = AuthTokens.fromJson(json);
    await tokens.save(
      accessToken: pair.accessToken,
      refreshToken: pair.refreshToken,
    );
    if (json['user'] != null) {
      _user = AuthUser.fromJson(json['user'] as Map<String, dynamic>);
    }
    notifyListeners();
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode >= 400) {
      throw ApiError.fromResponse(res.statusCode, res.body);
    }
  }
}
