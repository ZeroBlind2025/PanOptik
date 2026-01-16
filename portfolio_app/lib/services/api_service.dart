import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final _secureStorage = const FlutterSecureStorage();
  bool _initialized = false;

  static const _tokenKey = 'access_token';

  void initialize() {
    if (_initialized) return;

    _dio = Dio(BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add JWT token to all requests
        final token = await _secureStorage.read(key: _tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors (token expired)
        if (error.response?.statusCode == 401) {
          await clearToken();
        }
        handler.next(error);
      },
    ));

    _initialized = true;
  }

  // Store JWT token
  Future<void> setToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  // Get current token
  Future<String?> getToken() async {
    return _secureStorage.read(key: _tokenKey);
  }

  // Clear token (logout)
  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  // Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.post<T>(path, data: data, queryParameters: queryParameters);
  }

  // Generic PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.patch<T>(path, data: data, queryParameters: queryParameters);
  }

  // Generic DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.delete<T>(path, queryParameters: queryParameters);
  }
}
