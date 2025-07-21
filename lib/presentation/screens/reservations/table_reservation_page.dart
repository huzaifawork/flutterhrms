import 'package:flutter/material.dart';
import 'package:hrms_mobile_app/core/config/environment.dart';
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

      bool isActuallyPersonalized = false;
      final recommendations = response['recommendations'] ?? [];

      if (response['success'] == true && recommendations.isNotEmpty) {
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

        if (_recommendedTables.length < 4) {
          await _supplementWithPopularTables();
        }
      } else {
        await _loadCuratedTableRecommendations();
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading recommendations: $e';
      });
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
        return;
      }

      final existingIds =
          _recommendedTables.map((table) => table['_id']).toSet();

      final availableTables = _allTables
          .where((table) =>
              (table['status'] ?? 'Available').toLowerCase() == 'available' &&
              !existingIds.contains(table['_id']))
          .toList();

      availableTables.sort((a, b) {
        final ratingA = (a['avgRating'] ?? 4.0).toDouble();
        final ratingB = (b['avgRating'] ?? 4.0).toDouble();
        return ratingB.compareTo(ratingA);
      });

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
      }
    } catch (e) {
      print('Error supplementing with popular tables: $e');
    }
  }

  Future<void> _loadCuratedTableRecommendations() async {
    try {
      if (_allTables.isEmpty) {
        await _loadAllTables();
      }

      if (_allTables.isEmpty) {
        return;
      }

      final availableTables = _allTables
          .where((table) =>
              (table['status'] ?? 'Available').toLowerCase() == 'available')
          .toList();

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
    } catch (e) {
      print('Error loading curated table recommendations: $e');
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
        ? '${Environment.currentApiUrl}/$cleanPath'
        : '${Environment.currentApiUrl}/uploads/$cleanPath';
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
    await _recordInteraction(table['_id'], 'view');

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
          // Customization Filters
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                // Filter Row - Made responsive with Wrap
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Occasion Filter
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 400 ? null : double.infinity,
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
                                  color: const Color(0xFF64FFDA).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
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

                    // Party Size Filter
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 400 ? null : double.infinity,
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
                                  color: const Color(0xFF64FFDA).withOpacity(0.3)),
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

                    // Time Preference Filter
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 400 ? null : double.infinity,
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
                                  color: const Color(0xFF64FFDA).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
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

          const SizedBox(height: 8),

          // Recommendations Grid
          _isLoadingRecommended
              ? const SizedBox(
                  height: 200,
                  child: Center(child: LoadingWidget()),
                )
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
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
                    )
                  : _recommendedTables.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.table_restaurant_outlined,
                                  color: Colors.grey, size: 48),
                              const SizedBox(height: 16),
                              const Text(
                                'No recommendations available',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _getRecommendations,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Responsive grid based on screen width
                              int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                              if (constraints.maxWidth > 900) crossAxisCount = 4;
                              if (constraints.maxWidth < 350) crossAxisCount = 1;

                              return GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
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
                              );
                            },
                          ),
                        ),

          const SizedBox(height: 20),
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
            // Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reserve Tables',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Find your perfect dining spot',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search and notification icons - hidden on small screens
                      if (MediaQuery.of(context).size.width > 350)
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
                            const SizedBox(width: 8),
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

                  const SizedBox(height: 20),

                  // Tab Selector
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                    size: 18,
                                    color: _tabController.index == 0
                                        ? const Color(0xFF0F172A)
                                        : Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'FOR YOU',
                                    style: TextStyle(
                                      color: _tabController.index == 0
                                          ? const Color(0xFF0F172A)
                                          : Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                    size: 18,
                                    color: _tabController.index == 1
                                        ? const Color(0xFF0F172A)
                                        : Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ALL TABLES',
                                    style: TextStyle(
                                      color: _tabController.index == 1
                                          ? const Color(0xFF0F172A)
                                          : Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
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

            // Tab Content
            Expanded(
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
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.table_restaurant_outlined,
                          color: Colors.grey, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'No tables available',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAllTables,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive grid based on screen width
                      int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                      if (constraints.maxWidth > 900) crossAxisCount = 4;
                      if (constraints.maxWidth < 350) crossAxisCount = 1;

                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _allTables.length,
                        itemBuilder: (context, index) {
                          final table = _allTables[index];
                          return _buildModernTableCard(table,
                              isRecommended: false);
                        },
                      );
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () => _handleTableTap(table),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF1E293B),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(Icons.table_restaurant,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),

                    // Recommendation badge
                    if (isRecommended)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _getRecommendationBadge(
                            table['recommendationReason']),
                      ),

                    // Status badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Favorite button
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _handleTableFavorite(table),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
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

              // Details Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Table name
                      Text(
                        table['tableName'] ?? 'Unknown Table',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Location and capacity
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF64FFDA),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              table['location'] ?? 'Main Hall',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64FFDA)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
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

                      // Rating and Reserve button
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF64FFDA),
                                  Color(0xFF4FD1C7)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Reserve',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Recommendation explanation
                      if (isRecommended && table['explanation'] != null)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              table['explanation'],
                              style: TextStyle(
                                color: const Color(0xFF64FFDA)
                                    .withOpacity(0.9),
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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

