import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/ev_spot_model.dart';

class SpotsRemoteDatasource {
  final Dio _dio = DioClient.instance.dio;

  Future<List<EvSpotModel>> getSpots() async {
    final response = await _dio.get(ApiConstants.spots);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => EvSpotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EvSpotModel> getSpotById(String id) async {
    final response = await _dio.get(ApiConstants.spotById(id));
    return EvSpotModel.fromJson(response.data as Map<String, dynamic>);
  }
}
