class ApiConstants {
  ApiConstants._();

  // Connects physical phone to laptop backend directly via current LAN IP or USB
  static const String defaultBaseUrl = 'http://10.37.241.209:5000/api';
  static const String webBaseUrl = 'http://localhost:5000/api';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Endpoints
  static const String health = '/health';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  static const String verifyMedicine = '/medicines/verify';
  static const String medicines = '/medicines';

  static const String medications = '/medications';
  static const String intake = '/intake';
  static const String intakeHistory = '/intake/history';
  static const String verificationHistory = '/verification/history';
  static const String aiChat = '/ai/chat';
}
