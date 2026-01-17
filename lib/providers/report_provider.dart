// lib/providers/report_provider.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/report_model.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  bool _isLoading = false;
  String? _error;
  List<Report> _reports = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Report> get reports => _reports;

  /// Submit a report
  Future<bool> submitReport({
    required String type,
    required String description,
    required double latitude,
    required double longitude,
    int severity = 3,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _reportService.submitReport(
      type: type,
      description: description,
      latitude: latitude,
      longitude: longitude,
      severity: severity,
    );
    _isLoading = false;

    if (response.isSuccess) {
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to submit report';
      notifyListeners();
      return false;
    }
  }

  /// Fetch nearby reports
  Future<void> getNearbyReports({
    required double latitude,
    required double longitude,
    double radius = 2000,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _reportService.getNearbyReports(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
    _isLoading = false;

    if (response.isSuccess) {
      _reports = response.data ?? [];
      _error = null;
    } else {
      _error = response.error ?? 'Failed to fetch reports';
    }
    notifyListeners();
  }
}
