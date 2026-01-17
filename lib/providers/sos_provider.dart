// lib/providers/sos_provider.dart
import 'package:flutter/material.dart';

import '../models/sos_model.dart';
import '../services/sos_service.dart';

class SOSProvider extends ChangeNotifier {
  final SOSService _sosService = SOSService();

  bool _isLoading = false;
  String? _error;
  SOSAlert? _lastSOS;

  bool get isLoading => _isLoading;
  String? get error => _error;
  SOSAlert? get lastSOS => _lastSOS;
  bool get isActive =>
      _lastSOS?.status == 'sent' || _lastSOS?.status == 'triggered';

  /// Trigger SOS
  Future<bool> triggerSOS(double latitude, double longitude) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _sosService.triggerSOS(
      latitude: latitude,
      longitude: longitude,
    );
    _isLoading = false;

    if (response.isSuccess) {
      _lastSOS = response.data;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to trigger SOS';
      notifyListeners();
      return false;
    }
  }

  /// Resolve SOS
  Future<bool> resolveSOS(String sosId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _sosService.resolveSOS(sosId);
    _isLoading = false;

    if (response.isSuccess) {
      _lastSOS = null;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to resolve SOS';
      notifyListeners();
      return false;
    }
  }
}
