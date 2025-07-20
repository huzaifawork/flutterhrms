import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/environment.dart';
import 'mock_api.dart';

class APIService {
  // Singleton pattern
  static final APIService _instance = APIService._internal();
  static APIService get instance => _instance;
  factory APIService() => _instance;
  APIService._internal();

  // API availability tracking
  static bool _apiAvailable = false;
  static bool get isApiAvailable => _apiAvailable;
  static DateTime _lastAPICheck =
      DateTime.now().subtract(const Duration(minutes: 5));
  static const Duration _minCheckInterval = Duration(seconds: 30);

  // Use mock data (set to false to prioritize real API data)
  bool _useMockData = false;
  bool get useMockData => _useMockData;

  // Base URL configuration
  static String get baseUrl {
    // Use environment configuration first
    if (Environment.currentApiUrl.isNotEmpty) {
      return Environment.currentApiUrl;
    }

    // Fallback to platform-specific URLs for development
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    // For Android emulator, use 10.0.2.2 to access localhost
    else if (Platform.isAndroid) {
      // For real Android devices, use the computer's IP address
      return 'http://192.168.10.6:8080';
    }
    // For iOS simulator, use localhost
    else if (Platform.isIOS) {
      return 'http://localhost:8080';
    }
    // Fallback to localhost
    else {
      return 'http://localhost:8080';
    }
  }

  // Create a complete URL for a specific API endpoint
  static String url(String endpoint) {
    // Ensure endpoint starts with a slash
    if (!endpoint.startsWith('/')) {
      endpoint = '/$endpoint';
    }
    return '$baseUrl$endpoint';
  }

  // Get headers for API requests
  static Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Add additional headers if needed for authentication
    };
  }

  // Check if the API is available (with rate limiting)
  Future<bool> checkApiAvailability() async {
    // If we're explicitly using mock data, don't check the API
    if (_useMockData) {
      return false;
    }

    // Avoid checking too frequently
    final now = DateTime.now();
    if (now.difference(_lastAPICheck) < _minCheckInterval) {
      return _apiAvailable;
    }

    try {
      print('Checking API availability at: $baseUrl/api/health');
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/health'),
            headers: getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      _lastAPICheck = now;
      _apiAvailable = response.statusCode == 200;
      print(
          'API availability check result: $_apiAvailable (${response.statusCode})');
      return _apiAvailable;
    } catch (e) {
      _lastAPICheck = now;
      _apiAvailable = false;
      print('API availability check error: $e');
      return false;
    }
  }

  // Force using mock data for testing
  void setUseMockData(bool value) {
    _useMockData = value;
  }

  // General method to make GET requests
  Future<http.Response> get(String endpoint) async {
    // Always try to use real API first unless we're explicitly using mock data
    if (_useMockData) {
      print('Using mock data for: $endpoint');
      return _getMockResponse(endpoint);
    }

    // Try real API call
    final url = APIService.url(endpoint);
    print('Making GET request to: $url');

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print('Response received with status code: ${response.statusCode}');

      // Check for error status codes
      if (response.statusCode >= 400) {
        print('API error: ${response.statusCode} - ${response.body}');
        // For error status codes, fallback to mock data
        return _getMockResponse(endpoint);
      }

      // If successful, return the real response
      return response;
    } catch (e) {
      // Detailed error logging
      String errorMessage = 'API request failed: $e';
      if (e.toString().contains('SocketException')) {
        errorMessage =
            'Connection refused. Is your backend server running at $url?';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage =
            'Request timed out. Backend server at $url is taking too long to respond.';
      } else if (e.toString().contains('Failed to fetch')) {
        if (kIsWeb) {
          errorMessage =
              'CORS issue or server unavailable. Make sure your backend allows cross-origin requests.';
        } else {
          errorMessage = 'Failed to connect to $url. Is the server running?';
        }
      }

      print(errorMessage);
      print('Automatically falling back to mock data');

      // Always fall back to mock data for development experience
      return _getMockResponse(endpoint);
    }
  }

  // Helper method to get mock responses
  http.Response _getMockResponse(String endpoint) {
    print('Using mock data for: $endpoint');

    // Return mock data based on the endpoint
    Map<String, dynamic> mockResponse;

    if (endpoint.contains('api/health')) {
      mockResponse = MockApi.mockResponse(MockApi.getHealth());
    } else if (endpoint.contains('api/menus')) {
      if (endpoint.contains('/')) {
        // Single menu item request
        String id = endpoint.split('/').last;
        var items = MockApi.getMenuItems();
        var item = items.firstWhere((menu) => menu['id'] == id,
            orElse: () => items.first);
        mockResponse = MockApi.mockResponse([item]);
      } else {
        // All menu items
        mockResponse = MockApi.mockResponse(MockApi.getMenuItems());
      }
    } else if (endpoint.contains('api/rooms')) {
      if (endpoint.contains('/') && !endpoint.endsWith('/rooms')) {
        // Single room request
        String id = endpoint.split('/').last;
        var items = MockApi.getRooms();
        var item = items.firstWhere((room) => room['id'] == id,
            orElse: () => items.first);
        mockResponse = MockApi.mockResponse([item]);
      } else {
        // All rooms
        mockResponse = MockApi.mockResponse(MockApi.getRooms());
      }
    } else if (endpoint.contains('api/tables')) {
      if (endpoint.contains('/') && !endpoint.endsWith('/tables')) {
        // Single table request
        String id = endpoint.split('/').last;
        var items = MockApi.getTables();
        var item = items.firstWhere((table) => table['id'] == id,
            orElse: () => items.first);
        mockResponse = MockApi.mockResponse([item]);
      } else {
        // All tables
        mockResponse = MockApi.mockResponse(MockApi.getTables());
      }
    } else {
      // Default mock response for unknown endpoints
      mockResponse = {
        'statusCode': 404,
        'body': jsonEncode({'error': 'Not found', 'endpoint': endpoint})
      };
    }

    // Create a fake Response object
    return http.Response(
      mockResponse['body'],
      mockResponse['statusCode'],
      headers: {'content-type': 'application/json'},
    );
  }

  // Map API paths for image URLs
  static String mapImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'https://via.placeholder.com/400x300?text=No+Image';
    }

    print('Original image path: $imagePath');

    // If it's already a full URL, return it as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      print('Using original image URL: $imagePath');
      return imagePath;
    }

    // Clean up the image path
    // Replace backslashes with forward slashes and handle any spaces
    String cleanPath = imagePath.replaceAll('\\', '/').replaceAll(' ', '%20');

    // Remove any leading slashes to avoid double slashes
    while (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // Add a single leading slash
    cleanPath = '/$cleanPath';

    // If it's a relative path, prepend the base URL
    String fullUrl = '$baseUrl$cleanPath';
    print('Mapped image URL: $fullUrl');
    return fullUrl;
  }
}
// Minor change for contribution
