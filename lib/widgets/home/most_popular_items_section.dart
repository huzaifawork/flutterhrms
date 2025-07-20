import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/recommendation_service.dart';
import '../../presentation/screens/orders/menu_ordering_page.dart';
import '../../core/config/environment.dart';

class MostPopularItemsSection extends StatefulWidget {
  const MostPopularItemsSection({Key? key}) : super(key: key);

  @override
  State<MostPopularItemsSection> createState() =>
      _MostPopularItemsSectionState();
}

class _MostPopularItemsSectionState extends State<MostPopularItemsSection> {
  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPopularItems();
  }

  Future<void> _loadPopularItems() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Use RecommendationService to get popular food items
      final response =
          await RecommendationService.getPopularFoodItems(count: 3);

      if (response['success'] == true) {
        final popularItems = response['popularItems'] ?? [];
        final topItems = popularItems.map<Map<String, dynamic>>((item) {
          final menuItem = item['menuItem'] ?? item;
          return {
            '_id': menuItem['_id'] ?? '',
            'name': menuItem['name'] ?? '',
            'category': menuItem['category'] ?? '',
            'price': menuItem['price'] ?? 0,
            'image': menuItem['image'] ?? '',
            'rating': menuItem['averageRating'] ?? menuItem['rating'] ?? 4.5,
            'description': menuItem['description'] ?? '',
          };
        }).toList();

        setState(() {
          _menuItems = topItems.take(3).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load popular items');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading popular items: $e';
        _isLoading = false;
      });
    }
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'https://via.placeholder.com/300x200?text=Food';
    }
    if (imagePath.startsWith('http')) return imagePath;
    final cleanPath = imagePath.replaceAll(RegExp(r'^/+'), '');
    final baseUrl = Environment.currentApiUrl;
    return cleanPath.contains('uploads')
        ? '$baseUrl/$cleanPath'
        : '$baseUrl/uploads/$cleanPath';
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
                'Most Popular Items',
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
                    : _menuItems.isEmpty
                        ? _buildEmptyState()
                        : _buildItemsGrid(),
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
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
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
              _error ?? 'Failed to load menu items',
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPopularItems,
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
            Icon(Icons.restaurant_menu_outlined, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No popular items available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsGrid() {
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
          itemCount: _menuItems.length,
          itemBuilder: (context, index) {
            final item = _menuItems[index];
            return _buildItemCard(item);
          },
        ),

        // View All Menus Button
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          child: ElevatedButton(
            onPressed: () {
              // Navigate to the menu ordering page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MenuOrderingPage(),
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
                const Icon(Icons.restaurant_menu, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'View All Menus',
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

  Widget _buildItemCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        // Navigate to order food
        Navigator.pushNamed(context, '/order-food', arguments: item);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Image Section
              Expanded(
                flex: 2,
                child: Stack(
                  children: [
                    // Food Image
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(_getImageUrl(item['image'])),
                          fit: BoxFit.cover,
                          onError: (error, stackTrace) {
                            print('Error loading food image: $error');
                          },
                        ),
                      ),
                    ),

                    // Rating Badge
                    Positioned(
                      top: 8,
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
                              size: 10,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              (item['rating'] ?? 4.5).toStringAsFixed(1),
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

                    // Price Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBB86FC).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatPrice(item['price']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
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
                      // Item Title
                      Text(
                        item['name'] ?? 'Menu Item',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Colors.white, Color(0xFFBB86FC)],
                            ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBB86FC).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                const Color(0xFFBB86FC).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          item['category'] ?? 'Delicious',
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
                          _buildFeatureIcon(Icons.access_time, '15 min'),
                          const SizedBox(width: 4),
                          _buildFeatureIcon(
                              Icons.local_fire_department, 'Spicy'),
                          const SizedBox(width: 4),
                          _buildFeatureIcon(Icons.favorite, 'Popular'),
                        ],
                      ),
                      const Spacer(),

                      // Order Button
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/order-food',
                                arguments: item);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFBB86FC).withValues(alpha: 0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'ORDER NOW',
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
