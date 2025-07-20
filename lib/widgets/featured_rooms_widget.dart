import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/recommendation_service.dart';
import '../services/auth_service.dart';
import '../models/room_model.dart';
import '../data/models/room_model.dart' as data_room;
import '../presentation/screens/booking/room_booking_screen.dart';

class FeaturedRoomsWidget extends StatefulWidget {
  const FeaturedRoomsWidget({Key? key}) : super(key: key);

  @override
  State<FeaturedRoomsWidget> createState() => _FeaturedRoomsWidgetState();
}

class _FeaturedRoomsWidgetState extends State<FeaturedRoomsWidget> {
  List<Room> _rooms = [];
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

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final response = await RecommendationService.getRoomRecommendations(
        userId: userId,
        count: 3, // Show only 3 rooms like website
      );

      if (response['success'] == true) {
        final List<dynamic> roomsData = response['recommendations'] ??
            response['popularRooms'] ??
            response['rooms'] ??
            [];

        setState(() {
          _rooms = roomsData.map((data) => Room.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load featured rooms';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading featured rooms: $e';
        _isLoading = false;
      });
    }
  }

  String _getRecommendationBadge(String? reason) {
    switch (reason) {
      case 'collaborative_filtering':
        return 'Similar Users';
      case 'content_based':
        return 'Your Taste';
      case 'popularity':
        return 'Trending';
      default:
        return 'Featured';
    }
  }

  Color _getBadgeColor(String? reason) {
    switch (reason) {
      case 'collaborative_filtering':
        return Colors.green;
      case 'content_based':
        return Colors.blue;
      case 'popularity':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: const Text(
                'Featured Rooms',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Content
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_rooms.isEmpty)
            _buildEmptyState()
          else
            _buildRoomsGrid(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 300,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load rooms',
              style: TextStyle(color: Colors.red[700]),
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
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          return Container(
            width: 280,
            margin: EdgeInsets.only(right: index < _rooms.length - 1 ? 16 : 0),
            child: _buildRoomCard(room),
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    return GestureDetector(
      onTap: () {
        // Record interaction
        RecommendationService.recordRoomInteraction(
          roomId: room.id,
          interactionType: 'view',
        );

        // Navigate to room booking
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RoomBookingScreen(room: _convertToRoomModel(room)),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E293B),
              const Color(0xFF334155),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Room Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: room.image != null
                  ? Image.network(
                      room.image!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.hotel,
                              size: 64, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child:
                          const Icon(Icons.hotel, size: 64, color: Colors.grey),
                    ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
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

            // Recommendation Badge
            if (room.recommendationReason != null)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getBadgeColor(room.recommendationReason),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _getRecommendationBadge(room.recommendationReason),
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

            // Price Badge
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Rs ${room.price}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Room Details
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.roomNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.roomType,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFeatureIcon(Icons.wifi, 'Free WiFi'),
                        const SizedBox(width: 16),
                        _buildFeatureIcon(Icons.coffee, 'Coffee'),
                        const SizedBox(width: 16),
                        _buildFeatureIcon(Icons.tv, 'Smart TV'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to booking
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomBookingScreen(
                                  room: _convertToRoomModel(room)),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'BOOK NOW',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  data_room.RoomModel _convertToRoomModel(Room room) {
    return data_room.RoomModel(
      id: room.id,
      roomNumber: room.roomNumber,
      roomType: room.roomType,
      pricePerNight: room.price,
      capacity: 2, // Default capacity
      amenities: ['Wi-Fi', 'TV', 'Air Conditioning'], // Default amenities
      imageUrls: room.image != null ? [room.image!] : [],
      status: room.status,
      description: room.description,
      floor: 1, // Default floor
      isAvailable: room.status == 'Available',
      size: 'Standard',
    );
  }
}
