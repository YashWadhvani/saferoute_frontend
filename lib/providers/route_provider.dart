// lib/providers/route_provider.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_model.dart';
import '../services/route_service.dart';

class RouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();

  bool _isLoading = false;
  String? _error;
  List<RouteData> _routes = [];
  RouteData? _selectedRoute;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<RouteData> get routes => _routes;
  RouteData? get selectedRoute => _selectedRoute;

  /// Compare routes between origin and destination
  Future<void> compareRoutes(LatLng origin, LatLng destination) async {
    _isLoading = true;
    _error = null;
    _routes = [];
    _selectedRoute = null;
    notifyListeners();

    final response = await _routeService.compareRoutes(
      origin: origin,
      destination: destination,
    );
    _isLoading = false;

    if (response.isSuccess) {
      _routes = response.data ?? [];
      if (_routes.isNotEmpty) {
        // Auto-select safest route
        _selectedRoute =
            _routes.reduce((a, b) => a.safetyScore > b.safetyScore ? a : b);
      }
      _error = null;
    } else {
      _error = response.error ?? 'Failed to fetch routes';
    }
    notifyListeners();
  }

  /// Select a route
  void selectRoute(RouteData route) {
    _selectedRoute = route;
    notifyListeners();
  }

  /// Clear routes
  void clearRoutes() {
    _routes = [];
    _selectedRoute = null;
    notifyListeners();
  }
}
