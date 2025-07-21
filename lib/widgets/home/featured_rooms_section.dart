import 'package:flutter/material.dart';
import 'package:hrms_mobile_app/core/config/environment.dart';
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
          Uri.parse('${Environment.currentApiUrl}/api/rooms'),
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
        ? '${Environment.currentApiUrl}/$cleanPath'
        : '${Environment.currentApiUrl}/uploads/$cleanPath';
  }

  String _formatPrice(dynamic price) {
    final priceNum =
        price is String ? double.tryParse(price) ?? 0 : price.toDouble();
    return 'Rs ${priceNum.toStringAsFixed(0)}';
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
            padding: const EdgeInsets.symmetric(
                horizontal: 12), // Reduced padding for mobile
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
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        double childAspectRatio = 1;

        if (constraints.maxWidth >= 600) {
          crossAxisCount = 2;
          childAspectRatio = 0.85;
        }
        if (constraints.maxWidth >= 900) {
          crossAxisCount = 3;
          childAspectRatio = 0.9;
        }

        return Column(
          children: [
            GridView.builder(
              itemCount: _rooms.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                return _buildRoomCard(_rooms[index]);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
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
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.hotel),
              label: const Text(
                'View All Recommended Rooms',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/room-booking', arguments: room);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  _getImageUrl(room['image']),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room['roomNumber'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room['roomType'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        (room['averageRating'] ?? 4.5).toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        _formatPrice(room['price']),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
