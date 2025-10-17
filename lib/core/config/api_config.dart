class ApiConfig {
  // Production VIB3 backend on DigitalOcean
  static const String baseUrl = 'https://vib3-backend-u8zjk.ondigitalocean.app/api';
  static const String wsUrl = 'wss://vib3-backend-u8zjk.ondigitalocean.app';

  // For local development:
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String wsUrl = 'ws://10.0.2.2:3000';
  
  // API Endpoints
  static const String auth = '/auth';
  static const String users = '/users';
  static const String posts = '/posts';
  static const String stories = '/stories';
  static const String messages = '/messages';
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String upload = '/upload';
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
