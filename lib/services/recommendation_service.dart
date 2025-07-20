import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../data/models/menu_item_model.dart';

class RecommendationService {
  static String get baseUrl => ApiConstants.baseUrl;

  // Get authorization headers
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey) ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get current user ID
  static Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.userIdKey);
    print('Debug: Retrieved user ID from SharedPreferences: $userId');
    return userId;
  }

  // Debug method to check stored values
  static Future<Map<String, String?>> debugGetStoredValues() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(AppConstants.userIdKey),
      'token': prefs.getString(AppConstants.tokenKey),
      'userRole': prefs.getString(AppConstants.userRoleKey),
    };
  }

  // Food Recommendations
  static Future<Map<String, dynamic>> getFoodRecommendations({
    String? userId,
    int count = 10,
  }) async {
    try {
      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
            '$baseUrl/food-recommendations/recommendations/$currentUserId?count=$count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both array and object responses
        if (data is List) {
          return {
            'success': true,
            'recommendations': data,
          };
        } else if (data is Map<String, dynamic>) {
          return data;
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
          };
        }
      } else {
        // Fallback to popular items
        return await getPopularFoodItems(count: count);
      }
    } catch (e) {
      print('Error getting food recommendations: $e');
      // Fallback to popular items
      return await getPopularFoodItems(count: count);
    }
  }

  // Get Pakistani cuisine recommendations
  static Future<Map<String, dynamic>> getPakistaniFoodRecommendations({
    String? userId,
    int count = 10,
  }) async {
    try {
      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse(
            '$baseUrl/food-recommendations/pakistani-recommendations/$currentUserId?count=$count'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get Pakistani recommendations');
      }
    } catch (e) {
      print('Error getting Pakistani recommendations: $e');
      // Fallback to popular items
      return await getPopularFoodItems(count: count);
    }
  }

  // Get popular food items
  static Future<Map<String, dynamic>> getPopularFoodItems({
    int count = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/food-recommendations/popular?count=$count'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both array and object responses
        if (data is List) {
          return {
            'success': true,
            'popularItems': data,
          };
        } else if (data is Map<String, dynamic>) {
          return data;
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Failed to get popular items',
        };
      }
    } catch (e) {
      print('Error getting popular items: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Record food interaction
  static Future<bool> recordFoodInteraction({
    required String menuItemId,
    required String interactionType, // 'rating', 'order', 'view', 'favorite'
    int? rating,
    int orderQuantity = 1,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/food-recommendations/interaction'),
        headers: headers,
        body: json.encode({
          'userId': userId,
          'menuItemId': menuItemId,
          'interactionType': interactionType,
          'rating': rating,
          'orderQuantity': orderQuantity,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error recording food interaction: $e');
      return false;
    }
  }

  // Rate a menu item
  static Future<bool> rateMenuItem({
    required String menuItemId,
    required int rating,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/food-recommendations/rate'),
        headers: headers,
        body: json.encode({
          'userId': userId,
          'menuItemId': menuItemId,
          'rating': rating,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error rating menu item: $e');
      return false;
    }
  }

  // Record order interactions
  static Future<bool> recordOrderInteractions({
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/food-recommendations/order-interaction'),
        headers: headers,
        body: json.encode({
          'userId': userId,
          'items': items,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error recording order interactions: $e');
      return false;
    }
  }

  // Room Recommendations
  static Future<Map<String, dynamic>> getRoomRecommendations({
    String? userId,
    int count = 6,
    String? occasion,
    int? groupSize,
    String? budgetRange,
  }) async {
    try {
      final currentUserId = userId ?? await _getCurrentUserId();

      if (currentUserId != null) {
        // Get personalized recommendations for logged-in users
        final headers = await _getHeaders();

        // Build query parameters
        final queryParams = <String, String>{
          'count': count.toString(),
        };

        if (occasion != null && occasion.isNotEmpty) {
          queryParams['occasion'] = occasion;
        }
        if (groupSize != null) {
          queryParams['groupSize'] = groupSize.toString();
        }
        if (budgetRange != null && budgetRange.isNotEmpty) {
          queryParams['budgetRange'] = budgetRange;
        }

        final uri = Uri.parse('$baseUrl/rooms/recommendations/$currentUserId')
            .replace(queryParameters: queryParams);

        final response = await http.get(uri, headers: headers);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          // Handle both array and object responses
          if (data is List) {
            return {
              'success': true,
              'recommendations': data,
            };
          } else if (data is Map<String, dynamic>) {
            return data;
          } else {
            return {
              'success': false,
              'error': 'Invalid response format',
            };
          }
        }
      }

      // Fallback to popular rooms
      return await getPopularRooms(count: count);
    } catch (e) {
      print('Error getting room recommendations: $e');
      // Fallback to popular rooms
      return await getPopularRooms(count: count);
    }
  }

  // Get popular rooms
  static Future<Map<String, dynamic>> getPopularRooms({
    int count = 6,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rooms/popular?count=$count'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both array and object responses
        if (data is List) {
          return {
            'success': true,
            'popularRooms': data,
          };
        } else if (data is Map<String, dynamic>) {
          return data;
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Failed to get popular rooms',
        };
      }
    } catch (e) {
      print('Error getting popular rooms: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Record room interaction
  static Future<bool> recordRoomInteraction({
    required String roomId,
    required String
        interactionType, // 'view', 'inquiry', 'favorite', 'share', 'rating', 'booking'
    int? rating,
    int? sessionDuration,
    Map<String, dynamic>? context,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rooms/interactions'),
        headers: headers,
        body: json.encode({
          'userId': userId,
          'roomId': roomId,
          'interactionType': interactionType,
          'rating': rating,
          'sessionDuration': sessionDuration,
          'context': context ?? {},
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error recording room interaction: $e');
      return false;
    }
  }

  // Table Recommendations
  static Future<Map<String, dynamic>> getTableRecommendations({
    String? userId,
    String occasion = 'casual',
    int partySize = 2,
    String timeSlot = 'evening',
    int numRecommendations = 10,
    bool useCache = true,
  }) async {
    try {
      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final headers = await _getHeaders();
      final queryParams = {
        'occasion': occasion,
        'partySize': partySize.toString(),
        'timeSlot': timeSlot,
        'numRecommendations': numRecommendations.toString(),
        'useCache': useCache.toString(),
      };

      final uri = Uri.parse('$baseUrl/tables/recommendations/$currentUserId')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both array and object responses
        if (data is List) {
          return {
            'success': true,
            'recommendations': data,
          };
        } else if (data is Map<String, dynamic>) {
          return data;
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
          };
        }
      } else {
        // Fallback to popular tables
        return await getPopularTables(limit: numRecommendations);
      }
    } catch (e) {
      print('Error getting table recommendations: $e');
      // Fallback to popular tables
      return await getPopularTables(limit: numRecommendations);
    }
  }

  // Get popular tables
  static Future<Map<String, dynamic>> getPopularTables({
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tables/popular?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both array and object responses
        if (data is List) {
          return {
            'success': true,
            'popularTables': data,
          };
        } else if (data is Map<String, dynamic>) {
          return data;
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Failed to get popular tables',
        };
      }
    } catch (e) {
      print('Error getting popular tables: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Record table interaction
  static Future<bool> recordTableInteraction({
    required String tableId,
    required String
        interactionType, // 'view', 'inquiry', 'favorite', 'share', 'rating', 'booking'
    int? rating,
    int? sessionDuration,
    Map<String, dynamic>? context,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tables/interactions'),
        headers: headers,
        body: json.encode({
          'userId': userId,
          'tableId': tableId,
          'interactionType': interactionType,
          'rating': rating,
          'sessionDuration': sessionDuration,
          'context': context ?? {},
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error recording table interaction: $e');
      return false;
    }
  }

  // Get user's food interaction history
  static Future<Map<String, dynamic>> getUserFoodHistory({
    String? userId,
    int days = 30,
  }) async {
    try {
      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/recommendations/history/$currentUserId?days=$days'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get user history');
      }
    } catch (e) {
      print('Error getting user food history: $e');
      rethrow;
    }
  }

  // Get user's table interaction history
  static Future<Map<String, dynamic>> getUserTableHistory({
    String? userId,
    int limit = 50,
    String? interactionType,
  }) async {
    try {
      final currentUserId = userId ?? await _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final headers = await _getHeaders();
      final queryParams = {
        'limit': limit.toString(),
        if (interactionType != null) 'interactionType': interactionType,
      };

      final uri = Uri.parse('$baseUrl/tables/history/$currentUserId')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get table history');
      }
    } catch (e) {
      print('Error getting user table history: $e');
      rethrow;
    }
  }

  // New methods to match website API structure

  // Get personalized recommendations for a user
  Future<List<MenuItemModel>> getPersonalizedRecommendations(
      String userId, int maxItems) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/food-recommendations/recommendations/$userId?count=$maxItems'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['recommendations'] != null) {
          final List<dynamic> recommendations = data['recommendations'];
          return recommendations
              .map((item) => MenuItemModel.fromJson(item))
              .toList();
        }
      }

      // Fallback to popular items
      return await getPopularItems(maxItems);
    } catch (e) {
      print('Error getting personalized recommendations: $e');
      return await getPopularItems(maxItems);
    }
  }

  // Get popular items
  Future<List<MenuItemModel>> getPopularItems(int maxItems) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/food-recommendations/popular?count=$maxItems'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['popularItems'] != null) {
          final List<dynamic> popularItems = data['popularItems'];
          return popularItems
              .map((item) => MenuItemModel.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('Error getting popular items: $e');
      return [];
    }
  }

  // Record interaction
  Future<void> recordInteraction(
      String userId, String menuItemId, String interactionType) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/food-recommendations/interactions'),
        headers: await _getHeaders(),
        body: json.encode({
          'userId': userId,
          'menuItemId': menuItemId,
          'interactionType': interactionType,
        }),
      );
    } catch (e) {
      print('Error recording interaction: $e');
    }
  }

  // Rate menu item (instance method)
  Future<void> rateMenuItemInstance(
      String userId, String menuItemId, double rating) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/food-recommendations/interactions'),
        headers: await _getHeaders(),
        body: json.encode({
          'userId': userId,
          'menuItemId': menuItemId,
          'interactionType': 'rating',
          'rating': rating,
        }),
      );
    } catch (e) {
      print('Error rating menu item: $e');
    }
  }
}
