import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-user charging statistics: session count, total energy (kWh),
/// and CO2 saved (kg). All keys are namespaced by userId so different users
/// each get their own counters.
class UserStatsService {
  UserStatsService._();
  static final UserStatsService instance = UserStatsService._();

  static String _sessionsKey(String uid) => 'stats_sessions_$uid';
  static String _energyKey(String uid) => 'stats_energy_$uid';
  static String _co2Key(String uid) => 'stats_co2_$uid';

  Future<Map<String, dynamic>> getStats(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'sessions': prefs.getInt(_sessionsKey(userId)) ?? 0,
      'energyKwh': prefs.getDouble(_energyKey(userId)) ?? 0.0,
      'co2Kg': prefs.getDouble(_co2Key(userId)) ?? 0.0,
    };
  }

  Future<void> addSession(String userId, double energyKwh) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = (prefs.getInt(_sessionsKey(userId)) ?? 0) + 1;
    final totalEnergy = (prefs.getDouble(_energyKey(userId)) ?? 0.0) + energyKwh;
    // Average EV emits ~0.25 kg CO2/kWh saved vs petrol
    final totalCo2 = (prefs.getDouble(_co2Key(userId)) ?? 0.0) + (energyKwh * 0.25);

    await prefs.setInt(_sessionsKey(userId), sessions);
    await prefs.setDouble(_energyKey(userId), totalEnergy);
    await prefs.setDouble(_co2Key(userId), totalCo2);
  }

  Future<void> clearStats(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey(userId));
    await prefs.remove(_energyKey(userId));
    await prefs.remove(_co2Key(userId));
  }
}
