import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../presentation/screens/bookings/room_booking_page.dart';
import '../../services/recommendation_service.dart';

class FeaturedRoomsSection extends StatefulWidget {
  const FeaturedRoomsSection({Key? key}) : super(key: key);

  @override
  State<FeaturedRoomsSection> createState() => _FeaturedRoomsSectionState();
}

class _FeaturedRoomsSectionState extends State<FeaturedRoomsSection> {
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;
  String? _error;
  String? _hoveredRoom;

  @override
  void initState() {
    super.initState();
    _loadFeaturedRooms();
  }

  Future<void> _loadFeaturedRooms() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check if user is logged in
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');

      List<Map<String, dynamic>> rooms = [];

      if (token != null && userId != null) {
        // Try to get personalized recommendations using RecommendationService
        try {
          final response = await RecommendationService.getRoomRecommendations(
            userId: userId,
            count: 3,
          );

          if (response['success'] == true) {
            final recommendations = response['recommendations'] ?? [];
            rooms = recommendations.map<Map<String, dynamic>>((item) {
              final room = item['roomDetails'] ?? item;
              return {
                '_id': room['_id'] ?? '',
                'roomNumber': room['roomNumber'] ?? '',
                'roomType': room['roomType'] ?? '',
                'price': room['price'] ?? 0,
                'image': room['image'] ?? '',
                'averageRating': room['averageRating'] ?? 4.5,
                'recommendationReason': item['reason'] ?? 'popularity',
              };
            }).toList();
          }
        } catch (e) {
          print('Error fetching recommendations: $e');
        }
      }

      // Fallback to popular rooms if no recommendations
      if (rooms.isEmpty) {
        try {
          final response =
              await RecommendationService.getPopularRooms(count: 3);

          if (response['success'] == true) {
            final popularRooms = response['popularRooms'] ?? [];
            rooms = popularRooms
                .map<Map<String, dynamic>>((room) => {
                      '_id': room['_id'] ?? '',
                      'roomNumber': room['roomNumber'] ?? '',
                      'roomType': room['roomType'] ?? '',
                      'price': room['price'] ?? 0,
                      'image': room['image'] ?? '',
                      'averageRating': room['averageRating'] ?? 4.5,
                      'recommendationReason': 'popularity',
                    })
                .toList();
          }
        } catch (e) {
          print('Error fetching popular rooms: $e');
        }
      }

      // Final fallback to all rooms
      if (rooms.isEmpty) {
        final response = await http.get(
          Uri.parse('http://localhost:8080/api/rooms'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is List) {
            rooms = data
                .take(3)
                .map<Map<String, dynamic>>((room) => {
                      '_id': room['_id'] ?? '',
                      'roomNumber': room['roomNumber'] ?? '',
                      'roomType': room['roomType'] ?? '',
                      'price': room['price'] ?? 0,
                      'image': room['image'] ?? '',
                      'averageRating': room['averageRating'] ?? 4.5,
                      'recommendationReason': 'featured',
                    })
                .toList();
          }
        }
      }

      setState(() {
        _rooms = rooms.take(3).toList(); // Ensure maximum 3 rooms
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading featured rooms: $e';
        _isLoading = false;
      });
    }
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'https://via.placeholder.com/300x200?text=Room';
    }
    if (imagePath.startsWith('http')) return imagePath;
    final cleanPath = imagePath.replaceAll(RegExp(r'^/+'), '');
    return cleanPath.contains('uploads')
        ? 'http://localhost:8080/$cleanPath'
        : 'http://localhost:8080/uploads/$cleanPath';
  }

  String _formatPrice(dynamic price) {
    final priceNum =
        price is String ? double.tryParse(price) ?? 0 : price.toDouble();
    return 'Rs ${priceNum.toStringAsFixed(0)}';
  }

  Widget _getRecommendationBadge(String? reason) {
    Map<String, Map<String, dynamic>> badges = {
      'collaborative_filtering': {
        'text': 'Similar Users',
        'color': Colors.green,
        'icon': Icons.favorite
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
    };

    final badge = badges[reason] ?? badges['popularity']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade400, Colors.pink.shade300],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.4),
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
            Color(0xFF112240),
            Color(0xFF0A192F),
            Color(0xFF112240),
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
                'Featured Rooms',
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
                    : _rooms.isEmpty
                        ? _buildEmptyState()
                        : _buildRoomsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 400,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFBB86FC)),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load rooms',
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeaturedRooms,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel_outlined, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No featured rooms available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsGrid() {
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
          itemCount: _rooms.length > 3 ? 3 : _rooms.length, // Limit to 3 rooms
          itemBuilder: (context, index) {
            final room = _rooms[index];
            return _buildRoomCard(room);
          },
        ),

        // View All Recommended Rooms Button
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoomBookingPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: const Color(0xFF64FFDA).withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'View All Recommended Rooms',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final isHovered = _hoveredRoom == room['_id'];

    return GestureDetector(
      onTap: () {
        // Navigate to room booking
        Navigator.pushNamed(context, '/room-booking', arguments: room);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredRoom = room['_id']),
        onExit: (_) => setState(() => _hoveredRoom = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHovered
                  ? [
                      const Color(0xFF64FFDA).withOpacity(0.12),
                      const Color(0xFFBB86FC).withOpacity(0.08),
                      const Color(0xFFFF6B9D).withOpacity(0.06),
                    ]
                  : [
                      const Color(0xFF112240).withOpacity(0.8),
                      const Color(0xFF1A2332).withOpacity(0.6),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovered
                  ? const Color(0xFF64FFDA).withOpacity(0.4)
                  : Colors.white.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHovered ? 0.4 : 0.3),
                blurRadius: isHovered ? 20 : 8,
                offset: Offset(0, isHovered ? 8 : 3),
              ),
            ],
          ),
          transform: Matrix4.identity()
            ..translate(0.0, isHovered ? -8.0 : 0.0)
            ..scale(isHovered ? 1.02 : 1.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Image Section
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      // Room Image
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(_getImageUrl(room['image'])),
                            fit: BoxFit.cover,
                            onError: (error, stackTrace) {
                              print('Error loading image: $error');
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
                      if (room['recommendationReason'] != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _getRecommendationBadge(
                              room['recommendationReason']),
                        ),

                      // Price Badge
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF64FFDA), Color(0xFFBB86FC)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF64FFDA).withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            _formatPrice(room['price']),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      // Rating Badge
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (room['averageRating'] ?? 4.5)
                                    .toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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
                        // Room Title
                        Text(
                          room['roomNumber'] ?? 'Luxury Room',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
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

                        // Room Type
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
                            room['roomType'] ?? 'Deluxe',
                            style: const TextStyle(
                              color: Color(0xFFBB86FC),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Features
                        Row(
                          children: [
                            _buildFeatureIcon(Icons.wifi, 'WiFi'),
                            const SizedBox(width: 8),
                            _buildFeatureIcon(Icons.coffee, 'Coffee'),
                            const SizedBox(width: 8),
                            _buildFeatureIcon(Icons.tv, 'TV'),
                          ],
                        ),
                        const Spacer(),

                        // Book Button
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/room-booking',
                                  arguments: room);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'BOOK NOW',
                              style: TextStyle(
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}
