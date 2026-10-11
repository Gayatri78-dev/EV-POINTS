import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_response.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Local-first AuthRepository.
///
/// Users are stored in SharedPreferences as a JSON map keyed by email.
/// No backend is required. The architecture is identical to a real API
/// implementation – only this file changes when you add a real server.
class AuthRepository {
  static const String _tokenKey = 'auth_token';
  static const String _currentUserKey = 'current_user_id';
  static const String _usersMapKey = 'registered_users';

  // ── Helpers: user store ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> _loadUsersMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersMapKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _saveUsersMap(Map<String, dynamic> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersMapKey, jsonEncode(map));
  }

  /// Simple deterministic "hash" – replace with bcrypt if you add a backend.
  String _hashPassword(String password) {
    // XOR-fold the UTF-8 bytes, then Base64-encode → lightweight, not crypto
    final bytes = utf8.encode('${password}ev_salt_2024');
    int h = 5381;
    for (final b in bytes) {
      h = ((h << 5) + h) ^ b;
      h &= 0xFFFFFFFF;
    }
    return base64Url.encode(utf8.encode(h.toString()));
  }

  String _generateId() {
    final rand = Random.secure();
    return List.generate(12, (_) => rand.nextInt(36).toRadixString(36)).join();
  }

  // ── Token helpers ─────────────────────────────────────────────────────────

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_currentUserKey);
  }

  // ── Cached user (for fast app resume) ────────────────────────────────────

  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_currentUserKey);
    if (userId == null) return null;

    final usersMap = await _loadUsersMap();
    final record = usersMap[userId] as Map<String, dynamic>?;
    if (record == null) return null;
    return UserModel.fromJson(record);
  }

  // ── Auth methods ──────────────────────────────────────────────────────────

  Future<ApiResponse<AuthResponseModel>> login(
      String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400)); // simulate latency

    final usersMap = await _loadUsersMap();
    // Find user by email (case-insensitive)
    final key = usersMap.keys.firstWhere(
      (k) => (usersMap[k] as Map)['email'].toString().toLowerCase() ==
          email.trim().toLowerCase(),
      orElse: () => '',
    );

    if (key.isEmpty) {
      return ApiResponse.error('No account found with that email address.');
    }

    final record = Map<String, dynamic>.from(usersMap[key] as Map);
    final storedHash = record['passwordHash'] as String;

    if (storedHash != _hashPassword(password)) {
      return ApiResponse.error('Incorrect password. Please try again.');
    }

    final user = UserModel.fromJson(record);
    final token = 'local_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

    final prefs = await SharedPreferences.getInstance();
    await _saveToken(token);
    await prefs.setString(_currentUserKey, user.id);

    return ApiResponse.success(AuthResponseModel(token: token, user: user));
  }

  Future<ApiResponse<void>> register(
      String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final usersMap = await _loadUsersMap();

    // Check email uniqueness
    final emailExists = usersMap.values.any(
      (v) => (v as Map)['email'].toString().toLowerCase() ==
          email.trim().toLowerCase(),
    );
    if (emailExists) {
      return ApiResponse.error(
          'An account with this email already exists. Please login.');
    }

    final id = _generateId();
    // Capitalise first letter of each word in name
    final cleanName = name
        .trim()
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    usersMap[id] = {
      'id': id,
      'name': cleanName,
      'email': email.trim().toLowerCase(),
      'role': 'user',
      'isRegistered': true,
      'createdAt': DateTime.now().toIso8601String(),
      'passwordHash': _hashPassword(password),
      'phone': '',
      'vehicleType': '',
    };

    await _saveUsersMap(usersMap);
    return ApiResponse.success(null);
  }

  Future<ApiResponse<UserModel>> getUserById(String id) async {
    final usersMap = await _loadUsersMap();
    final record = usersMap[id] as Map<String, dynamic>?;
    if (record == null) {
      return ApiResponse.error('User not found.');
    }
    return ApiResponse.success(UserModel.fromJson(record));
  }

  Future<ApiResponse<UserModel>> updateUser(
      String id, String name, String email,
      {String? phone, String? vehicleType}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final usersMap = await _loadUsersMap();
    final record = usersMap[id] as Map<String, dynamic>?;
    if (record == null) {
      return ApiResponse.error('User not found.');
    }

    // Check email uniqueness if changed
    final newEmail = email.trim().toLowerCase();
    if (newEmail != record['email']) {
      final conflict = usersMap.entries.any(
        (e) =>
            e.key != id &&
            (e.value as Map)['email'].toString().toLowerCase() == newEmail,
      );
      if (conflict) {
        return ApiResponse.error('That email is already in use by another account.');
      }
    }

    final cleanName = name
        .trim()
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    record['name'] = cleanName;
    record['email'] = newEmail;
    if (phone != null) record['phone'] = phone;
    if (vehicleType != null) record['vehicleType'] = vehicleType;
    usersMap[id] = record;

    await _saveUsersMap(usersMap);
    return ApiResponse.success(UserModel.fromJson(record));
  }

  Future<ApiResponse<void>> changePassword(
      String id, String currentPassword, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final usersMap = await _loadUsersMap();
    final record = usersMap[id] as Map<String, dynamic>?;
    if (record == null) return ApiResponse.error('User not found.');

    if (record['passwordHash'] != _hashPassword(currentPassword)) {
      return ApiResponse.error('Current password is incorrect.');
    }

    record['passwordHash'] = _hashPassword(newPassword);
    usersMap[id] = record;
    await _saveUsersMap(usersMap);
    return ApiResponse.success(null);
  }
}
