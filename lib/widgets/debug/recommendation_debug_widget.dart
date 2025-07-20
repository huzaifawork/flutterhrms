import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/recommendation_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/config/environment.dart';

class RecommendationDebugWidget extends StatefulWidget {
  const RecommendationDebugWidget({Key? key}) : super(key: key);

  @override
  State<RecommendationDebugWidget> createState() => _RecommendationDebugWidgetState();
}

class _RecommendationDebugWidgetState extends State<RecommendationDebugWidget> {
  Map<String, dynamic> _debugInfo = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final debugInfo = <String, dynamic>{};

      // Environment Configuration
      debugInfo['environment'] = {
        'apiBaseUrl': Environment.currentApiUrl,
        'socketUrl': Environment.currentSocketUrl,
        'stripeKey': Environment.currentStripeKey.substring(0, 20) + '...',
        'isProduction': Environment.isProduction,
        'enableLogging': Environment.enableLogging,
      };

      // API Configuration
      debugInfo['apiConfig'] = {
        'baseUrl': ApiConstants.baseUrl,
        'foodRecommendationsEndpoint': ApiConstants.foodRecommendationsEndpoint,
        'roomsEndpoint': ApiConstants.roomsEndpoint,
        'tablesEndpoint': ApiConstants.tablesEndpoint,
      };

      // User Authentication
      debugInfo['auth'] = {
        'userId': prefs.getString('userId'),
        'token': prefs.getString('token')?.substring(0, 20) ?? 'null',
        'userRole': prefs.getString('userRole'),
      };

      // Test API Endpoints
      debugInfo['apiTests'] = {};

      // Test Popular Food Items
      try {
        final foodResponse = await RecommendationService.getPopularFoodItems(count: 3);
        debugInfo['apiTests']['popularFood'] = {
          'success': foodResponse['success'],
          'itemCount': foodResponse['popularItems']?.length ?? 0,
          'error': foodResponse['error'],
          'sampleItem': foodResponse['popularItems']?.isNotEmpty == true 
              ? foodResponse['popularItems'][0] 
              : null,
        };
      } catch (e) {
        debugInfo['apiTests']['popularFood'] = {
          'success': false,
          'error': e.toString(),
        };
      }

      // Test Popular Rooms
      try {
        final roomResponse = await RecommendationService.getPopularRooms(count: 3);
        debugInfo['apiTests']['popularRooms'] = {
          'success': roomResponse['success'],
          'itemCount': roomResponse['popularRooms']?.length ?? 0,
          'error': roomResponse['error'],
          'sampleItem': roomResponse['popularRooms']?.isNotEmpty == true 
              ? roomResponse['popularRooms'][0] 
              : null,
        };
      } catch (e) {
        debugInfo['apiTests']['popularRooms'] = {
          'success': false,
          'error': e.toString(),
        };
      }

      // Test Popular Tables
      try {
        final tableResponse = await RecommendationService.getPopularTables(limit: 3);
        debugInfo['apiTests']['popularTables'] = {
          'success': tableResponse['success'],
          'itemCount': tableResponse['popularTables']?.length ?? 0,
          'error': tableResponse['error'],
          'sampleItem': tableResponse['popularTables']?.isNotEmpty == true 
              ? tableResponse['popularTables'][0] 
              : null,
        };
      } catch (e) {
        debugInfo['apiTests']['popularTables'] = {
          'success': false,
          'error': e.toString(),
        };
      }

      setState(() {
        _debugInfo = debugInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendation Debug'),
        backgroundColor: const Color(0xFF0A192F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0A192F),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFBB86FC)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Environment Configuration', _debugInfo['environment']),
                  const SizedBox(height: 16),
                  _buildSection('API Configuration', _debugInfo['apiConfig']),
                  const SizedBox(height: 16),
                  _buildSection('Authentication', _debugInfo['auth']),
                  const SizedBox(height: 16),
                  _buildSection('API Tests', _debugInfo['apiTests']),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, dynamic data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFBB86FC),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDataDisplay(data),
        ],
      ),
    );
  }

  Widget _buildDataDisplay(dynamic data) {
    if (data == null) {
      return const Text(
        'No data available',
        style: TextStyle(color: Colors.grey),
      );
    }

    if (data is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '${entry.key}:',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildValueDisplay(entry.value),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return _buildValueDisplay(data);
  }

  Widget _buildValueDisplay(dynamic value) {
    Color textColor = Colors.white;
    String displayText = value.toString();

    if (value is bool) {
      textColor = value ? Colors.green : Colors.red;
      displayText = value.toString().toUpperCase();
    } else if (value is String && value.toLowerCase().contains('error')) {
      textColor = Colors.red;
    } else if (value is String && value.toLowerCase().contains('success')) {
      textColor = Colors.green;
    }

    return Text(
      displayText,
      style: TextStyle(
        color: textColor,
        fontSize: 14,
      ),
    );
  }
}
