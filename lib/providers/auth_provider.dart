import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AuthProvider(this._authService);

  bool _isLoading = false;
  String? _errorMessage;
  String? _role;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get role => _role;
  bool get isAdmin => _role == 'admin';
  bool get isTeacher => _role == 'teacher';

  Future<bool> login(String id, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(id, password);

    _isLoading = false;

    if (result.role == null) {
      _errorMessage = result.error ?? 'Unknown error';
      notifyListeners();
      return false;
    }

    _role = result.role;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _authService.logout();
    _role = null;
    _errorMessage = null;
    notifyListeners();
  }
}