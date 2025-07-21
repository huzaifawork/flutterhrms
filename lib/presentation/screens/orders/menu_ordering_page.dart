import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/environment.dart';
import '../../../services/recommendation_service.dart';
import '../../../data/models/menu_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/loading_widget.dart';
import 'cart_screen.dart';

class MenuOrderingPage extends StatefulWidget {
  const MenuOrderingPage({super.key});

  @override
  State<MenuOrderingPage> createState() => _MenuOrderingPageState();
}

class _MenuOrderingPageState extends State<MenuOrderingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _personalizedRecommendations = [],
      _trendingItems = [],
      _allMenuItems = [];
  bool _isLoadingPersonalized = true,
      _isLoadingTrending = true,
      _isLoadingAll = true,
      _showAllRecommendations = false;
  String? _error, _selectedCategory = 'All Categories', _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = const [
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

  Future<void> _loadInitialData() async => await Future.wait([
        _loadPersonalizedRecommendations(),
        _loadTrendingItems(),
        _loadAllMenuItems()
      ]);

  Future<void> _loadPersonalizedRecommendations() async {
    try {
      setState(() {
        _isLoadingPersonalized = true;
        _error = null;
      });
      Map<String, dynamic> response = {};
      final userId = await RecommendationService.debugGetStoredValues();
      if (userId['userId'] != null) {
        final personalizedResponse = await http.get(
          Uri.parse(
              '${Environment.currentApiUrl}/api/food-recommendations/recommendations/${userId['userId']}?count=8'),
          headers: {'Content-Type': 'application/json'},
        );
        if (personalizedResponse.statusCode == 200) {
          response = json.decode(personalizedResponse.body);
        }
      }
      if (response.isEmpty || response['recommendations'] == null) {
        final popularResponse = await http.get(
          Uri.parse(
              '${Environment.currentApiUrl}/api/food-recommendations/popular?count=8'),
          headers: {'Content-Type': 'application/json'},
        );
        if (popularResponse.statusCode == 200) {
          response = {
            'success': true,
            'recommendations':
                json.decode(popularResponse.body)['popularItems'] ?? []
          };
        }
      }
      bool isActuallyPersonalized = false;
      final recommendations = response['recommendations'] ?? [];
      if (response['success'] == true && recommendations.isNotEmpty) {
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
        final aiRecommendations =
            recommendations.map<Map<String, dynamic>>((item) {
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
        setState(() => _personalizedRecommendations = aiRecommendations);
        if (_personalizedRecommendations.length < 4) {
          await _supplementWithCuratedItems();
        }
      } else {
        await _loadCuratedRecommendations();
      }
    } catch (e) {
      await _loadCuratedRecommendations();
    } finally {
      setState(() => _isLoadingPersonalized = false);
    }
  }

  Future<void> _loadCuratedRecommendations() async {
    try {
      if (_allMenuItems.isEmpty && _isLoadingAll) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (_allMenuItems.isNotEmpty) {
        final curatedItems = _createCuratedSelection(_allMenuItems);
        setState(() => _personalizedRecommendations = curatedItems
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
            .toList());
      } else {
        setState(() => _personalizedRecommendations = []);
      }
    } catch (e) {
      setState(() => _personalizedRecommendations = []);
    }
  }

  List<Map<String, dynamic>> _createCuratedSelection(
      List<Map<String, dynamic>> allItems) {
    final availableItems = allItems
        .where((item) => (item['isAvailable'] ?? true) == true)
        .toList();
    availableItems.sort((a, b) => (b['avgRating'] ?? 4.0)
        .toDouble()
        .compareTo((a['avgRating'] ?? 4.0).toDouble()));
    final curatedItems = <Map<String, dynamic>>[];
    final usedCategories = <String>{};
    for (final item in availableItems) {
      if (curatedItems.length >= 6) break;
      final category = item['category'] ?? 'Other';
      if (!usedCategories.contains(category) || usedCategories.length < 3) {
        curatedItems.add(item);
        usedCategories.add(category);
      }
    }
    for (final item in availableItems) {
      if (curatedItems.length >= 6) break;
      if (!curatedItems.any((existing) => existing['_id'] == item['_id'])) {
        curatedItems.add(item);
      }
    }
    return curatedItems;
  }

  Future<void> _supplementWithCuratedItems() async {
    try {
      if (_allMenuItems.isEmpty) return;
      final existingIds =
          _personalizedRecommendations.map((item) => item['_id']).toSet();
      final availableItems = _allMenuItems
          .where((item) =>
              (item['isAvailable'] ?? true) == true &&
              !existingIds.contains(item['_id']))
          .toList();
      availableItems.sort((a, b) => (b['avgRating'] ?? 4.0)
          .toDouble()
          .compareTo((a['avgRating'] ?? 4.0).toDouble()));
      final needed = 6 - _personalizedRecommendations.length;
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
        setState(() =>
            _personalizedRecommendations.addAll(additionalRecommendations));
      }
    } catch (e) {
      debugPrint('Error supplementing with curated items: $e');
    }
  }

  Future<void> _loadTrendingItems() async {
    try {
      setState(() => _isLoadingTrending = true);
      final response = await http.get(
        Uri.parse(
            '${Environment.currentApiUrl}/api/food-recommendations/popular?count=6'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['popularItems'] ?? [];
        setState(() => _trendingItems = items.map<Map<String, dynamic>>((item) {
              final menuItem = item['menuItem'] ?? item;
              return {
                '_id': menuItem['_id'] ?? item['_id'] ?? '',
                'name': menuItem['name'] ?? item['name'] ?? '',
                'price': menuItem['price'] ?? item['price'] ?? 0,
                'image': menuItem['image'] ?? item['image'] ?? '',
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
            }).toList());
      }
    } catch (e) {
      debugPrint('Error loading trending items: $e');
    } finally {
      setState(() => _isLoadingTrending = false);
    }
  }

  Future<void> _loadAllMenuItems() async {
    try {
      setState(() => _isLoadingAll = true);
      final response = await http.get(
        Uri.parse('${Environment.currentApiUrl}/api/menus'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> items = json.decode(response.body);
        setState(() => _allMenuItems = items
            .map<Map<String, dynamic>>((item) => {
                  '_id': item['_id'] ?? '',
                  'name': item['name'] ?? '',
                  'price': item['price'] ?? 0,
                  'image': item['image'] ?? '',
                  'category': item['category'] ?? '',
                  'description': item['description'] ?? '',
                  'avgRating': item['averageRating'] ?? 4.5,
                  'isAvailable': item['availability'] ?? true,
                  'cuisine': item['cuisine'] ?? '',
                  'spiceLevel': item['spiceLevel'] ?? '',
                  'dietaryTags': item['dietaryTags'] ?? [],
                  'preparationTime': item['preparationTime'] ?? 15,
                })
            .toList());
      } else {
        setState(() => _allMenuItems = []);
      }
    } catch (e) {
      setState(() => _allMenuItems = []);
    } finally {
      setState(() => _isLoadingAll = false);
    }
  }

  String _getImageUrl(String? imagePath) => imagePath == null ||
          imagePath.isEmpty
      ? _getFallbackImageUrl()
      : imagePath.startsWith('http://') || imagePath.startsWith('https://')
          ? imagePath
          : '${Environment.currentApiUrl}${imagePath.startsWith('/') ? imagePath : '/$imagePath'}';

  String _getFallbackImageUrl() =>
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop&crop=center';

  Widget _getRecommendationBadge(String? reason) {
    if (reason == null) return const SizedBox.shrink();
    const badges = {
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
        gradient: LinearGradient(colors: [
          (badge['color'] as MaterialColor).shade400,
          (badge['color'] as MaterialColor).shade300,
        ]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (badge['color'] as MaterialColor).withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge['icon'] as IconData, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            badge['text'] as String,
            style: const TextStyle(
                color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _recordInteraction(
      String menuItemId, String interactionType) async {
    try {
      await RecommendationService.recordFoodInteraction(
          menuItemId: menuItemId, interactionType: interactionType);
    } catch (e) {
      debugPrint('Error recording interaction: $e');
    }
  }

  void _handleMenuItemTap(Map<String, dynamic> menuItem) async {
    await _recordInteraction(menuItem['_id'], 'view');
    _handleAddToCart(menuItem);
  }

  void _handleAddToCart(Map<String, dynamic> menuItem) async {
    await _recordInteraction(menuItem['_id'], 'order');
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final menuItemModel = MenuItemModel(
      id: menuItem['_id'],
      name: menuItem['name'],
      price: (menuItem['price'] ?? 0).toDouble(),
      imageUrl: _getImageUrl(menuItem['image']),
      category: menuItem['category'] ?? 'Main Course',
      description: menuItem['description'] ?? '',
      ingredients: [],
      isAvailable: menuItem['isAvailable'] ?? true,
    );
    cartProvider.addItem(menuItem: menuItemModel, quantity: 1);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${menuItem['name']} added to cart!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredItems(
          List<Map<String, dynamic>> items) =>
      items.where((item) {
        final matchesSearch = (_searchQuery?.isEmpty ?? true) ||
            item['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery?.toLowerCase() ?? '') ||
            item['description']
                .toString()
                .toLowerCase()
                .contains(_searchQuery?.toLowerCase() ?? '');
        final matchesCategory = _selectedCategory == 'All Categories' ||
            item['category'].toString().toLowerCase() ==
                _selectedCategory?.toLowerCase();
        return matchesSearch && matchesCategory;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
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
                                  color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Food',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Delicious meals just for you',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFFCCCCCC),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Consumer<CartProvider>(
                            builder: (context, cart, child) => Stack(
                              alignment: Alignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (!mounted) return;
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => const CartScreen()),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.2)),
                                    ),
                                    child: const Icon(
                                        Icons.shopping_cart_outlined,
                                        color: Colors.white,
                                        size: 20),
                                  ),
                                ),
                                if (cart.itemCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF6B6B),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)),
                                      ),
                                      constraints: const BoxConstraints(
                                          minWidth: 18, minHeight: 18),
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
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 20),
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
                                  fontSize: 15),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune,
                              color: Color(0xFFFF6B6B), size: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final isSelected =
                                    _selectedCategory == category;
                                return Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedCategory = category),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? const LinearGradient(colors: [
                                                Color(0xFFFF6B6B),
                                                Color(0xFFFF8E8E)
                                              ])
                                            : null,
                                        color: isSelected
                                            ? null
                                            : Colors.white
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFFF6B6B)
                                              : Colors.white
                                                  .withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFFFF6B6B)
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 5),
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        category,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white
                                                  .withValues(alpha: 0.8),
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
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFFF6B6B)
                                      .withValues(alpha: 0.15),
                                  const Color(0xFFBB86FC)
                                      .withValues(alpha: 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B6B)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          Color(0xFFFF6B6B),
                                          Color(0xFFFF8E8E)
                                        ]),
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(12)),
                                      ),
                                      child: const Icon(Icons.psychology,
                                          color: Colors.white, size: 20),
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
                                      onTap: () => setState(() =>
                                          _showAllRecommendations =
                                              !_showAllRecommendations),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.3),
                                              width: 1),
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
                                _showAllRecommendations
                                    ? _buildForYouFullMenuGrid()
                                    : SizedBox(
                                        height: 140,
                                        child: _isLoadingAll
                                            ? const Center(
                                                child: LoadingWidget())
                                            : ListView.builder(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                itemCount: _allMenuItems
                                                    .take(6)
                                                    .length,
                                                itemBuilder: (context, index) =>
                                                    Container(
                                                  width: 160,
                                                  margin: const EdgeInsets.only(
                                                      right: 16),
                                                  child: _buildCompactMenuCard(
                                                      _allMenuItems[index]),
                                                ),
                                              ),
                                      ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
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
                                      child: const Icon(Icons.trending_up,
                                          color: Colors.white, size: 20),
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
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                    height: 140,
                                    child: _buildTrendingPreview()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
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
                                      child: const Icon(Icons.flag,
                                          color: Colors.white, size: 20),
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
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                    height: 140,
                                    child: _buildPakistaniPreview()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForYouFullMenuGrid() {
    final filteredItems = _getFilteredItems(_allMenuItems);
    if (_isLoadingAll) return const Center(child: LoadingWidget());
    if (filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text('No menu items found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;
        final childAspectRatio = constraints.maxWidth > 900
            ? 0.9
            : constraints.maxWidth > 600
                ? 0.85
                : 0.8;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) =>
              _buildMenuItemCard(filteredItems[index]),
        );
      },
    );
  }

  Widget _buildTrendingPreview() {
    if (_isLoadingTrending) return const Center(child: LoadingWidget());
    if (_trendingItems.isEmpty) {
      return const Center(
          child: Text('No trending items available',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _trendingItems.length,
      itemBuilder: (context, index) => Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: _buildCompactMenuCard(_trendingItems[index]),
      ),
    );
  }

  Widget _buildPakistaniPreview() {
    final pakistaniItems = _allMenuItems
        .where((item) =>
            (item['category']?.toString().toLowerCase().contains('pakistani') ==
                true) ||
            (item['cuisine']?.toString().toLowerCase().contains('pakistani') ==
                true))
        .take(6)
        .toList();
    if (_isLoadingAll) return const Center(child: LoadingWidget());
    if (pakistaniItems.isEmpty) {
      return const Center(
          child: Text('No Pakistani cuisine available',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: pakistaniItems.length,
      itemBuilder: (context, index) => Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: _buildCompactMenuCard(pakistaniItems[index]),
      ),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> menuItem,
      {bool isRecommended = false, bool isCompact = false}) {
    final imageUrl = _getImageUrl(menuItem['image']);
    final rating = (menuItem['avgRating'] ?? 4.5).toDouble();
    final price = (menuItem['price'] ?? 0).toDouble();
    final titleFontSize = isCompact ? 12.0 : 14.0;

    return LayoutBuilder(
      builder: (context, constraints) {
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
                color: menuItem['isAvailable'] ?? true
                    ? const Color(0xFFFF6B6B).withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: (menuItem['isAvailable'] ?? true
                          ? const Color(0xFFFF6B6B)
                          : Colors.grey)
                      .withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isCompact ? 2 : 3,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          color: Colors.grey[800],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: Stack(
                            children: [
                              Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
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
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.restaurant_menu,
                                            color: Colors.white, size: 24),
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
                                ),
                                loadingBuilder: (context, child,
                                        loadingProgress) =>
                                    loadingProgress == null
                                        ? child
                                        : Container(
                                            color: Colors.grey[800],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: const Color(0xFFFF6B6B),
                                                strokeWidth: 2,
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          ),
                              ),
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
                      if (isRecommended)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _getRecommendationBadge(
                              menuItem['recommendationReason']),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: menuItem['isAvailable'] ?? true
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            menuItem['isAvailable'] ?? true
                                ? 'Available'
                                : 'Unavailable',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (menuItem['isAvailable'] ?? true)
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
                              child: const Icon(Icons.add_shopping_cart,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: isCompact ? 1 : 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          menuItem['name'] ?? 'Unknown Item',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isCompact) ...[
                          const SizedBox(height: 4),
                          Text(
                            menuItem['description'] ?? '',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
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
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
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
      },
    );
  }

  Widget _buildCompactMenuCard(Map<String, dynamic> menuItem,
      {bool isRecommended = false}) {
    final imageUrl = _getImageUrl(menuItem['image']);
    final rating = (menuItem['avgRating'] ?? 4.5).toDouble();
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
              width: 1.5),
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
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      color: Colors.grey[800],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF4F46E5).withValues(alpha: 0.8),
                                const Color(0xFF7C3AED).withValues(alpha: 0.6),
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
                                child: const Icon(Icons.restaurant_menu,
                                    color: Colors.white, size: 20),
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
                        ),
                        loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null
                                ? child
                                : Container(
                                    color: Colors.grey[800],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: const Color(0xFFFF6B6B),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
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
                  if (menuItem['isAvailable'] ?? true)
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
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              height: 50,
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
                                fontSize: 8),
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
}
