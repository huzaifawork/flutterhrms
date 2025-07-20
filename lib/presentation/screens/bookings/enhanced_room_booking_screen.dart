import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../data/models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import '../booking/room_booking_screen.dart';

class EnhancedRoomBookingScreen extends StatefulWidget {
  const EnhancedRoomBookingScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedRoomBookingScreen> createState() =>
      _EnhancedRoomBookingScreenState();
}

class _EnhancedRoomBookingScreenState extends State<EnhancedRoomBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _recommendedRooms = [];
  List<Map<String, dynamic>> _allRooms = [];
  bool _isLoadingRecommended = true;
  bool _isLoadingAll = true;
  String? _error;

  // Customization filters
  String _selectedOccasion = 'Any Occasion';
  int _groupSize = 2;
  String _budgetRange = 'Any Budget';

  final List<String> _occasions = [
    'Any Occasion',
    'Business',
    'Vacation',
    'Family Trip',
    'Romantic Getaway',
    'Weekend Break',
    'Conference'
  ];

  final List<String> _budgetRanges = [
    'Any Budget',
    'Budget (Under Rs 5000)',
    'Mid-range (Rs 5000-10000)',
    'Premium (Rs 10000-20000)',
    'Luxury (Above Rs 20000)'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecommendedRooms();
    _loadAllRooms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendedRooms() async {
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
              'http://localhost:8080/api/rooms/recommendations/$userId?numRecommendations=6&occasion=${_selectedOccasion.toLowerCase()}&groupSize=$_groupSize'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final recommendations = data['recommendations'] ?? [];
            setState(() {
              _recommendedRooms =
                  recommendations.map<Map<String, dynamic>>((item) {
                final room = item['room'] ?? item;
                return {
                  '_id': room['_id'] ?? '',
                  'roomNumber': room['roomNumber'] ?? '',
                  'roomType': room['roomType'] ?? '',
                  'description': room['description'] ?? '',
                  'price': room['price'] ?? 0,
                  'status': room['status'] ?? 'Available',
                  'image': room['image'] ?? '',
                  'averageRating': room['averageRating'] ?? 4.5,
                  'capacity': room['capacity'] ?? 2,
                  'amenities': room['amenities'] ?? [],
                  'floor': room['floor'] ?? 1,
                  'size': room['size'] ?? 300,
                  'bedType': room['bedType'] ?? 'Double',
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
        // Fallback to popular rooms for non-logged-in users
        await _loadPopularRooms();
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading recommendations: $e';
        _isLoadingRecommended = false;
      });
    }
  }

  Future<void> _loadPopularRooms() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/rooms/popular?count=6'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final popularRooms = data['popularRooms'] ?? [];
          setState(() {
            _recommendedRooms = popularRooms
                .map<Map<String, dynamic>>((room) => {
                      '_id': room['_id'] ?? '',
                      'roomNumber': room['roomNumber'] ?? '',
                      'roomType': room['roomType'] ?? '',
                      'description': room['description'] ?? '',
                      'price': room['price'] ?? 0,
                      'status': room['status'] ?? 'Available',
                      'image': room['image'] ?? '',
                      'averageRating': room['averageRating'] ?? 4.5,
                      'capacity': room['capacity'] ?? 2,
                      'amenities': room['amenities'] ?? [],
                      'floor': room['floor'] ?? 1,
                      'size': room['size'] ?? 300,
                      'bedType': room['bedType'] ?? 'Double',
                      'recommendationReason': 'popularity',
                      'score': 0.9,
                      'explanation': 'Popular room with high ratings',
                    })
                .toList();
            _isLoadingRecommended = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading popular rooms: $e';
        _isLoadingRecommended = false;
      });
    }
  }

  Future<void> _loadAllRooms() async {
    try {
      setState(() {
        _isLoadingAll = true;
      });

      final response = await http.get(
        Uri.parse('http://localhost:8080/api/rooms'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            _allRooms = data
                .map<Map<String, dynamic>>((room) => {
                      '_id': room['_id'] ?? '',
                      'roomNumber': room['roomNumber'] ?? '',
                      'roomType': room['roomType'] ?? '',
                      'description': room['description'] ?? '',
                      'price': room['price'] ?? 0,
                      'status': room['status'] ?? 'Available',
                      'image': room['image'] ?? '',
                      'averageRating': room['averageRating'] ?? 4.5,
                      'capacity': room['capacity'] ?? 2,
                      'amenities': room['amenities'] ?? [],
                      'floor': room['floor'] ?? 1,
                      'size': room['size'] ?? 300,
                      'bedType': room['bedType'] ?? 'Double',
                    })
                .toList();
            _isLoadingAll = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading rooms: $e';
        _isLoadingAll = false;
      });
    }
  }

  Future<void> _getRecommendations() async {
    await _loadRecommendedRooms();
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
    return 'Rs ${priceNum.toStringAsFixed(0)}/night';
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      appBar: AppBar(
        title: const Text(
          'Book a Room',
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
                    'Find your perfect stay',
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
                            Icon(Icons.hotel, size: 16),
                            SizedBox(width: 8),
                            Text('ALL ROOMS'),
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

                      // Group Size
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Group Size',
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
                                  onPressed: _groupSize > 1
                                      ? () {
                                          setState(() {
                                            _groupSize--;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.remove, size: 16),
                                  color: Colors.white,
                                  constraints: const BoxConstraints(
                                      minWidth: 24, minHeight: 24),
                                ),
                                Text(
                                  '$_groupSize',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                ),
                                IconButton(
                                  onPressed: _groupSize < 10
                                      ? () {
                                          setState(() {
                                            _groupSize++;
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
                // Recommended Rooms Tab
                _buildRecommendedRoomsView(),

                // All Rooms Tab
                _buildAllRoomsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedRoomsView() {
    if (_isLoadingRecommended) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFBB86FC)),
            SizedBox(height: 16),
            Text(
              'Finding perfect rooms for you...',
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
              onPressed: _loadRecommendedRooms,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_recommendedRooms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel_outlined, color: Colors.grey, size: 48),
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
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _recommendedRooms.length,
        itemBuilder: (context, index) {
          final room = _recommendedRooms[index];
          return _buildRoomCard(room, isRecommended: true);
        },
      ),
    );
  }

  Widget _buildAllRoomsView() {
    if (_isLoadingAll) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFBB86FC)),
            SizedBox(height: 16),
            Text(
              'Loading all rooms...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_allRooms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel_outlined, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No rooms available',
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
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _allRooms.length,
        itemBuilder: (context, index) {
          final room = _allRooms[index];
          return _buildRoomCard(room, isRecommended: false);
        },
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room,
      {required bool isRecommended}) {
    return GestureDetector(
      onTap: () {
        // Convert to RoomModel and navigate to booking screen
        final roomModel = RoomModel(
          id: room['_id'],
          roomNumber: room['roomNumber'] ?? 'Unknown',
          roomType: room['roomType'] ?? 'Standard',
          description: room['description'] ?? '',
          pricePerNight: room['price'].toDouble(),
          capacity: room['capacity'] ?? 2,
          amenities: List<String>.from(room['amenities'] ?? []),
          imageUrls: [_getImageUrl(room['image'])],
          status: room['status'] ?? 'Available',
          floor: room['floor'] ?? 1,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomBookingScreen(room: roomModel),
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
                    // Room Image
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(_getImageUrl(room['image'])),
                          fit: BoxFit.cover,
                          onError: (error, stackTrace) {
                            print('Error loading room image: $error');
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
                    if (isRecommended && room['recommendationReason'] != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _getRecommendationBadge(
                            room['recommendationReason']),
                      ),

                    // Status Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: room['status'] == 'Available'
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          room['status'] ?? 'Available',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Price Badge
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBB86FC).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatPrice(room['price']),
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
                              (room['averageRating'] ?? 4.5).toStringAsFixed(1),
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
                      // Room Title
                      Text(
                        'Room ${room['roomNumber']}',
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

                      // Room Type
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBB86FC).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          room['roomType'] ?? 'Standard',
                          style: const TextStyle(
                            color: Color(0xFFBB86FC),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Room Info
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${room['capacity']} guests',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.bed,
                            size: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              room['bedType'] ?? 'Double',
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
                      const Spacer(),

                      // Book Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: room['status'] == 'Available'
                              ? () {
                                  final roomModel = RoomModel(
                                    id: room['_id'],
                                    roomNumber: room['roomNumber'] ?? 'Unknown',
                                    roomType: room['roomType'] ?? 'Standard',
                                    description: room['description'] ?? '',
                                    pricePerNight: room['price'].toDouble(),
                                    capacity: room['capacity'] ?? 2,
                                    amenities: List<String>.from(
                                        room['amenities'] ?? []),
                                    imageUrls: [_getImageUrl(room['image'])],
                                    status: room['status'] ?? 'Available',
                                    floor: room['floor'] ?? 1,
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RoomBookingScreen(room: roomModel),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: room['status'] == 'Available'
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
                            room['status'] == 'Available'
                                ? 'Book Now'
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
