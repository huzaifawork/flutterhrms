import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../services/recommendation_service.dart';
import '../../../../models/recommendation_model.dart';
import '../../../../data/models/menu_item_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/loading_widget.dart';
import '../../orders/cart_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  // Recommendation data
  List<FoodRecommendation> _personalizedRecommendations = [];
  List<FoodRecommendation> _trendingItems = [];

  // UI state
  String _activeRecommendationTab = 'for_you'; // for_you, trending, refresh
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this); // For You, Trending, Refresh
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _isLoadingRecommendations = true;
      _error = null;
    });

    try {
      // Load personalized recommendations
      await _loadPersonalizedRecommendations();

      // Load trending items
      await _loadTrendingItems();

      setState(() {
        _isLoading = false;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingRecommendations = false;
        _error = 'Failed to load recommendations: $e';
      });
    }
  }

  Future<void> _loadPersonalizedRecommendations() async {
    try {
      final response =
          await RecommendationService.getFoodRecommendations(count: 20);

      if (response['success'] == true) {
        final recommendations = response['recommendations'] ?? [];
        setState(() {
          _personalizedRecommendations = recommendations
              .map<FoodRecommendation>(
                  (item) => FoodRecommendation.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading personalized recommendations: $e');
      // Fallback to popular items
      await _loadPopularItems();
    }
  }

  Future<void> _loadTrendingItems() async {
    try {
      final response =
          await RecommendationService.getPopularFoodItems(count: 20);

      if (response['success'] == true) {
        final items = response['popularItems'] ?? [];
        setState(() {
          _trendingItems = items
              .map<FoodRecommendation>(
                  (item) => FoodRecommendation.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading trending items: $e');
    }
  }

  Future<void> _loadPopularItems() async {
    try {
      final response =
          await RecommendationService.getPopularFoodItems(count: 20);

      if (response['success'] == true) {
        final items = response['popularItems'] ?? [];
        setState(() {
          _personalizedRecommendations = items
              .map<FoodRecommendation>(
                  (item) => FoodRecommendation.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading popular items: $e');
    }
  }

  // Convert FoodRecommendation to MenuItemModel
  MenuItemModel _convertToMenuItemModel(FoodRecommendation recommendation) {
    return MenuItemModel(
      id: recommendation.menuItemId,
      name: recommendation.name,
      category: recommendation.category,
      price: recommendation.price,
      description: recommendation.description,
      ingredients: [], // Default empty list
      imageUrl: recommendation.image ?? '',
      isAvailable: recommendation.availability,
      isVegetarian: recommendation.dietaryTags?.contains('vegetarian') ?? false,
      isVegan: recommendation.dietaryTags?.contains('vegan') ?? false,
      isGlutenFree:
          recommendation.dietaryTags?.contains('gluten-free') ?? false,
      averageRating: recommendation.averageRating ?? 0.0,
      totalRatings: 0, // Default value
      image: recommendation.image,
    );
  }

  // Helper method to build food image with fallback
  Widget _buildFoodImage(String? imageUrl) {
    // List of fallback food images
    final fallbackImages = [
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
    ];

    final randomFallback =
        fallbackImages[DateTime.now().millisecond % fallbackImages.length];
    final displayUrl =
        imageUrl?.isNotEmpty == true ? imageUrl! : randomFallback;

    return Image.network(
      displayUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey.shade300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant,
                size: 32,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 8),
              Text(
                'Food Image',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFBB86FC),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A192F),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFBB86FC),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A192F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRecommendations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB86FC),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0A192F),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0A192F),
                      Color(0xFF1A2332),
                      Color(0xFF2A3441),
                    ],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star,
                        color: Color(0xFF64FFDA),
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Recommended for You',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'AI-powered recommendations based on your preferences',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64FFDA),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart,
                            color: Color(0xFF64FFDA)),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CartScreen(),
                            ),
                          );
                        },
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBB86FC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
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
            ],
          ),

          // Recommendation Tabs Section
          SliverToBoxAdapter(
            child: _buildRecommendationTabs(),
          ),

          // Recommendations Grid
          SliverToBoxAdapter(
            child: _buildRecommendationsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Warning message
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing popular items instead',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recommendation Tabs
          Row(
            children: [
              _buildTabButton('For You', 'for_you', Icons.person),
              const SizedBox(width: 12),
              _buildTabButton('Trending', 'trending', Icons.trending_up),
              const SizedBox(width: 12),
              _buildTabButton('Refresh', 'refresh', Icons.refresh),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, String tabKey, IconData icon) {
    final isActive = _activeRecommendationTab == tabKey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeRecommendationTab = tabKey;
          });

          if (tabKey == 'refresh') {
            _loadRecommendations();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFFBB86FC), Color(0xFF64FFDA)],
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : const Color(0xFF64FFDA).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.black : const Color(0xFF64FFDA),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsGrid() {
    List<FoodRecommendation> currentRecommendations;

    switch (_activeRecommendationTab) {
      case 'trending':
        currentRecommendations = _trendingItems;
        break;
      case 'for_you':
      case 'refresh':
      default:
        currentRecommendations = _personalizedRecommendations;
        break;
    }

    if (_isLoadingRecommendations) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFBB86FC),
          ),
        ),
      );
    }

    if (currentRecommendations.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.restaurant_menu,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              const Text(
                'No recommendations found',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRecommendations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB86FC),
                ),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: currentRecommendations.length,
        itemBuilder: (context, index) {
          return _buildRecommendationCard(currentRecommendations[index]);
        },
      ),
    );
  }

  Widget _buildRecommendationCard(FoodRecommendation recommendation) {
    return GestureDetector(
      onTap: () {
        // Record view interaction
        RecommendationService.recordFoodInteraction(
          menuItemId: recommendation.menuItemId,
          interactionType: 'view',
        );

        // Navigate to details (you can implement this later)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${recommendation.name} details'),
            backgroundColor: const Color(0xFFBB86FC),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF64FFDA).withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Menu Item Image
                    Stack(
                      children: [
                        _buildFoodImage(recommendation.image),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Recommendation Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFBB86FC), Color(0xFF64FFDA)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getRecommendationBadgeText(
                                  recommendation.reason),
                              style: const TextStyle(
                                color: Colors.black,
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
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Rs. ${recommendation.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF64FFDA),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name
                      Text(
                        recommendation.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Description
                      Text(
                        recommendation.description.isNotEmpty
                            ? recommendation.description
                            : 'Delicious Pakistani cuisine',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),

                      // Bottom Row with Rating and Add Button
                      Row(
                        children: [
                          // Rating
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                recommendation.score.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),

                          // Add to Cart Button
                          GestureDetector(
                            onTap: () {
                              // Record interaction
                              RecommendationService.recordFoodInteraction(
                                menuItemId: recommendation.menuItemId,
                                interactionType: 'add_to_cart',
                              );

                              // Convert FoodRecommendation to MenuItemModel
                              final menuItem =
                                  _convertToMenuItemModel(recommendation);

                              // Add to cart
                              final cartProvider = Provider.of<CartProvider>(
                                  context,
                                  listen: false);
                              cartProvider.addItem(
                                menuItem: menuItem,
                                quantity: 1,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${recommendation.name} added to cart!'),
                                  backgroundColor: const Color(0xFFBB86FC),
                                  action: SnackBarAction(
                                    label: 'View Cart',
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
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFBB86FC),
                                    Color(0xFF64FFDA)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_shopping_cart,
                                    size: 12,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Colors.black,
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

  String _getRecommendationBadgeText(String? reason) {
    switch (reason) {
      case 'collaborative_filtering':
        return 'Similar Users';
      case 'content_based':
        return 'Your Taste';
      case 'popularity':
        return 'Trending';
      case 'pakistani_cuisine':
        return 'Pakistani';
      default:
        return 'AI Pick';
    }
  }
}
