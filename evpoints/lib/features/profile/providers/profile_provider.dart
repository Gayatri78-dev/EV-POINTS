import 'package:flutter/material.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../../core/services/user_stats_service.dart';

/// ProfileProvider is a thin wrapper around AuthProvider for profile-specific UI.
/// It delegates authentication state and adds live stats from UserStatsService.
class ProfileProvider extends ChangeNotifier {
  final AuthProvider _authProvider;

  // Cached stats – refreshed whenever user changes
  int _sessionCount = 0;
  double _totalEnergyKwh = 0;
  double _co2SavedKg = 0;
  bool _statsLoaded = false;

  ProfileProvider(this._authProvider) {
    _authProvider.addListener(_onAuthChanged);
    if (_authProvider.user != null) _loadStats();
  }

  void _onAuthChanged() {
    _statsLoaded = false;
    notifyListeners();
    if (_authProvider.user != null) _loadStats();
  }

  Future<void> _loadStats() async {
    final uid = _authProvider.user?.id;
    if (uid == null) return;
    final stats = await UserStatsService.instance.getStats(uid);
    _sessionCount = stats['sessions'] as int;
    _totalEnergyKwh = stats['energyKwh'] as double;
    _co2SavedKg = stats['co2Kg'] as double;
    _statsLoaded = true;
    notifyListeners();
  }

  // ── Public getters ───────────────────────────────────────────────────────

  UserModel? get user => _authProvider.user;
  bool get isLoading => _authProvider.status == AuthStatus.loading;
  String? get errorMessage => _authProvider.errorMessage;
  bool get statsLoaded => _statsLoaded;

  int get sessionCount => _sessionCount;
  String get totalEnergy =>
      _totalEnergyKwh < 1000
          ? '${_totalEnergyKwh.toStringAsFixed(0)} kWh'
          : '${(_totalEnergyKwh / 1000).toStringAsFixed(1)} MWh';
  String get co2Saved => '${_co2SavedKg.toStringAsFixed(1)} kg';

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<bool> updateProfile(
    String name,
    String email, {
    String? phone,
    String? vehicleType,
  }) {
    return _authProvider.updateProfile(
      name,
      email,
      phone: phone,
      vehicleType: vehicleType,
    );
  }

  Future<bool> changePassword(String current, String newPass) {
    return _authProvider.changePassword(current, newPass);
  }

  /// Call this when a user completes a charging session.
  Future<void> addChargingSession(double energyKwh) async {
    final uid = user?.id;
    if (uid == null) return;
    await UserStatsService.instance.addSession(uid, energyKwh);
    await _loadStats();
  }

  Future<void> logout() => _authProvider.logout();

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}
