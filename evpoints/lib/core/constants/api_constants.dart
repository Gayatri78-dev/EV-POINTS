class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.0.2.2:3000';

  // Auth
  static const String register = '/api/v1/auth/register';
  static const String login = '/api/v1/auth/login';

  // Spots
  static const String spots = '/api/v1/spots';
  static String spotById(String id) => '/api/v1/spots/$id';

  // Users
  static String userById(String id) => '/api/v1/users/$id';
}
