import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final Dio _dio = DioClient.instance.dio;

  Future<AuthResponseModel> login(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> register(String name, String email, String password) async {
    await _dio.post(
      ApiConstants.register,
      data: {'name': name, 'email': email, 'password': password},
    );
  }

  Future<UserModel> getUserById(String id) async {
    final response = await _dio.get(ApiConstants.userById(id));
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> updateUser(String id, String name, String email) async {
    final response = await _dio.put(
      ApiConstants.userById(id),
      data: {'name': name, 'email': email},
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
