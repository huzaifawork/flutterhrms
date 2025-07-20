import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../data/models/table_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import 'table_reservation_screen.dart';

class EnhancedTableReservationScreen extends StatefulWidget {
  const EnhancedTableReservationScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedTableReservationScreen> createState() =>
      _EnhancedTableReservationScreenState();
}

class _EnhancedTableReservationScreenState
    extends State<EnhancedTableReservationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _recommendedTables = [];
  List<Map<String, dynamic>> _allTables = [];
  bool _isLoadingRecommended = true;
  bool _isLoadingAll = true;
  String? _error;

  // Customization filters
  String _selectedOccasion = 'Any Occasion';
  int _partySize = 2;
  String _timePreference = 'Any Time';

  final List<String> _occasions = [
    'Any Occasion',
    'Romantic',
    'Business',
    'Family',
    'Friends',
    'Celebration',
    'Casual'
  ];

  final List<String> _timePreferences = [
    'Any Time',
    'Morning',
    'Afternoon',
    'Evening',
    'Night'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecommendedTables();
    _loadAllTables();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendedTables() async {
    try {
      setState(() {
        _isLoadingRecommended = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');

      if (token != null && userId != null) {
        final response = await http.get(
          Uri.parse(
              'http://localhost:8080/api/tables/recommendations/$userId?numRecommendations=6&occasion=${_selectedOccasion.toLowerCase()}&timeSlot=${_timePreference.toLowerCase()}&partySize=$_partySize'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final recommendations = data['recommendations'] ?? [];
            setState(() {
              _recommendedTables =
                  recommendations.map<Map<String, dynamic>>((item) {
                final table = item['table'] ?? item;
                return {
                  '_id': table['_id'] ?? '',
                  'tableName': table['tableName'] ?? '',
                  'tableType': table['tableType'] ?? '',
                  'capacity': table['capacity'] ?? 0,
                  'status': table['status'] ?? 'Available',
                  'location': table['location'] ?? '',
                  'image': table['image'] ?? '',
                  'avgRating': table['avgRating'] ?? 4.5,
                  'description': table['description'] ?? '',
                  'ambiance': table['ambiance'] ?? 'Casual',
                  'hasWindowView': table['hasWindowView'] ?? false,
                  'isPrivate': table['isPrivate'] ?? false,
                  'priceTier': table['priceTier'] ?? 'Mid-range',
                  'features': table['features'] ?? [],
                  'recommendationReason': item['reason'] ?? 'contextual',
                  'score': item['score'] ?? 0.8,
                  'explanation': item['explanation'] ?? 'Recommended for you',
                };
              }).toList();
              _isLoadingRecommended = false;
            });
          }
        }
      } else {
        // Fallback to popular tables for non-logged-in users
        await _loadPopularTables();
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading recommendations: $e';
        _isLoadingRecommended = false;
      });
    }
  }

  Future<void> _loadPopularTables() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/tables/popular?count=6'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final popularTables = data['popularTables'] ?? [];
          setState(() {
            _recommendedTables = popularTables
                .map<Map<String, dynamic>>((table) => {
                      '_id': table['_id'] ?? '',
                      'tableName': table['tableName'] ?? '',
                      'tableType': table['tableType'] ?? '',
                      'capacity': table['capacity'] ?? 0,
                      'status': table['status'] ?? 'Available',
                      'location': table['location'] ?? '',
                      'image': table['image'] ?? '',
                      'avgRating': table['avgRating'] ?? 4.5,
                      'description': table['description'] ?? '',
                      'ambiance': table['ambiance'] ?? 'Casual',
                      'hasWindowView': table['hasWindowView'] ?? false,
                      'isPrivate': table['isPrivate'] ?? false,
                      'priceTier': table['priceTier'] ?? 'Mid-range',
                      'features': table['features'] ?? [],
                      'recommendationReason': 'popularity',
                      'score': 0.9,
                      'explanation': 'Popular table with high ratings',
                    })
                .toList();
            _isLoadingRecommended = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading popular tables: $e';
        _isLoadingRecommended = false;
      });
    }
  }

  Future<void> _loadAllTables() async {
    try {
      setState(() {
        _isLoadingAll = true;
      });

      final response = await http.get(
        Uri.parse('http://localhost:8080/api/tables'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            _allTables = data
                .map<Map<String, dynamic>>((table) => {
                      '_id': table['_id'] ?? '',
                      'tableName': table['tableName'] ?? '',
                      'tableType': table['tableType'] ?? '',
                      'capacity': table['capacity'] ?? 0,
                      'status': table['status'] ?? 'Available',
                      'location': table['location'] ?? '',
                      'image': table['image'] ?? '',
                      'avgRating': table['avgRating'] ?? 4.5,
                      'description': table['description'] ?? '',
                      'ambiance': table['ambiance'] ?? 'Casual',
                      'hasWindowView': table['hasWindowView'] ?? false,
                      'isPrivate': table['isPrivate'] ?? false,
                      'priceTier': table['priceTier'] ?? 'Mid-range',
                      'features': table['features'] ?? [],
                    })
                .toList();
            _isLoadingAll = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading tables: $e';
        _isLoadingAll = false;
      });
    }
  }

  Future<void> _getRecommendations() async {
    await _loadRecommendedTables();
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'https://via.placeholder.com/300x200?text=Table';
    }
    if (imagePath.startsWith('http')) return imagePath;
    final cleanPath = imagePath.replaceAll(RegExp(r'^/+'), '');
    return cleanPath.contains('uploads')
        ? 'http://localhost:8080/$cleanPath'
        : 'http://localhost:8080/uploads/$cleanPath';
  }

  Widget _getRecommendationBadge(String? reason) {
    if (reason == null) return const SizedBox.shrink();

    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (reason) {
      case 'collaborative_filtering':
        badgeColor = Colors.blue;
        badgeText = 'Similar Users';
        badgeIcon = Icons.people;
        break;
      case 'content_based':
        badgeColor = Colors.green;
        badgeText = 'Your Taste';
        badgeIcon = Icons.favorite;
        break;
      case 'popularity':
        badgeColor = Colors.orange;
        badgeText = 'Trending';
        badgeIcon = Icons.trending_up;
        break;
      case 'contextual':
        badgeColor = Colors.purple;
        badgeText = 'AI Pick';
        badgeIcon = Icons.psychology;
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = 'Recommended';
        badgeIcon = Icons.star;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      appBar: AppBar(
        title: const Text(
          'Reserve a Table',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0A192F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFBB86FC)],
                  ).createShader(bounds),
                  child: const Text(
                    'Book your perfect dining experience',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFBB86FC), Color(0xFF64FFDA)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.7),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.psychology, size: 16),
                            SizedBox(width: 8),
                            Text('RECOMMENDED FOR YOU'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.table_restaurant, size: 16),
                            SizedBox(width: 8),
                            Text('ALL TABLES'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Customization Section (only show for recommended tab)
          if (_tabController.index == 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.1),
                    Colors.orange.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Customize Your Recommendations',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Occasion Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Occasion',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedOccasion,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1A2332),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                  items: _occasions.map((occasion) {
                                    return DropdownMenuItem(
                                      value: occasion,
                                      child: Text(occasion),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedOccasion = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Party Size
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Party Size',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: _partySize > 1
                                      ? () {
                                          setState(() {
                                            _partySize--;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.remove, size: 16),
                                  color: Colors.white,
                                  constraints: const BoxConstraints(
                                      minWidth: 24, minHeight: 24),
                                ),
                                Text(
                                  '$_partySize',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                ),
                                IconButton(
                                  onPressed: _partySize < 10
                                      ? () {
                                          setState(() {
                                            _partySize++;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.add, size: 16),
                                  color: Colors.white,
                                  constraints: const BoxConstraints(
                                      minWidth: 24, minHeight: 24),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Time Preference
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Time Preference',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _timePreference,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1A2332),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                  items: _timePreferences.map((time) {
                                    return DropdownMenuItem(
                                      value: time,
                                      child: Text(time),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _timePreference = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Get Recommendations Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _getRecommendations,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBB86FC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Get Recommendations',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Recommended Tables Tab
                _buildRecommendedTablesView(),

                // All Tables Tab
                _buildAllTablesView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedTablesView() {
    if (_isLoadingRecommended) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFBB86FC)),
            SizedBox(height: 16),
            Text(
              'Finding perfect tables for you...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRecommendedTables,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_recommendedTables.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant_outlined, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No recommendations available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _recommendedTables.length,
        itemBuilder: (context, index) {
          final table = _recommendedTables[index];
          return _buildTableCard(table, isRecommended: true);
        },
      ),
    );
  }

  Widget _buildAllTablesView() {
    if (_isLoadingAll) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFBB86FC)),
            SizedBox(height: 16),
            Text(
              'Loading all tables...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_allTables.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant_outlined, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No tables available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _allTables.length,
        itemBuilder: (context, index) {
          final table = _allTables[index];
          return _buildTableCard(table, isRecommended: false);
        },
      ),
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table,
      {required bool isRecommended}) {
    return GestureDetector(
      onTap: () {
        // Convert to TableModel and navigate to reservation screen
        final tableModel = TableModel(
          id: table['_id'],
          tableNumber: table['tableName'] ?? 'Unknown',
          capacity: table['capacity'],
          status: table['status'] ?? 'Available',
          location: table['location'] ?? 'Main Hall',
          imageUrl: _getImageUrl(table['image']),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TableReservationScreen(table: tableModel),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Image Section
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Table Image
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(_getImageUrl(table['image'])),
                          fit: BoxFit.cover,
                          onError: (error, stackTrace) {
                            print('Error loading table image: $error');
                          },
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Recommendation Badge
                    if (isRecommended && table['recommendationReason'] != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _getRecommendationBadge(
                            table['recommendationReason']),
                      ),

                    // Status Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: table['status'] == 'Available'
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          table['status'] ?? 'Available',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Rating Badge
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              (table['avgRating'] ?? 4.5).toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Table Title
                      Text(
                        table['tableName'] ?? 'Premium Table',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Colors.white, Color(0xFFBB86FC)],
                            ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Table Info
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${table['capacity']} seats',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              table['location'] ?? 'Main Hall',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Ambiance
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBB86FC).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          table['ambiance'] ?? 'Casual',
                          style: const TextStyle(
                            color: Color(0xFFBB86FC),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Reserve Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: table['status'] == 'Available'
                              ? () {
                                  final tableModel = TableModel(
                                    id: table['_id'],
                                    tableNumber:
                                        table['tableName'] ?? 'Unknown',
                                    capacity: table['capacity'],
                                    status: table['status'] ?? 'Available',
                                    location: table['location'] ?? 'Main Hall',
                                    imageUrl: _getImageUrl(table['image']),
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TableReservationScreen(
                                              table: tableModel),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: table['status'] == 'Available'
                                ? const Color(0xFFBB86FC)
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            table['status'] == 'Available'
                                ? 'Reserve Now'
                                : 'Unavailable',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
