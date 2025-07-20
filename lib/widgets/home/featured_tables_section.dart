import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../presentation/screens/reservations/table_reservation_page.dart';
import '../../services/recommendation_service.dart';

class FeaturedTablesSection extends StatefulWidget {
  const FeaturedTablesSection({Key? key}) : super(key: key);

  @override
  State<FeaturedTablesSection> createState() => _FeaturedTablesSectionState();
}

class _FeaturedTablesSectionState extends State<FeaturedTablesSection> {
  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = true;
  String? _error;
  String? _hoveredTable;

  @override
  void initState() {
    super.initState();
    _loadFeaturedTables();
  }

  Future<void> _loadFeaturedTables() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      // Use the same RecommendationService as the Tables page for consistency
      final response = await RecommendationService.getTableRecommendations(
        userId: userId,
        occasion: 'casual',
        partySize: 2,
        timeSlot: 'evening',
        numRecommendations: 3, // Show only 3 tables like website
      );

      List<Map<String, dynamic>> tables = [];

      if (response['success'] == true) {
        final recommendations = response['recommendations'] ??
            response['popularTables'] ??
            response['tables'] ??
            [];

        tables = recommendations.take(3).map<Map<String, dynamic>>((item) {
          // Handle both recommendation format and direct table format
          final table = item['table'] ?? item;
          final reason =
              item['reason'] ?? item['recommendationReason'] ?? 'featured';

          return {
            '_id': table['_id'] ?? '',
            'tableName': table['tableName'] ?? '',
            'tableType': table['tableType'] ?? '',
            'capacity': table['capacity'] ?? 0,
            'status': table['status'] ?? 'Available',
            'location': table['location'] ?? '',
            'image': table['image'] ?? '',
            'avgRating': table['avgRating'] ?? 4.5,
            'recommendationReason': reason,
          };
        }).toList();
      }

      // Ensure we only have exactly 3 tables
      if (tables.length > 3) {
        tables = tables.take(3).toList();
      }

      setState(() {
        _tables = tables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading featured tables: $e';
        _isLoading = false;
      });
    }
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

    // Use the same badge logic as the Tables page for consistency
    String badgeText;
    Color badgeColor;
    IconData badgeIcon;

    switch (reason) {
      case 'collaborative_filtering':
        badgeText = 'Similar Users';
        badgeColor = Colors.green;
        badgeIcon = Icons.people;
        break;
      case 'content_based':
        badgeText = 'Your Taste';
        badgeColor = Colors.blue;
        badgeIcon = Icons.favorite;
        break;
      case 'popularity':
        badgeText = 'Trending';
        badgeColor = Colors.orange;
        badgeIcon = Icons.trending_up;
        break;
      case 'contextual':
        badgeText = 'AI Pick';
        badgeColor = Colors.pink;
        badgeIcon = Icons.psychology;
        break;
      default:
        badgeText = 'Featured';
        badgeColor = Colors.indigo;
        badgeIcon = Icons.star;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [badgeColor, badgeColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            badgeText,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A192F),
            Color(0xFF112240),
            Color(0xFF0A192F),
          ],
        ),
      ),
      child: Column(
        children: [
          // Section Title
          Container(
            margin: const EdgeInsets.only(bottom: 32),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Color(0xFFBB86FC)],
              ).createShader(bounds),
              child: const Text(
                'Featured Tables',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Content
          Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _tables.isEmpty
                        ? _buildEmptyState()
                        : _buildTablesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 280,
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 8,
                right: index == 2 ? 0 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFBB86FC)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load tables',
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeaturedTables,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant_outlined, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No featured tables available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablesGrid() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount:
              _tables.length > 3 ? 3 : _tables.length, // Limit to 3 tables
          itemBuilder: (context, index) {
            final table = _tables[index];
            return _buildTableCard(table);
          },
        ),

        // View All Button
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          child: ElevatedButton(
            onPressed: () {
              // Navigate to Tables page and ensure it opens on the Recommendations tab
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TableReservationPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB86FC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: const Color(0xFFBB86FC).withValues(alpha: 0.4),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.psychology, size: 20),
                SizedBox(width: 12),
                Text(
                  'View All Recommended Tables',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    final isHovered = _hoveredTable == table['_id'];

    return GestureDetector(
      onTap: () {
        // Navigate to table reservation
        Navigator.pushNamed(context, '/reserve-table', arguments: table);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredTable = table['_id']),
        onExit: (_) => setState(() => _hoveredTable = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHovered
                  ? [
                      const Color(0xFFBB86FC).withOpacity(0.08),
                      const Color(0xFFFF6B9D).withOpacity(0.04),
                    ]
                  : [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.02),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? const Color(0xFFBB86FC).withOpacity(0.5)
                  : Colors.white.withOpacity(0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHovered ? 0.3 : 0.2),
                blurRadius: isHovered ? 10 : 4,
                offset: Offset(0, isHovered ? 5 : 2),
              ),
            ],
          ),
          transform: Matrix4.identity()..translate(0.0, isHovered ? -5.0 : 0.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                // Image Section
                Expanded(
                  flex: 2,
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
                      if (table['recommendationReason'] != null)
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
                            gradient: const LinearGradient(
                              colors: [Color(0xFF64FFDA), Color(0xFFBB86FC)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF64FFDA).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            table['status'] ?? 'Available',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
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
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 10,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                (table['avgRating'] ?? 4.5).toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
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
                            fontWeight: FontWeight.w700,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [Colors.white, Color(0xFFBB86FC)],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Table Type
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFBB86FC).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFBB86FC)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            table['tableType'] ?? 'Premium',
                            style: const TextStyle(
                              color: Color(0xFFBB86FC),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Features
                        Row(
                          children: [
                            _buildFeatureIcon(
                                Icons.people, '${table['capacity']} Seats'),
                            const SizedBox(width: 4),
                            _buildFeatureIcon(Icons.location_on,
                                table['location'] ?? 'Premium'),
                            const SizedBox(width: 4),
                            _buildFeatureIcon(Icons.access_time, 'Cozy'),
                          ],
                        ),
                        const Spacer(),

                        // Reserve Button
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            onPressed: table['status'] == 'Available'
                                ? () {
                                    Navigator.pushNamed(
                                        context, '/reserve-table',
                                        arguments: table);
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
                                  ? 'RESERVE'
                                  : 'UNAVAILABLE',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 8,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
