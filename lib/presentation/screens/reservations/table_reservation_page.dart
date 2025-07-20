import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../services/recommendation_service.dart';
import '../../../data/models/table_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import 'table_reservation_screen.dart';

class TableReservationPage extends StatefulWidget {
  const TableReservationPage({Key? key}) : super(key: key);

  @override
  State<TableReservationPage> createState() => _TableReservationPageState();
}

class _TableReservationPageState extends State<TableReservationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _recommendedTables = [];
  List<Map<String, dynamic>> _allTables = [];
  bool _isLoadingRecommended = true;
  bool _isLoadingAll = true;
  String? _error;

  // Customization filters - exactly like website
  String _selectedOccasion = 'Any Occasion';
  int _partySize = 2;
  String _timePreference = 'Any Time';

  // Booking form data - exactly like website
  String _selectedDate = '';
  String _selectedTime = '';
  int _guests = 2;

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

  final List<String> _timeSlots = [
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
    '20:30',
    '21:00',
    '21:30',
    '22:00'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadRecommendedTables(),
      _loadAllTables(),
    ]);
  }

  Future<void> _loadRecommendedTables() async {
    try {
      setState(() {
        _isLoadingRecommended = true;
        _error = null;
      });

      print('🔍 Loading table recommendations...');
      final response = await RecommendationService.getTableRecommendations(
        occasion: _selectedOccasion == 'Any Occasion'
            ? ''
            : _selectedOccasion.toLowerCase(),
        partySize: _partySize,
        timeSlot:
            _timePreference == 'Any Time' ? '' : _timePreference.toLowerCase(),
        numRecommendations: 8,
        useCache: false,
      );

      print('📊 Table Recommendation API Response: $response');

      // Check if we got actual table recommendations (not just popular fallback)
      bool isActuallyPersonalized = false;
      final recommendations = response['recommendations'] ?? [];

      if (response['success'] == true && recommendations.isNotEmpty) {
        // Check if these are real recommendations by looking for recommendation-specific fields
        for (var item in recommendations) {
          if (item['reason'] != null ||
              item['score'] != null ||
              item['explanation'] != null ||
              item['rank'] != null) {
            isActuallyPersonalized = true;
            break;
          }
        }
      }

      if (isActuallyPersonalized) {
        print('✅ Got actual table recommendations: ${recommendations.length}');
        final aiRecommendations =
            recommendations.map<Map<String, dynamic>>((item) {
          final table = item['table'] ?? item;
          return {
            '_id': table['_id'] ?? '',
            'tableName': table['tableName'] ?? '',
            'capacity': table['capacity'] ?? 2,
            'location': table['location'] ?? '',
            'image': table['image'] ?? '',
            'status': table['status'] ?? 'Available',
            'avgRating': table['avgRating'] ?? 4.5,
            'recommendationReason': item['reason'] ?? 'ai_recommended',
            'explanation': item['explanation'] ?? 'AI recommended for you',
            'rank': item['rank'] ?? 1,
            'score': item['score'] ?? 0.8,
          };
        }).toList();

        setState(() {
          _recommendedTables = aiRecommendations;
        });

        // If we have fewer than 4 AI recommendations, supplement with popular tables
        if (_recommendedTables.length < 4) {
          print(
              '🔄 Supplementing ${_recommendedTables.length} AI table recommendations with popular tables...');
          await _supplementWithPopularTables();
        }
      } else {
        print(
            '⚠️ No personalized table recommendations available, using curated selection');
        await _loadCuratedTableRecommendations();
      }
    } catch (e) {
      print('❌ Error loading table recommendations: $e');
      setState(() {
        _error = 'Error loading recommendations: $e';
      });
      // Fallback to curated selection
      await _loadCuratedTableRecommendations();
    } finally {
      setState(() {
        _isLoadingRecommended = false;
      });
    }
  }

  Future<void> _loadAllTables() async {
    try {
      setState(() {
        _isLoadingAll = true;
      });

      // Get all tables from API
      final response = await RecommendationService.getPopularTables(limit: 20);

      if (response['success'] == true) {
        final tables = response['popularTables'] ?? [];
        setState(() {
          _allTables = tables
              .map<Map<String, dynamic>>((table) => {
                    '_id': table['_id'] ?? '',
                    'tableName': table['tableName'] ?? '',
                    'capacity': table['capacity'] ?? 2,
                    'location': table['location'] ?? '',
                    'image': table['image'] ?? '',
                    'status': table['status'] ?? 'Available',
                    'avgRating': table['avgRating'] ?? 4.5,
                  })
              .toList();
        });
      }
    } catch (e) {
      print('Error loading all tables: $e');
    } finally {
      setState(() {
        _isLoadingAll = false;
      });
    }
  }

  Future<void> _supplementWithPopularTables() async {
    try {
      if (_allTables.isEmpty) {
        print('⚠️ No tables available for supplementing');
        return;
      }

      // Get existing recommendation IDs to avoid duplicates
      final existingIds =
          _recommendedTables.map((table) => table['_id']).toSet();

      // Get additional high-rated tables not already recommended
      final availableTables = _allTables
          .where((table) =>
              (table['status'] ?? 'Available').toLowerCase() == 'available' &&
              !existingIds.contains(table['_id']))
          .toList();

      // Sort by rating
      availableTables.sort((a, b) {
        final ratingA = (a['avgRating'] ?? 4.0).toDouble();
        final ratingB = (b['avgRating'] ?? 4.0).toDouble();
        return ratingB.compareTo(ratingA);
      });

      // Take up to 4 additional tables to reach a total of 6
      final targetTotal = 6;
      final needed = targetTotal - _recommendedTables.length;
      final supplementTables = availableTables.take(needed).toList();

      if (supplementTables.isNotEmpty) {
        final additionalRecommendations = supplementTables
            .map<Map<String, dynamic>>((table) => {
                  '_id': table['_id'] ?? '',
                  'tableName': table['tableName'] ?? '',
                  'capacity': table['capacity'] ?? 2,
                  'location': table['location'] ?? '',
                  'image': table['image'] ?? '',
                  'status': table['status'] ?? 'Available',
                  'avgRating': table['avgRating'] ?? 4.5,
                  'recommendationReason': 'popular',
                  'explanation': 'Popular choice',
                  'rank': 2,
                  'score': 0.6,
                })
            .toList();

        setState(() {
          _recommendedTables.addAll(additionalRecommendations);
        });

        print(
            '✅ Added ${additionalRecommendations.length} popular tables. Total: ${_recommendedTables.length}');
        print(
            '📋 Final table recommendations: ${_recommendedTables.map((table) => '${table['tableName']} (${table['recommendationReason']})').join(', ')}');
      }
    } catch (e) {
      print('❌ Error supplementing with popular tables: $e');
    }
  }

  Future<void> _loadCuratedTableRecommendations() async {
    try {
      if (_allTables.isEmpty) {
        await _loadAllTables();
      }

      if (_allTables.isEmpty) {
        print('⚠️ No tables available for curated recommendations');
        return;
      }

      // Create curated selection of top-rated available tables
      final availableTables = _allTables
          .where((table) =>
              (table['status'] ?? 'Available').toLowerCase() == 'available')
          .toList();

      // Sort by rating and take top 6
      availableTables.sort((a, b) {
        final ratingA = (a['avgRating'] ?? 4.0).toDouble();
        final ratingB = (b['avgRating'] ?? 4.0).toDouble();
        return ratingB.compareTo(ratingA);
      });

      final curatedTables = availableTables.take(6).toList();

      final curatedRecommendations = curatedTables
          .map<Map<String, dynamic>>((table) => {
                '_id': table['_id'] ?? '',
                'tableName': table['tableName'] ?? '',
                'capacity': table['capacity'] ?? 2,
                'location': table['location'] ?? '',
                'image': table['image'] ?? '',
                'status': table['status'] ?? 'Available',
                'avgRating': table['avgRating'] ?? 4.5,
                'recommendationReason': 'curated',
                'explanation': 'Top rated table',
                'rank': 1,
                'score': 0.7,
              })
          .toList();

      setState(() {
        _recommendedTables = curatedRecommendations;
      });

      print(
          '🎯 Curated table selection: ${curatedRecommendations.map((table) => '${table['tableName']} (${table['avgRating']})').join(', ')}');
    } catch (e) {
      print('❌ Error loading curated table recommendations: $e');
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

    Map<String, Map<String, dynamic>> badges = {
      'collaborative_filtering': {
        'text': 'Similar Users',
        'color': Colors.green,
        'icon': Icons.people
      },
      'content_based': {
        'text': 'Your Taste',
        'color': Colors.blue,
        'icon': Icons.favorite
      },
      'popularity': {
        'text': 'Trending',
        'color': Colors.orange,
        'icon': Icons.trending_up
      },
      'recommended': {
        'text': 'AI Pick',
        'color': Colors.pink,
        'icon': Icons.psychology
      },
    };

    final badge = badges[reason] ?? badges['recommended']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [badge['color'].shade400, badge['color'].shade300],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badge['color'].withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge['icon'], size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            badge['text'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recordInteraction(
      String tableId, String interactionType) async {
    try {
      await RecommendationService.recordTableInteraction(
        tableId: tableId,
        interactionType: interactionType,
        context: {
          'occasion': _selectedOccasion,
          'partySize': _partySize,
          'timePreference': _timePreference,
        },
      );
    } catch (e) {
      print('Error recording interaction: $e');
    }
  }

  void _handleTableTap(Map<String, dynamic> table) async {
    // Record view interaction
    await _recordInteraction(table['_id'], 'view');

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
  }

  void _handleTableFavorite(Map<String, dynamic> table) async {
    await _recordInteraction(table['_id'], 'favorite');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${table['tableName']} added to favorites!'),
        backgroundColor: Colors.pink,
      ),
    );
  }

  Widget _buildRecommendedTablesView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Customization Filters - Exactly like website
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                const Text(
                  '🎯 Customize Your Recommendations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Filter Row
                Row(
                  children: [
                    // Occasion Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🎉 Occasion',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A192F),
                              border: Border.all(
                                  color:
                                      const Color(0xFF64FFDA).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedOccasion,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedOccasion = value!;
                                  });
                                },
                                dropdownColor: const Color(0xFF0A192F),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                                items: _occasions.map((occasion) {
                                  return DropdownMenuItem(
                                    value: occasion,
                                    child: Text(occasion),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Party Size Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '👥 Party Size',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A192F),
                              border: Border.all(
                                  color:
                                      const Color(0xFF64FFDA).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextFormField(
                              initialValue: _partySize.toString(),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _partySize = int.tryParse(value) ?? 2;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Time Preference Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🕐 Time',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A192F),
                              border: Border.all(
                                  color:
                                      const Color(0xFF64FFDA).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _timePreference,
                                onChanged: (value) {
                                  setState(() {
                                    _timePreference = value!;
                                  });
                                },
                                dropdownColor: const Color(0xFF0A192F),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                                items: _timePreferences.map((time) {
                                  return DropdownMenuItem(
                                    value: time,
                                    child: Text(time),
                                  );
                                }).toList(),
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

          // Recommendations Grid
          _isLoadingRecommended
              ? const SizedBox(
                  height: 200,
                  child: Center(child: LoadingWidget()),
                )
              : _error != null
                  ? SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _getRecommendations,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _recommendedTables.isEmpty
                      ? const SizedBox(
                          height: 300,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.table_restaurant_outlined,
                                    color: Colors.grey, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'No recommendations available',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _recommendedTables.length,
                            itemBuilder: (context, index) {
                              final table = _recommendedTables[index];
                              return _buildModernTableCard(table,
                                  isRecommended: true);
                            },
                          ),
                        ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header with gradient
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header Row
                  Row(
                    children: [
                      if (Navigator.canPop(context))
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reserve Tables',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Find your perfect dining spot',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search and notification icons
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Modern Tab Selector
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _tabController.animateTo(0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: _tabController.index == 0
                                    ? LinearGradient(
                                        colors: [
                                          const Color(0xFF64FFDA),
                                          const Color(0xFF4FD1C7),
                                        ],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _tabController.index == 0
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF64FFDA)
                                              .withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.psychology_outlined,
                                    size: 20,
                                    color: _tabController.index == 0
                                        ? const Color(0xFF0F172A)
                                        : Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'FOR YOU',
                                    style: TextStyle(
                                      color: _tabController.index == 0
                                          ? const Color(0xFF0F172A)
                                          : Colors.white.withOpacity(0.8),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _tabController.animateTo(1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: _tabController.index == 1
                                    ? LinearGradient(
                                        colors: [
                                          const Color(0xFF64FFDA),
                                          const Color(0xFF4FD1C7),
                                        ],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _tabController.index == 1
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF64FFDA)
                                              .withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant_outlined,
                                    size: 20,
                                    color: _tabController.index == 1
                                        ? const Color(0xFF0F172A)
                                        : Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ALL TABLES',
                                    style: TextStyle(
                                      color: _tabController.index == 1
                                          ? const Color(0xFF0F172A)
                                          : Colors.white.withOpacity(0.8),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content with proper scrolling
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Recommended Tables Tab
                    _buildRecommendedTablesView(),

                    // All Tables Tab
                    _buildAllTablesView(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTablesView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: _isLoadingAll
          ? const SizedBox(
              height: 200,
              child: Center(child: LoadingWidget()),
            )
          : _allTables.isEmpty
              ? const SizedBox(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_restaurant_outlined,
                            color: Colors.grey, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'No tables available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _allTables.length,
                    itemBuilder: (context, index) {
                      final table = _allTables[index];
                      return _buildModernTableCard(table, isRecommended: false);
                    },
                  ),
                ),
    );
  }

  Widget _buildModernTableCard(Map<String, dynamic> table,
      {bool isRecommended = false}) {
    final imageUrl = _getImageUrl(table['image']);
    final rating = (table['avgRating'] ?? 4.5).toDouble();
    final status = table['status'] ?? 'Available';
    final isAvailable = status.toLowerCase() == 'available';

    return GestureDetector(
      onTap: () => _handleTableTap(table),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E293B).withValues(alpha: 0.8),
              const Color(0xFF0F172A).withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAvailable
                ? const Color(0xFF64FFDA).withValues(alpha: 0.4)
                : Colors.red.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isAvailable ? const Color(0xFF64FFDA) : Colors.red)
                  .withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Image Section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Table image with modern styling
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          // Handle image loading error
                        },
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Modern Recommendation badge with proper type
                  if (isRecommended)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _getRecommendationBadge(
                          table['recommendationReason']),
                    ),

                  // Modern Status badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: (isAvailable
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                .withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Modern Favorite button
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _handleTableFavorite(table),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Modern Table details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Table name with modern styling
                    Text(
                      table['tableName'] ?? 'Unknown Table',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Location and capacity with modern icons
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF64FFDA).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF64FFDA),
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            table['location'] ?? 'Main Hall',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF64FFDA).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${table['capacity'] ?? 2} seats',
                            style: const TextStyle(
                              color: Color(0xFF64FFDA),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Rating with modern design
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Reserve button
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF64FFDA), Color(0xFF4FD1C7)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF64FFDA)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Reserve',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Recommendation explanation (only for recommended tables)
                    if (isRecommended && table['explanation'] != null)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64FFDA)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF64FFDA)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              table['explanation'],
                              style: TextStyle(
                                color: const Color(0xFF64FFDA)
                                    .withValues(alpha: 0.9),
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
    );
  }
}
