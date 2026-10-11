import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Check if a token exists in storage and restore user
  Future<bool> checkAuthStatus() async {
    final token = await _repo.getToken();
    if (token != null) {
      _user = await _repo.getCachedUser();
      if (_user != null) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
    }
    await _repo.clearToken();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repo.login(email, password);
    if (result.isSuccess) {
      _user = result.data!.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.error;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repo.register(name, email, password);
    if (result.isSuccess) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.error;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(
    String name,
    String email, {
    String? phone,
    String? vehicleType,
  }) async {
    if (_user == null) return false;
    _status = AuthStatus.loading;
    notifyListeners();

    final result = await _repo.updateUser(
      _user!.id,
      name,
      email,
      phone: phone,
      vehicleType: vehicleType,
    );
    if (result.isSuccess) {
      _user = result.data;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.error;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    if (_user == null) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result =
        await _repo.changePassword(_user!.id, currentPassword, newPassword);
    if (result.isSuccess) {
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.error;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.clearToken();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
