import 'package:flutter/material.dart';
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
    return SingleChildScrollView(
      child: Container(
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
            ShaderMask(
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
              ),
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : _menuItems.isEmpty
                          ? _buildEmptyState()
                          : _buildItemsGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
        const SizedBox(height: 8),
        Text(
          _error ?? 'Failed to load menu items',
          style: TextStyle(color: Colors.red.shade700),
          textAlign: TextAlign.center,
        ),
        ElevatedButton(
          onPressed: _loadPopularItems,
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No popular items available',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildItemsGrid() {
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
              itemCount: _menuItems.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                return _buildItemCard(_menuItems[index]);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
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
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text(
                'View All Menus',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/order-food', arguments: item);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
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
                  _getImageUrl(item['image']),
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
                    item['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['category'] ?? '',
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
                        (item['rating'] ?? 4.5).toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        _formatPrice(item['price']),
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
