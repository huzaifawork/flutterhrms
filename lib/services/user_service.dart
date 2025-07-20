import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/constants/app_constants.dart';
import '../data/models/user_model.dart';
import 'auth_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  Dio? _dio;

  void initialize() {
    if (_dio != null) return; // Prevent re-initialization
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptor for token
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = AuthService().token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _dio!.get('/api/admin/users');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['users'];
        return data.map((item) => UserModel.fromJson(item)).toList();
      }

      throw Exception('Failed to load users');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load users');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<UserModel> getUserById(String userId) async {
    try {
      final response = await _dio!.get('/api/admin/users/$userId');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      }

      throw Exception('User not found');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load user');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<Map<String, dynamic>> updateUser(
      String userId, Map<String, dynamic> updates) async {
    try {
      final response =
          await _dio!.put('/api/admin/users/$userId', data: updates);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'User updated successfully',
          'user': UserModel.fromJson(response.data['user']),
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to update user',
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

  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final response = await _dio!.delete('/api/admin/users/$userId');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'User deleted successfully',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to delete user',
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

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _dio!.post('/api/admin/users', data: userData);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'User created successfully',
          'user': UserModel.fromJson(response.data['user']),
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to create user',
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

  Future<Map<String, dynamic>> changeUserRole(
      String userId, String newRole) async {
    return updateUser(userId, {'role': newRole});
  }

  Future<Map<String, dynamic>> toggleUserStatus(
      String userId, bool isActive) async {
    return updateUser(userId, {'isActive': isActive});
  }

  Future<Map<String, dynamic>> resetUserPassword(String userId) async {
    try {
      final response =
          await _dio!.post('/api/admin/users/$userId/reset-password');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Password reset successfully',
          'temporaryPassword': response.data['temporaryPassword'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to reset password',
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

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _dio!.get('/api/admin/users/stats');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'stats': response.data['stats'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to load user stats',
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

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response =
          await _dio!.get('/api/admin/users/search', queryParameters: {
        'q': query,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['users'];
        return data.map((item) => UserModel.fromJson(item)).toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to search users');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final response = await _dio!.get('/api/admin/users/by-role/$role');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['users'];
        return data.map((item) => UserModel.fromJson(item)).toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load users by role');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
      String userId, Map<String, dynamic> profileData) async {
    try {
      final response =
          await _dio!.put('/api/users/$userId/profile', data: profileData);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Profile updated successfully',
          'user': UserModel.fromJson(response.data['user']),
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to update profile',
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
}
