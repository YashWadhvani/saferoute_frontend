// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _error;
  User? _user;
  String? _token;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;

  /// Initialize: Check if token exists from previous session
  Future<void> initialize() async {
    final token = await ApiClient.getToken();
    if (token != null && token.isNotEmpty) {
      _token = token;
      _isAuthenticated = true;
    }
    notifyListeners();
  }

  /// Send OTP to identifier (email or phone)
  Future<void> sendOTP(String identifier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _authService.sendOTP(identifier);
    _isLoading = false;

    if (response.isSuccess) {
      _error = null;
    } else {
      _error = response.error ?? 'Failed to send OTP';
    }
    notifyListeners();
  }

  /// Verify OTP and authenticate user
  Future<bool> verifyOTP(String identifier, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _authService.verifyOTP(identifier, otp);
    _isLoading = false;

    if (response.isSuccess) {
      _token = response.data!.token;
      _user = response.data!.user;
      _isAuthenticated = true;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to verify OTP';
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _user = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }
}
