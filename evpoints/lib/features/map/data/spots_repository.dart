import 'package:dio/dio.dart';
import '../../../core/network/api_response.dart';
import '../models/ev_spot_model.dart';
import 'spots_remote_datasource.dart';

class SpotsRepository {
  final SpotsRemoteDatasource _remote = SpotsRemoteDatasource();

  // ── Mock data flag ──────────────────────────────────────────────────────────
  final bool useMockData = true;

  static final List<EvSpotModel> _mockSpots = [
    const EvSpotModel(
      id: '1',
      name: 'MP Nagar Charge Hub',
      address: 'MP Nagar Zone 1, Bhopal',
      latitude: 23.2332,
      longitude: 77.4272,
      chargerType: 'AC',
      isAvailable: true,
      isActive: true,
      openHours: '8am - 10pm',
      operatorName: 'EV India',
      photos: [],
    ),
    const EvSpotModel(
      id: '2',
      name: 'New Market FastCharge',
      address: 'New Market, Bhopal',
      latitude: 23.2368,
      longitude: 77.4011,
      chargerType: 'Fast Charge',
      isAvailable: true,
      isActive: true,
      openHours: '24 hours',
      operatorName: 'ChargeZone',
      photos: [],
    ),
    const EvSpotModel(
      id: '3',
      name: 'Kamlapati Railway Charger',
      address: 'Railway Station, Bhopal',
      latitude: 23.2295,
      longitude: 77.4382,
      chargerType: 'DC',
      isAvailable: true,
      isActive: true,
      openHours: '24 hours',
      operatorName: 'BPCL',
      photos: [],
    ),
    const EvSpotModel(
      id: '4',
      name: 'DB Mall Power Point',
      address: 'DB City Mall, Bhopal',
      latitude: 23.2217,
      longitude: 77.4326,
      chargerType: 'AC',
      isAvailable: false,
      isActive: true,
      openHours: '10am - 9pm',
      operatorName: 'Tata Power',
      photos: [],
    ),
    const EvSpotModel(
      id: '5',
      name: 'Arera Colony EV Stop',
      address: 'Arera Colony, Bhopal',
      latitude: 23.2156,
      longitude: 77.4289,
      chargerType: 'Fast Charge',
      isAvailable: true,
      isActive: true,
      openHours: '6am - 11pm',
      operatorName: 'Adani Electric',
      photos: [],
    ),
    const EvSpotModel(
      id: '6',
      name: 'Kolar Road Charge Point',
      address: 'Kolar Road, Bhopal',
      latitude: 23.1901,
      longitude: 77.4523,
      chargerType: 'DC',
      isAvailable: true,
      isActive: true,
      openHours: '8am - 8pm',
      operatorName: 'Jio-BP',
      photos: [],
    ),
    const EvSpotModel(
      id: '7',
      name: 'Shahpura EV Station',
      address: 'Shahpura, Bhopal',
      latitude: 23.2012,
      longitude: 77.4401,
      chargerType: 'AC',
      isAvailable: false,
      isActive: true,
      openHours: '9am - 9pm',
      operatorName: 'EV India',
      photos: [],
    ),
    const EvSpotModel(
      id: '8',
      name: 'NIT Bhopal Charger',
      address: 'NIT Bhopal Campus',
      latitude: 23.2124,
      longitude: 77.3945,
      chargerType: 'AC',
      isAvailable: true,
      isActive: true,
      openHours: '9am - 6pm',
      operatorName: 'EV India',
      photos: [],
    ),
    const EvSpotModel(
      id: '9',
      name: 'Bittan Market DC Hub',
      address: 'Bittan Market, Bhopal',
      latitude: 23.2241,
      longitude: 77.4198,
      chargerType: 'DC',
      isAvailable: true,
      isActive: true,
      openHours: '7am - 10pm',
      operatorName: 'Tata Power',
      photos: [],
    ),
    const EvSpotModel(
      id: '10',
      name: 'Bairagarh Fast Station',
      address: 'Bairagarh, Bhopal',
      latitude: 23.2587,
      longitude: 77.3712,
      chargerType: 'Fast Charge',
      isAvailable: false,
      isActive: true,
      openHours: '24 hours',
      operatorName: 'ChargeZone',
      photos: [],
    ),
  ];

  Future<ApiResponse<List<EvSpotModel>>> getSpots() async {
    if (useMockData) {
      return ApiResponse.success(_mockSpots);
    }
    try {
      final spots = await _remote.getSpots();
      return ApiResponse.success(spots);
    } on DioException catch (e) {
      return ApiResponse.error(_handleError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<EvSpotModel>> getSpotById(String id) async {
    if (useMockData) {
      final spot = _mockSpots.firstWhere(
        (s) => s.id == id,
        orElse: () => _mockSpots.first,
      );
      return ApiResponse.success(spot);
    }
    try {
      final spot = await _remote.getSpotById(id);
      return ApiResponse.success(spot);
    } on DioException catch (e) {
      return ApiResponse.error(_handleError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your network.';
    }
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      return 'Error ${e.response!.statusCode}';
    }
    return 'Network error. Please check your connection.';
  }
}
