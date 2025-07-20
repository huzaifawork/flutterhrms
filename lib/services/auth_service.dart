import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../data/models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final Dio _dio;
  String? _token;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptor for token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ensure token is loaded before making requests
        if (_token == null) {
          await _loadToken();
        }
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired, logout user
          logout();
        }
        handler.next(error);
      },
    ));

    // Load token on initialization
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    _token = token;
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    _token = null;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          await _saveToken(data['jwtToken']);

          // Save user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.userIdKey, data['userId']);

          return {
            'success': true,
            'user': UserModel(
              id: data['userId'],
              name: data['name'],
              email: data['email'],
              phoneNumber: data['phone'] ?? '',
              role: data['role'] ?? 'user',
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
            ),
          };
        }
      }

      return {
        'success': false,
        'message': response.data['msg'] ?? 'Login failed',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final response = await _dio.post('/auth/signup', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'],
          };
        }
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Registration failed',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> googleAuth(String idToken) async {
    try {
      final response = await _dio.post('/auth/google/google', data: {
        'idToken': idToken,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          await _saveToken(data['jwtToken']);

          // Save user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.userIdKey, data['userId']);

          return {
            'success': true,
            'user': UserModel(
              id: data['userId'],
              name: data['name'],
              email: data['email'],
              phoneNumber: data['phone'] ?? '',
              role: data['role'] ?? 'user',
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
            ),
          };
        }
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Google authentication failed',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<UserModel?> getCurrentUser() async {
    await _loadToken();
    if (_token == null) return null;

    try {
      final response = await _dio.get('/api/user/profile');

      if (response.statusCode == 200) {
        final data = response.data;
        return UserModel(
          id: data['_id'],
          name: data['name'],
          email: data['email'],
          phoneNumber: data['phone'] ?? '',
          role: data['role'] ?? 'user',
          createdAt: DateTime.parse(
              data['createdAt'] ?? DateTime.now().toIso8601String()),
          lastLoginAt: DateTime.now(),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _clearToken();
      }
    } catch (e) {
      // Handle other errors
    }

    return null;
  }

  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.put('/api/user/profile', data: userData);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      final response = await _dio.put('/api/user/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _clearToken();
  }

  Future<bool> isLoggedIn() async {
    await _loadToken();
    return _token != null;
  }

  String? get token => _token;
}
// Minor change for contribution
