// lib/providers/user_provider.dart
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _error;
  User? _user;
  List<EmergencyContact> _contacts = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  List<EmergencyContact> get contacts => _contacts;

  /// Fetch user profile
  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _userService.getProfile();
    _isLoading = false;

    if (response.isSuccess) {
      _user = response.data;
      _contacts = response.data!.emergencyContacts;
      _error = null;
    } else {
      _error = response.error ?? 'Failed to fetch profile';
    }
    notifyListeners();
  }

  /// Update user profile
  Future<bool> updateProfile(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _userService.updateProfile(name);
    _isLoading = false;

    if (response.isSuccess) {
      _user = response.data;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to update profile';
      notifyListeners();
      return false;
    }
  }

  /// Fetch emergency contacts
  Future<void> fetchContacts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _userService.getContacts();
    _isLoading = false;

    if (response.isSuccess) {
      _contacts = response.data ?? [];
      _error = null;
    } else {
      _error = response.error ?? 'Failed to fetch contacts';
    }
    notifyListeners();
  }

  /// Add emergency contact
  Future<bool> addContact(String name, String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _userService.addContact(name, phone);
    _isLoading = false;

    if (response.isSuccess) {
      _contacts = response.data ?? [];
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to add contact';
      notifyListeners();
      return false;
    }
  }

  /// Delete emergency contact
  Future<bool> deleteContact(String contactId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _userService.deleteContact(contactId);
    _isLoading = false;

    if (response.isSuccess) {
      _contacts = response.data ?? [];
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to delete contact';
      notifyListeners();
      return false;
    }
  }
}
