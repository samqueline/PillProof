import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storageService;

  AuthRepository({
    ApiClient? apiClient,
    SecureStorageService? storageService,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storageService = storageService ?? SecureStorageService();

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String role = 'user',
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await _storageService.saveToken(token);
      await _storageService.saveUserData(userId: user.id, email: user.email);

      return user;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      throw NetworkException('Registration failed. Please check your connection.');
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      await _storageService.saveToken(token);
      await _storageService.saveUserData(userId: user.id, email: user.email);

      return user;
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error!;
      }
      throw NetworkException('Login failed. Please check your credentials.');
    }
  }

  Future<UserModel?> checkAuthStatus() async {
    final token = await _storageService.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await _apiClient.get(ApiConstants.me);
      final data = response.data as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      await _storageService.clearAuth();
      return null;
    }
  }

  Future<void> logout() async {
    await _storageService.clearAuth();
  }
}
