import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../services/recommendation_service.dart';
import '../../../data/models/menu_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/loading_widget.dart';
import 'cart_screen.dart';

class MenuOrderingPage extends StatefulWidget {
  const MenuOrderingPage({Key? key}) : super(key: key);

  @override
  State<MenuOrderingPage> createState() => _MenuOrderingPageState();
}

class _MenuOrderingPageState extends State<MenuOrderingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _personalizedRecommendations = [];
  List<Map<String, dynamic>> _trendingItems = [];
  List<Map<String, dynamic>> _allMenuItems = [];
  bool _isLoadingPersonalized = true;
  bool _isLoadingTrending = true;
  bool _isLoadingAll = true;
  String? _error;

  // Search and filter
  String _searchQuery = '';
  String _selectedCategory = 'All Categories';
  final TextEditingController _searchController = TextEditingController();

  // View state
  bool _showAllRecommendations = false;

  final List<String> _categories = [
    'All Categories',
    'Appetizers',
    'Main Course',
    'Desserts',
    'Beverages',
    'Pakistani',
    'Chinese',
    'Continental'
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadPersonalizedRecommendations(),
      _loadTrendingItems(),
      _loadAllMenuItems(),
    ]);
  }

  Future<void> _loadPersonalizedRecommendations() async {
    try {
      setState(() {
        _isLoadingPersonalized = true;
        _error = null;
      });

      print('🔍 Loading personalized recommendations...');

      // Try to get personalized recommendations using the same API as website
      Map<String, dynamic> response = {};
      try {
        // First try to get user-specific recommendations
        final userId = await RecommendationService.debugGetStoredValues();
        if (userId['userId'] != null) {
          final personalizedResponse = await http.get(
            Uri.parse(
                'http://localhost:8080/api/food-recommendations/recommendations/${userId['userId']}?count=8'),
            headers: {'Content-Type': 'application/json'},
          );

          if (personalizedResponse.statusCode == 200) {
            response = json.decode(personalizedResponse.body);
          }
        }

        // If no personalized recommendations, fall back to popular items
        if (response.isEmpty || response['recommendations'] == null) {
          final popularResponse = await http.get(
            Uri.parse(
                'http://localhost:8080/api/food-recommendations/popular?count=8'),
            headers: {'Content-Type': 'application/json'},
          );

          if (popularResponse.statusCode == 200) {
            final popularData = json.decode(popularResponse.body);
            response = {
              'success': true,
              'recommendations': popularData['popularItems'] ?? [],
            };
          }
        }
      } catch (e) {
        print('Error fetching recommendations: $e');
        response = {'success': false, 'recommendations': []};
      }

      print('📊 Recommendation API Response: $response');

      // Check if we got actual personalized recommendations (not just popular fallback)
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
        print(
            '✅ Got actual personalized recommendations: ${recommendations.length}');

        final aiRecommendations =
            recommendations.map<Map<String, dynamic>>((item) {
          // Handle both direct menu items and recommendation objects
          final menuItem = item['menuItem'] ?? item;
          return {
            '_id': menuItem['_id'] ?? item['_id'] ?? '',
            'name': menuItem['name'] ?? item['name'] ?? '',
            'price': menuItem['price'] ?? item['price'] ?? 0,
            'image': menuItem['image'] ?? item['image'] ?? '',
            'category': menuItem['category'] ?? item['category'] ?? '',
            'description': menuItem['description'] ?? item['description'] ?? '',
            'avgRating': menuItem['averageRating'] ??
                menuItem['avgRating'] ??
                item['averageRating'] ??
                4.5,
            'isAvailable': menuItem['availability'] ??
                menuItem['isAvailable'] ??
                item['availability'] ??
                true,
            'recommendationReason': item['reason'] ?? 'ai_recommended',
            'explanation': item['explanation'] ?? 'AI recommended for you',
            'rank': item['rank'] ?? 1,
            'score': item['score'] ?? 0.8,
          };
        }).toList();

        setState(() {
          _personalizedRecommendations = aiRecommendations;
        });

        // If we have fewer than 4 AI recommendations, supplement with curated items
        if (_personalizedRecommendations.length < 4) {
          print(
              '🔄 Supplementing ${_personalizedRecommendations.length} AI recommendations with curated items...');
          await _supplementWithCuratedItems();
        }
      } else {
        print(
            '⚠️ No personalized recommendations available, using curated selection');
        // Instead of showing all items, show a curated selection of top-rated items
        await _loadCuratedRecommendations();
      }
    } catch (e) {
      print('❌ Error loading personalized recommendations: $e');
      // Fallback to curated selection
      await _loadCuratedRecommendations();
    } finally {
      setState(() {
        _isLoadingPersonalized = false;
      });
    }
  }

  Future<void> _loadCuratedRecommendations() async {
    try {
      print('🎯 Loading curated recommendations from menu items...');

      // Wait for menu items to load if they haven't already
      if (_allMenuItems.isEmpty && _isLoadingAll) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (_allMenuItems.isNotEmpty) {
        // Create a curated selection based on ratings and categories
        final curatedItems = _createCuratedSelection(_allMenuItems);

        setState(() {
          _personalizedRecommendations = curatedItems
              .map<Map<String, dynamic>>((item) => {
                    '_id': item['_id'] ?? '',
                    'name': item['name'] ?? '',
                    'price': item['price'] ?? 0,
                    'image': item['image'] ?? '',
                    'category': item['category'] ?? '',
                    'description': item['description'] ?? '',
                    'avgRating': item['avgRating'] ?? 4.5,
                    'isAvailable': item['isAvailable'] ?? true,
                    'recommendationReason': 'curated',
                    'explanation': 'Curated selection based on ratings',
                    'rank': 1,
                    'score': 0.6,
                  })
              .toList();
        });

        print(
            '✅ Created curated recommendations: ${_personalizedRecommendations.length} items');
      } else {
        print('⚠️ No menu items available for curation');
        setState(() {
          _personalizedRecommendations = [];
        });
      }
    } catch (e) {
      print('❌ Error creating curated recommendations: $e');
      setState(() {
        _personalizedRecommendations = [];
      });
    }
  }

  List<Map<String, dynamic>> _createCuratedSelection(
      List<Map<String, dynamic>> allItems) {
    // Filter available items with good ratings
    final availableItems = allItems
        .where((item) => (item['isAvailable'] ?? true) == true)
        .toList();

    // Sort by rating (highest first)
    availableItems.sort((a, b) {
      final ratingA = (a['avgRating'] ?? 4.0).toDouble();
      final ratingB = (b['avgRating'] ?? 4.0).toDouble();
      return ratingB.compareTo(ratingA);
    });

    // Take top 6 items with variety across categories
    final curatedItems = <Map<String, dynamic>>[];
    final usedCategories = <String>{};

    // First pass: Take highest rated items from different categories
    for (final item in availableItems) {
      if (curatedItems.length >= 6) break;

      final category = item['category'] ?? 'Other';
      if (!usedCategories.contains(category) || usedCategories.length < 3) {
        curatedItems.add(item);
        usedCategories.add(category);
      }
    }

    // Second pass: Fill remaining slots with highest rated items
    for (final item in availableItems) {
      if (curatedItems.length >= 6) break;

      if (!curatedItems.any((existing) => existing['_id'] == item['_id'])) {
        curatedItems.add(item);
      }
    }

    print(
        '🎯 Curated selection: ${curatedItems.map((item) => '${item['name']} (${item['avgRating']})').join(', ')}');

    return curatedItems;
  }

  Future<void> _supplementWithCuratedItems() async {
    try {
      if (_allMenuItems.isEmpty) {
        print('⚠️ No menu items available for supplementing');
        return;
      }

      // Get existing recommendation IDs to avoid duplicates
      final existingIds =
          _personalizedRecommendations.map((item) => item['_id']).toSet();

      // Get additional high-rated items not already recommended
      final availableItems = _allMenuItems
          .where((item) =>
              (item['isAvailable'] ?? true) == true &&
              !existingIds.contains(item['_id']))
          .toList();

      // Sort by rating
      availableItems.sort((a, b) {
        final ratingA = (a['avgRating'] ?? 4.0).toDouble();
        final ratingB = (b['avgRating'] ?? 4.0).toDouble();
        return ratingB.compareTo(ratingA);
      });

      // Take up to 4 additional items to reach a total of 6
      final targetTotal = 6;
      final needed = targetTotal - _personalizedRecommendations.length;
      final supplementItems = availableItems.take(needed).toList();

      if (supplementItems.isNotEmpty) {
        final additionalRecommendations = supplementItems
            .map<Map<String, dynamic>>((item) => {
                  '_id': item['_id'] ?? '',
                  'name': item['name'] ?? '',
                  'price': item['price'] ?? 0,
                  'image': item['image'] ?? '',
                  'category': item['category'] ?? '',
                  'description': item['description'] ?? '',
                  'avgRating': item['avgRating'] ?? 4.5,
                  'isAvailable': item['isAvailable'] ?? true,
                  'recommendationReason': 'curated',
                  'explanation': 'Top rated item',
                  'rank': 2,
                  'score': 0.6,
                })
            .toList();

        setState(() {
          _personalizedRecommendations.addAll(additionalRecommendations);
        });

        print(
            '✅ Added ${additionalRecommendations.length} curated items. Total: ${_personalizedRecommendations.length}');
        print(
            '📋 Final recommendations: ${_personalizedRecommendations.map((item) => '${item['name']} (${item['recommendationReason']})').join(', ')}');
      }
    } catch (e) {
      print('❌ Error supplementing with curated items: $e');
    }
  }

  Future<void> _loadTrendingItems() async {
    try {
      setState(() {
        _isLoadingTrending = true;
      });

      // Use the same API endpoint as the website for popular items
      final response = await http.get(
        Uri.parse(
            'http://localhost:8080/api/food-recommendations/popular?count=6'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['popularItems'] ?? [];
        setState(() {
          _trendingItems = items.map<Map<String, dynamic>>((item) {
            // Handle both direct menu items and recommendation objects
            final menuItem = item['menuItem'] ?? item;
            return {
              '_id': menuItem['_id'] ?? item['_id'] ?? '',
              'name': menuItem['name'] ?? item['name'] ?? '',
              'price': menuItem['price'] ?? item['price'] ?? 0,
              'image': menuItem['image'] ??
                  item['image'] ??
                  '', // Backend path like "/uploads/filename.jpg"
              'category': menuItem['category'] ?? item['category'] ?? '',
              'description':
                  menuItem['description'] ?? item['description'] ?? '',
              'avgRating': menuItem['averageRating'] ??
                  menuItem['avgRating'] ??
                  item['averageRating'] ??
                  4.5,
              'isAvailable': menuItem['availability'] ??
                  menuItem['isAvailable'] ??
                  item['availability'] ??
                  true,
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading trending items: $e');
    } finally {
      setState(() {
        _isLoadingTrending = false;
      });
    }
  }

  Future<void> _loadAllMenuItems() async {
    try {
      setState(() {
        _isLoadingAll = true;
      });

      // Use the same API endpoint as the website: /api/menus
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/menus'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = json.decode(response.body);
        setState(() {
          _allMenuItems = items
              .map<Map<String, dynamic>>((item) => {
                    '_id': item['_id'] ?? '',
                    'name': item['name'] ?? '',
                    'price': item['price'] ?? 0,
                    'image': item['image'] ??
                        '', // This will be the backend path like "/uploads/filename.jpg"
                    'category': item['category'] ?? '',
                    'description': item['description'] ?? '',
                    'avgRating': item['averageRating'] ??
                        4.5, // Note: backend uses 'averageRating'
                    'isAvailable': item['availability'] ??
                        true, // Note: backend uses 'availability'
                    'cuisine': item['cuisine'] ?? '',
                    'spiceLevel': item['spiceLevel'] ?? '',
                    'dietaryTags': item['dietaryTags'] ?? [],
                    'preparationTime': item['preparationTime'] ?? 15,
                  })
              .toList();
        });
      } else {
        // No data available from API
        setState(() {
          _allMenuItems = [];
        });
      }
    } catch (e) {
      print('Error loading all menu items: $e');
      // No data on error
      setState(() {
        _allMenuItems = [];
      });
    } finally {
      setState(() {
        _isLoadingAll = false;
      });
    }
  }

  String _getImageUrl(String? imagePath) {
    // Handle null or empty image paths
    if (imagePath == null || imagePath.isEmpty) {
      return _getFallbackImageUrl();
    }

    // If it's already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Construct the full URL from backend path (same as website)
    // Backend returns paths like "/uploads/filename.jpg"
    final baseUrl = 'http://localhost:8080';
    final cleanPath = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '$baseUrl$cleanPath';
  }

  String _getFallbackImageUrl() {
    // Return a single, reliable placeholder image
    return 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop&crop=center';
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
      'ai_recommended': {
        'text': 'AI Pick',
        'color': Colors.purple,
        'icon': Icons.psychology
      },
      'curated': {
        'text': 'Top Rated',
        'color': Colors.amber,
        'icon': Icons.star
      },
      'recommended': {
        'text': 'AI Pick',
        'color': Colors.pink,
        'icon': Icons.psychology
      },
      'pakistani_cuisine': {
        'text': 'Pakistani',
        'color': Colors.red,
        'icon': Icons.flag
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
            color: badge['color'].withValues(alpha: 0.4),
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
      String menuItemId, String interactionType) async {
    try {
      await RecommendationService.recordFoodInteraction(
        menuItemId: menuItemId,
        interactionType: interactionType,
      );
    } catch (e) {
      print('Error recording interaction: $e');
    }
  }

  void _handleMenuItemTap(Map<String, dynamic> menuItem) async {
    // Record view interaction
    await _recordInteraction(menuItem['_id'], 'view');

    // For now, just add to cart directly
    _handleAddToCart(menuItem);
  }

  void _handleAddToCart(Map<String, dynamic> menuItem) async {
    // Record order interaction
    await _recordInteraction(menuItem['_id'], 'order');

    // Add to cart
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final menuItemModel = MenuItemModel(
      id: menuItem['_id'],
      name: menuItem['name'],
      price: (menuItem['price'] ?? 0).toDouble(),
      imageUrl: _getImageUrl(menuItem['image']),
      category: menuItem['category'] ?? 'Main Course',
      description: menuItem['description'] ?? '',
      ingredients: [], // Empty ingredients list for now
      isAvailable: menuItem['isAvailable'] ?? true,
    );

    cartProvider.addItem(
      menuItem: menuItemModel,
      quantity: 1,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${menuItem['name']} added to cart!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CartScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredItems(
      List<Map<String, dynamic>> items) {
    return items.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item['description']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All Categories' ||
          item['category'].toString().toLowerCase() ==
              _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
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
                    color: Colors.black.withValues(alpha: 0.3),
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
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
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
                              'Order Food',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Delicious meals just for you',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Cart and notification icons
                      Row(
                        children: [
                          // Cart Icon with Badge
                          Consumer<CartProvider>(
                            builder: (context, cart, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const CartScreen(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.shopping_cart_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  if (cart.itemCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF6B6B),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          '${cart.itemCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
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

                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Search for delicious food...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: Color(0xFFFF6B6B),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Category Filter Chips
                    Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category;
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFFF6B6B),
                                            Color(0xFFFF8E8E)
                                          ],
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFF6B6B)
                                        : Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFFF6B6B)
                                                .withValues(alpha: 0.4),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Personalized Recommendations Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                            const Color(0xFFBB86FC).withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B6B),
                                      Color(0xFFFF8E8E)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.psychology,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Just For You',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showAllRecommendations =
                                        !_showAllRecommendations;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _showAllRecommendations
                                            ? 'Show Less'
                                            : 'View All (${_allMenuItems.length})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _showAllRecommendations
                                            ? Icons.keyboard_arrow_up
                                            : Icons.arrow_forward_ios,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // For You Section - Show Full Menu (not just recommendations)
                          _showAllRecommendations
                              ? _buildForYouFullMenuGrid()
                              : SizedBox(
                                  height: 140,
                                  child: _isLoadingAll
                                      ? const Center(child: LoadingWidget())
                                      : ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemCount:
                                              _allMenuItems.take(6).length,
                                          itemBuilder: (context, index) {
                                            final item = _allMenuItems[index];
                                            return Container(
                                              width: 160,
                                              margin: const EdgeInsets.only(
                                                  right: 16),
                                              child:
                                                  _buildCompactMenuCard(item),
                                            );
                                          },
                                        ),
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Trending Section
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange,
                                      Colors.orange.withValues(alpha: 0.8)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.trending_up,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Trending',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Text(
                                '${_trendingItems.length} items',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            height: 140,
                            child: _buildTrendingPreview(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Pakistani Section
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green,
                                      Colors.green.withValues(alpha: 0.8)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.flag,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Pakistani Cuisine',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Text(
                                'Recommendations',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            height: 140,
                            child: _buildPakistaniPreview(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // For You section - Show full menu instead of just recommendations
  Widget _buildForYouFullMenuGrid() {
    final filteredItems = _getFilteredItems(_allMenuItems);

    if (_isLoadingAll) {
      return const Center(child: LoadingWidget());
    }

    if (filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No menu items found',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildMenuItemCard(item);
      },
    );
  }

  Widget _buildPersonalizedTabButton(int index, String text, Color color) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                )
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color:
                isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPersonalizedPreview() {
    if (_isLoadingPersonalized) {
      return const Center(child: LoadingWidget());
    }

    if (_personalizedRecommendations.isEmpty) {
      return const Center(
        child: Text(
          'No personalized recommendations available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _personalizedRecommendations.take(3).length,
      itemBuilder: (context, index) {
        final item = _personalizedRecommendations[index];
        return Container(
          width: 200,
          margin: const EdgeInsets.only(right: 12),
          child: _buildMenuItemCard(item, isRecommended: true, isCompact: true),
        );
      },
    );
  }

  Widget _buildTrendingPreview() {
    if (_isLoadingTrending) {
      return const Center(child: LoadingWidget());
    }

    if (_trendingItems.isEmpty) {
      return const Center(
        child: Text(
          'No trending items available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _trendingItems
          .length, // Show all trending items (recommendations only)
      itemBuilder: (context, index) {
        final item = _trendingItems[index];
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 16),
          child: _buildCompactMenuCard(item),
        );
      },
    );
  }

  Widget _buildPakistaniPreview() {
    // Filter Pakistani cuisine items from all menu items
    final pakistaniItems = _allMenuItems
        .where((item) =>
            (item['category']?.toString().toLowerCase().contains('pakistani') ==
                true) ||
            (item['cuisine']?.toString().toLowerCase().contains('pakistani') ==
                true))
        .take(6) // Show only recommendations (limited number)
        .toList();

    if (_isLoadingAll) {
      return const Center(child: LoadingWidget());
    }

    if (pakistaniItems.isEmpty) {
      return const Center(
        child: Text(
          'No Pakistani cuisine available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: pakistaniItems.length, // Show only recommendations
      itemBuilder: (context, index) {
        final item = pakistaniItems[index];
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 16),
          child: _buildCompactMenuCard(item),
        );
      },
    );
  }

  Widget _buildAllMenuItemsGrid() {
    final filteredItems = _getFilteredItems(_allMenuItems);

    if (_isLoadingAll) {
      return const Center(child: LoadingWidget());
    }

    if (filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No menu items found',
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
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return _buildMenuItemCard(item);
        },
      ),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> menuItem,
      {bool isRecommended = false, bool isCompact = false}) {
    final imageUrl = _getImageUrl(menuItem['image']);
    final rating = (menuItem['avgRating'] ?? 4.5).toDouble();
    final isAvailable = menuItem['isAvailable'] ?? true;
    final price = (menuItem['price'] ?? 0).toDouble();

    return GestureDetector(
      onTap: () => _handleMenuItemTap(menuItem),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable
                ? const Color(0xFFFF6B6B).withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: (isAvailable ? const Color(0xFFFF6B6B) : Colors.grey)
                  .withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and badges
            Expanded(
              flex: isCompact ? 2 : 3,
              child: Stack(
                children: [
                  // Menu item image with better error handling
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      color: Colors.grey[800], // Fallback background
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Stack(
                        children: [
                          Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF4F46E5)
                                          .withValues(alpha: 0.8),
                                      const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.restaurant_menu,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text(
                                        menuItem['name'] ?? 'Food Item',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[800],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: const Color(0xFFFF6B6B),
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
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
                                  Colors.black.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Recommendation badge (only for recommended items)
                  if (isRecommended)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _getRecommendationBadge(
                          menuItem['recommendationReason']),
                    ),

                  // Availability badge
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
                        isAvailable ? 'Available' : 'Unavailable',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Add to cart button
                  if (isAvailable)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _handleAddToCart(menuItem),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B6B)
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Menu item details
            Expanded(
              flex: isCompact ? 1 : 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Item name
                    Text(
                      menuItem['name'] ?? 'Unknown Item',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (!isCompact) ...[
                      const SizedBox(height: 4),

                      // Description
                      Text(
                        menuItem['description'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 4),

                    // Price and rating
                    Row(
                      children: [
                        Text(
                          'Rs. ${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Recommendation explanation (only for recommended items)
                    if (isRecommended &&
                        menuItem['explanation'] != null &&
                        !isCompact)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            menuItem['explanation'],
                            style: TextStyle(
                              color: const Color(0xFFFF6B6B)
                                  .withValues(alpha: 0.8),
                              fontSize: 9,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
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
    );
  }

  Widget _buildCompactMenuCard(Map<String, dynamic> menuItem,
      {bool isRecommended = false}) {
    final imageUrl = _getImageUrl(menuItem['image']);
    final rating = (menuItem['avgRating'] ?? 4.5).toDouble();
    final isAvailable = menuItem['isAvailable'] ?? true;
    final price = (menuItem['price'] ?? 0).toDouble();

    return GestureDetector(
      onTap: () => _handleMenuItemTap(menuItem),
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
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      color: Colors.grey[800], // Fallback background color
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          print('🖼️ Image failed to load: $imageUrl');
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF4F46E5)
                                      .withValues(alpha: 0.8),
                                  const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.restaurant_menu,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    menuItem['name'] ?? 'Food Item',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[800],
                            child: Center(
                              child: CircularProgressIndicator(
                                color: const Color(0xFFFF6B6B),
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (isRecommended)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _getRecommendationBadge(
                          menuItem['recommendationReason']),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _handleAddToCart(menuItem),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B)
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details section
            Container(
              height: 50, // Fixed height to prevent overflow
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    menuItem['name'] ?? 'Unknown Item',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        'Rs. ${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 9),
                          const SizedBox(width: 1),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMenuGrid() {
    final filteredItems = _getFilteredItems(_allMenuItems);

    if (_isLoadingAll) {
      return const Center(child: LoadingWidget());
    }

    if (filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No menu items found',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildModernMenuCard(item);
      },
    );
  }

  Widget _buildModernMenuCard(Map<String, dynamic> menuItem) {
    final imageUrl = _getImageUrl(menuItem['image']);
    final rating = (menuItem['avgRating'] ?? 4.5).toDouble();
    final isAvailable = menuItem['isAvailable'] ?? true;
    final price = (menuItem['price'] ?? 0).toDouble();

    return GestureDetector(
      onTap: () => _handleMenuItemTap(menuItem),
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
                ? const Color(0xFFFF6B6B).withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isAvailable ? const Color(0xFFFF6B6B) : Colors.grey)
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
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      color: Colors.grey[800], // Fallback background
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Stack(
                        children: [
                          Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF4F46E5)
                                          .withValues(alpha: 0.8),
                                      const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.restaurant_menu,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(
                                        menuItem['name'] ?? 'Food Item',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[800],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: const Color(0xFFFF6B6B),
                                    strokeWidth: 3,
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Gradient overlay
                          Container(
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
                        ],
                      ),
                    ),
                  ),
                  // Availability badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isAvailable
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        isAvailable ? 'Available' : 'Sold Out',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Add to cart button
                  if (isAvailable)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _handleAddToCart(menuItem),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B6B)
                                    .withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Modern Details Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      menuItem['name'] ?? 'Unknown Item',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        menuItem['description'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Rs. ${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
