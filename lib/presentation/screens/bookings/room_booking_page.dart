import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/environment.dart';
import '../../../services/recommendation_service.dart';
import '../../../data/models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import '../booking/room_booking_screen.dart';

class RoomBookingPage extends StatefulWidget {
  const RoomBookingPage({Key? key}) : super(key: key);

  @override
  State<RoomBookingPage> createState() => _RoomBookingPageState();
}

class _RoomBookingPageState extends State<RoomBookingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _recommendedRooms = [];
  List<Map<String, dynamic>> _popularRooms = [];
  List<Map<String, dynamic>> _allRooms = [];
  bool _isLoadingRecommended = true;
  bool _isLoadingPopular = true;
  bool _isLoadingAll = true;
  String? _error;

  // Advanced filters
  String _selectedOccasion = 'Any Occasion';
  int _groupSize = 2;
  String _budgetRange = 'Any Budget';
  String _roomType = 'Any Type';
  List<String> _selectedAmenities = [];
  bool _filtersExpanded = false;

  final List<String> _occasions = [
    'Any Occasion',
    'Business',
    'Meeting',
    'Conference',
    'Training',
    'Event',
    'Private'
  ];

  final List<String> _budgetRanges = [
    'Any Budget',
    'Under Rs. 5,000',
    'Rs. 5,000 - Rs. 10,000',
    'Rs. 10,000 - Rs. 20,000',
    'Above Rs. 20,000'
  ];

  final List<String> _roomTypes = [
    'Any Type',
    'Conference Room',
    'Meeting Room',
    'Training Room',
    'Event Hall',
    'Private Office'
  ];

  final List<String> _amenities = [
    'WiFi',
    'Projector',
    'Whiteboard',
    'Audio System',
    'Video Conferencing',
    'Air Conditioning',
    'Parking',
    'Catering'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadRecommendedRooms(),
      _loadPopularRooms(),
      _loadAllRooms(),
    ]);
  }

  Future<void> _loadRecommendedRooms() async {
    try {
      setState(() {
        _isLoadingRecommended = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        final response = await http.get(
          Uri.parse(
              '${Environment.currentApiUrl}/api/rooms/recommendations/$userId?count=6'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final recommendations = data['recommendations'] ?? [];
            setState(() {
              _recommendedRooms =
                  recommendations.map<Map<String, dynamic>>((item) {
                final room = item['roomDetails'] ?? item;
                return _mapRoomData(room, isRecommended: true);
              }).toList();
            });
            return;
          }
        }
      }

      await _loadPopularRooms();
      setState(() {
        _recommendedRooms = _popularRooms;
      });
    } catch (e) {
      print('Error loading recommended rooms: $e');
      await _loadPopularRooms();
      setState(() {
        _recommendedRooms = _popularRooms;
      });
    } finally {
      setState(() {
        _isLoadingRecommended = false;
      });
    }
  }

  Future<void> _loadPopularRooms() async {
    try {
      setState(() {
        _isLoadingPopular = true;
      });

      final response = await http.get(
        Uri.parse('${Environment.currentApiUrl}/api/rooms/popular?count=6'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final rooms = data['popularRooms'] ?? [];
          setState(() {
            _popularRooms = rooms
                .map<Map<String, dynamic>>((room) => _mapRoomData(room))
                .toList();
          });
        }
      } else {
        await _loadAllRoomsFromAPI();
        setState(() {
          _popularRooms = _allRooms.take(6).toList();
        });
      }
    } catch (e) {
      print('Error loading popular rooms: $e');
      await _loadAllRoomsFromAPI();
      setState(() {
        _popularRooms = _allRooms.take(6).toList();
      });
    } finally {
      setState(() {
        _isLoadingPopular = false;
      });
    }
  }

  Future<void> _loadAllRooms() async {
    try {
      setState(() {
        _isLoadingAll = true;
      });

      await _loadAllRoomsFromAPI();
    } catch (e) {
      print('Error loading all rooms: $e');
    } finally {
      setState(() {
        _isLoadingAll = false;
      });
    }
  }

  Future<void> _getRecommendations() async {
    await _loadRecommendedRooms();
  }

  Map<String, dynamic> _mapRoomData(Map<String, dynamic> room,
      {bool isRecommended = false}) {
    return {
      '_id': room['_id'] ?? '',
      'roomName': room['roomNumber'] ?? room['roomName'] ?? 'Unknown Room',
      'capacity': room['capacity'] ?? 2,
      'pricePerHour': room['price'] ?? room['pricePerHour'] ?? 0,
      'image': room['image'] ?? '',
      'status': room['status'] ?? 'Available',
      'avgRating': room['averageRating'] ?? room['avgRating'] ?? 4.5,
      'amenities': room['amenities'] ?? [],
      'description': room['description'] ?? '',
      'roomType': room['roomType'] ?? 'Conference Room',
      if (isRecommended) ...{
        'recommendationReason': room['reason'] ?? 'recommended',
        'explanation': room['explanation'] ?? 'Recommended for you',
        'rank': room['rank'] ?? 1,
        'score': room['score'] ?? 0.8,
      }
    };
  }

  Future<void> _loadAllRoomsFromAPI() async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.currentApiUrl}/api/rooms'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _allRooms = data
              .map<Map<String, dynamic>>((room) => _mapRoomData(room))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading all rooms from API: $e');
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

  Future<void> _recordInteraction(String roomId, String interactionType) async {
    try {
      await RecommendationService.recordRoomInteraction(
        roomId: roomId,
        interactionType: interactionType,
        context: {
          'occasion': _selectedOccasion,
          'groupSize': _groupSize,
          'budgetRange': _budgetRange,
        },
      );
    } catch (e) {
      print('Error recording interaction: $e');
    }
  }

  void _handleRoomTap(Map<String, dynamic> room) async {
    await _recordInteraction(room['_id'], 'view');

    if (!mounted) return;

    final roomModel = RoomModel(
      id: room['_id'],
      roomNumber: room['roomName'] ?? 'Unknown Room',
      roomType: 'Conference Room',
      capacity: room['capacity'],
      pricePerNight: (room['pricePerHour'] ?? 0).toDouble(),
      imageUrls: [_getImageUrl(room['image'])],
      amenities: List<String>.from(room['amenities'] ?? []),
      status: room['status'] ?? 'Available',
      floor: 1,
      description: room['description'],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomBookingScreen(room: roomModel),
      ),
    );
  }

  void _handleRoomFavorite(Map<String, dynamic> room) async {
    await _recordInteraction(room['_id'], 'favorite');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${room['roomName']} added to favorites!'),
        backgroundColor: Colors.pink,
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A192F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Hero Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFF64FFDA)],
                  ).createShader(bounds),
                  child: const Text(
                    'Find your perfect meeting space',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Tab Navigation
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive tab sizing
                final isSmall = constraints.maxWidth < 400;
                return Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                          0,
                          isSmall ? '💝' : '💝 RECOMMENDED',
                          const Color(0xFF64FFDA)),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTabButton(1, isSmall ? '🔥' : '🔥 POPULAR',
                          const Color(0xFFFF6B6B)),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildTabButton(2, isSmall ? '🏢' : '🏢 ALL ROOMS',
                          const Color(0xFFBB86FC)),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendedRoomsView(),
                _buildPopularRoomsView(),
                _buildAllRoomsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String text, Color color) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF0A192F)
                  : Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedRoomsView() {
    return Column(
      children: [
        // Advanced Filters
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Collapsible header
              GestureDetector(
                onTap: () {
                  setState(() {
                    _filtersExpanded = !_filtersExpanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🎯 Advanced Filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      _filtersExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),

              // Expandable content
              if (_filtersExpanded) ...[
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 350;
                    return Column(
                      children: [
                        // First Row: Occasion and Group Size
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactFilterDropdown(
                                isSmall ? '🎉' : '🎉 Occasion',
                                _selectedOccasion,
                                _occasions,
                                (value) =>
                                    setState(() => _selectedOccasion = value!),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildCompactFilterInput(
                                isSmall ? '👥' : '👥 Size',
                                _groupSize.toString(),
                                (value) => setState(() =>
                                    _groupSize = int.tryParse(value) ?? 2),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Second Row: Budget and Room Type
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactFilterDropdown(
                                isSmall ? '💰' : '💰 Budget',
                                _budgetRange,
                                _budgetRanges,
                                (value) =>
                                    setState(() => _budgetRange = value!),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildCompactFilterDropdown(
                                isSmall ? '🏢' : '🏢 Type',
                                _roomType,
                                _roomTypes,
                                (value) => setState(() => _roomType = value!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 6),

                // Amenities Filter
                SizedBox(
                  height: 28,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _amenities.map((amenity) {
                        final isSelected = _selectedAmenities.contains(amenity);
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedAmenities.remove(amenity);
                                } else {
                                  _selectedAmenities.add(amenity);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF64FFDA).withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF64FFDA)
                                      : Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                amenity,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF64FFDA)
                                      : Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Get Recommendations Button
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: _getRecommendations,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64FFDA),
                      foregroundColor: const Color(0xFF0A192F),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const FittedBox(
                      child: Text(
                        'Get Recommendations',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Recommendations Grid
        Expanded(
          child: _buildRoomsGrid(_recommendedRooms, _isLoadingRecommended,
              isRecommended: true),
        ),
      ],
    );
  }

  Widget _buildPopularRoomsView() {
    return _buildRoomsGrid(_popularRooms, _isLoadingPopular);
  }

  Widget _buildAllRoomsView() {
    return _buildRoomsGrid(_allRooms, _isLoadingAll);
  }

  Widget _buildCompactFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0A192F),
            border: Border.all(color: const Color(0xFF64FFDA).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              dropdownColor: const Color(0xFF0A192F),
              style: const TextStyle(color: Colors.white, fontSize: 10),
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFilterInput(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0A192F),
            border: Border.all(color: const Color(0xFF64FFDA).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextFormField(
            initialValue: value,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 10),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsGrid(List<Map<String, dynamic>> rooms, bool isLoading,
      {bool isRecommended = false}) {
    if (isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (rooms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room_outlined, color: Colors.grey, size: 48),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive grid based on screen width
          int crossAxisCount = constraints.maxWidth > 600
              ? 3
              : constraints.maxWidth > 400
                  ? 2
                  : 1;

          double childAspectRatio = constraints.maxWidth > 600
              ? 0.75
              : constraints.maxWidth > 400
                  ? 0.7
                  : 0.8;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _buildRoomCard(room, isRecommended: isRecommended);
            },
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room,
      {bool isRecommended = false}) {
    final imageUrl = _getImageUrl(room['image']);
    final rating = (room['avgRating'] ?? 4.5).toDouble();
    final status = room['status'] ?? 'Available';
    final isAvailable = status.toLowerCase() == 'available';
    final pricePerHour = (room['pricePerHour'] ?? 0).toDouble();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF172A45),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleRoomTap(room),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image and badges
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Room image
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),

                  // Recommendation badge (only for recommended rooms)
                  if (isRecommended)
                    Positioned(
                      top: 8,
                      left: 8,
                      child:
                          _getRecommendationBadge(room['recommendationReason']),
                    ),

                  // Status badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAvailable ? Colors.green : Colors.red,
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
                      onTap: () => _handleRoomFavorite(room),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
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

            // Room details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 150;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room name
                        Text(
                          room['roomName'] ?? 'Unknown Room',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmall ? 12 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Capacity and price
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: Colors.grey[400],
                              size: isSmall ? 10 : 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${room['capacity'] ?? 2} people',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: isSmall ? 10 : 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Rs. ${pricePerHour.toStringAsFixed(0)}/hr',
                              style: TextStyle(
                                color: const Color(0xFF64FFDA),
                                fontSize: isSmall ? 10 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Rating
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < rating.floor()
                                    ? Icons.star
                                    : index < rating
                                        ? Icons.star_half
                                        : Icons.star_border,
                                color: Colors.amber,
                                size: isSmall ? 10 : 12,
                              );
                            }),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: isSmall ? 8 : 10,
                              ),
                            ),
                          ],
                        ),

                        // Amenities (show first 3)
                        if (room['amenities'] != null &&
                            room['amenities'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: (room['amenities'] as List)
                                  .take(3)
                                  .map<Widget>((amenity) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF64FFDA)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    amenity.toString(),
                                    style: TextStyle(
                                      color: const Color(0xFF64FFDA),
                                      fontSize: isSmall ? 7 : 8,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        // Recommendation explanation
                        if (isRecommended && room['explanation'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              room['explanation'],
                              style: TextStyle(
                                color: const Color(0xFF64FFDA).withOpacity(0.8),
                                fontSize: isSmall ? 8 : 9,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
