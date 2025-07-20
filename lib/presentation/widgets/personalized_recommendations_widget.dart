import 'package:flutter/material.dart';
import '../../services/recommendation_service.dart';
import '../../models/recommendation_model.dart';
import '../screens/recommendations_screen.dart';

class PersonalizedRecommendationsWidget extends StatefulWidget {
  final int maxItems;
  final bool showHeader;
  final Function(Map<String, dynamic>)? onAddToCart;
  final Function(String, int)? onRate;

  const PersonalizedRecommendationsWidget({
    super.key,
    this.maxItems = 8,
    this.showHeader = true,
    this.onAddToCart,
    this.onRate,
  });

  @override
  State<PersonalizedRecommendationsWidget> createState() =>
      _PersonalizedRecommendationsWidgetState();
}

class _PersonalizedRecommendationsWidgetState
    extends State<PersonalizedRecommendationsWidget> {
  List<FoodRecommendation> _recommendations = [];
  bool _isLoading = true;
  String? _error;
  String _activeTab = 'personalized';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> response;

      switch (_activeTab) {
        case 'personalized':
          try {
            response = await RecommendationService.getFoodRecommendations(
                count: widget.maxItems);
          } catch (personalizedError) {
            print(
                'Personalized recommendations failed, using popular items: $personalizedError');
            response = await RecommendationService.getPopularFoodItems(
                count: widget.maxItems);
          }
          break;
        case 'popular':
          response = await RecommendationService.getPopularFoodItems(
              count: widget.maxItems);
          break;
        default:
          response = await RecommendationService.getPopularFoodItems(
              count: widget.maxItems);
      }

      if (response['success'] == true) {
        final items =
            response['recommendations'] ?? response['popularItems'] ?? [];
        setState(() {
          _recommendations = items.map<FoodRecommendation>((item) {
            // Handle both nested and flat structures
            final itemData = item is Map<String, dynamic> ? item : {};

            // Create a normalized structure for FoodRecommendation
            final normalizedItem = {
              '_id': itemData['_id'] ?? itemData['menuItemId'] ?? '',
              'menuItemId': itemData['menuItemId'] ?? itemData['_id'] ?? '',
              'name': itemData['name'] ?? '',
              'description': itemData['description'] ?? '',
              'price': itemData['price'] ?? 0,
              'category': itemData['category'] ?? '',
              'image': itemData['image'] ?? '',
              'availability': itemData['availability'] ?? true,
              'cuisine': itemData['cuisine'] ?? 'Pakistani',
              'spiceLevel': itemData['spiceLevel'] ?? 'mild',
              'dietaryTags': itemData['dietaryTags'] ?? [],
              'preparationTime': itemData['preparationTime'],
              'averageRating': itemData['averageRating'] ?? 4.0,
              'totalRatings': itemData['totalRatings'] ?? 0,
              'score': itemData['score'] ?? itemData['averageRating'] ?? 4.0,
              'reason': itemData['reason'] ?? 'recommended',
              'confidence': itemData['confidence'] ?? 'medium',
            };

            return FoodRecommendation.fromJson(normalizedItem);
          }).toList();
        });
      } else {
        throw Exception(
            response['message'] ?? 'Failed to load recommendations');
      }
    } catch (err) {
      print('Error loading recommendations: $err');
      setState(() {
        _error = err.toString();
      });

      // Fallback to popular items
      try {
        final fallbackResponse =
            await RecommendationService.getPopularFoodItems(
                count: widget.maxItems);
        if (fallbackResponse['success'] == true) {
          final items = fallbackResponse['popularItems'] ?? [];
          setState(() {
            _recommendations = items.map<FoodRecommendation>((item) {
              // Handle both nested and flat structures
              final itemData = item is Map<String, dynamic> ? item : {};

              // Create a normalized structure for FoodRecommendation
              final normalizedItem = {
                '_id': itemData['_id'] ?? itemData['menuItemId'] ?? '',
                'menuItemId': itemData['menuItemId'] ?? itemData['_id'] ?? '',
                'name': itemData['name'] ?? '',
                'description': itemData['description'] ?? '',
                'price': itemData['price'] ?? 0,
                'category': itemData['category'] ?? '',
                'image': itemData['image'] ?? '',
                'availability': itemData['availability'] ?? true,
                'cuisine': itemData['cuisine'] ?? 'Pakistani',
                'spiceLevel': itemData['spiceLevel'] ?? 'mild',
                'dietaryTags': itemData['dietaryTags'] ?? [],
                'preparationTime': itemData['preparationTime'],
                'averageRating': itemData['averageRating'] ?? 4.0,
                'totalRatings': itemData['totalRatings'] ?? 0,
                'score': itemData['score'] ?? itemData['averageRating'] ?? 4.0,
                'reason': itemData['reason'] ?? 'popular',
                'confidence': itemData['confidence'] ?? 'medium',
              };

              return FoodRecommendation.fromJson(normalizedItem);
            }).toList();
            _error = 'Showing popular items instead';
          });
        }
      } catch (fallbackErr) {
        print('Fallback also failed: $fallbackErr');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadRecommendations();
    setState(() {
      _isRefreshing = false;
    });
  }

  void _handleAddToCart(FoodRecommendation recommendation) {
    // Record view interaction
    RecommendationService.recordFoodInteraction(
      menuItemId: recommendation.menuItemId,
      interactionType: 'view',
    );

    if (widget.onAddToCart != null) {
      widget.onAddToCart!(recommendation.toJson());
    }
  }

  void _handleRate(String menuItemId, int rating) {
    RecommendationService.recordFoodInteraction(
      menuItemId: menuItemId,
      interactionType: 'rating',
      rating: rating,
    );

    if (widget.onRate != null) {
      widget.onRate!(menuItemId, rating);
    }

    // Refresh recommendations after rating
    _loadRecommendations();
  }

  String _getTabTitle() {
    switch (_activeTab) {
      case 'personalized':
        return 'Recommended for You';
      case 'popular':
        return 'Most Popular Items';
      default:
        return 'Recommendations';
    }
  }

  String _getTabSubtitle() {
    switch (_activeTab) {
      case 'personalized':
        return 'AI-powered recommendations based on your preferences';
      case 'popular':
        return 'Customer favorites and trending dishes';
      default:
        return 'Discover delicious food recommendations';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading && _recommendations.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF64FFDA).withValues(alpha: 0.05),
              const Color(0xFF4FD1C7).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF64FFDA).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64FFDA)),
              ),
              SizedBox(height: 12),
              Text(
                'Loading delicious recommendations...',
                style: TextStyle(
                  color: Color(0xFF64FFDA),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF64FFDA).withValues(alpha: 0.05),
            const Color(0xFF4FD1C7).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF64FFDA).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            // Title Section
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF64FFDA),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getTabTitle(),
                        style: const TextStyle(
                          color: Color(0xFF64FFDA),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTabSubtitle(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Tab Navigation
                  _buildTabNavigation(theme),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Error Display
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recommendations Content
          if (_recommendations.isEmpty && !_isLoading)
            _buildEmptyState(theme)
          else
            _buildRecommendationsGrid(theme),
        ],
      ),
    );
  }

  Widget _buildTabNavigation(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTabButton(
          'personalized',
          'For You',
          Icons.person,
          theme,
        ),
        const SizedBox(width: 8),
        _buildTabButton(
          'popular',
          'Trending',
          Icons.trending_up,
          theme,
        ),
        const SizedBox(width: 8),
        _buildRefreshButton(theme),
      ],
    );
  }

  Widget _buildTabButton(
      String tab, String label, IconData icon, ThemeData theme) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tab;
        });
        _loadRecommendations();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF64FFDA), Color(0xFF4FD1C7)],
                )
              : null,
          color: isActive ? null : Colors.white.withValues(alpha: 0.1),
          border: isActive
              ? null
              : Border.all(
                  color: const Color(0xFF64FFDA).withValues(alpha: 0.3),
                ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF64FFDA).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isActive ? const Color(0xFF0A192F) : const Color(0xFF64FFDA),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF0A192F)
                    : const Color(0xFF64FFDA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton(ThemeData theme) {
    return GestureDetector(
      onTap: _isRefreshing ? null : _handleRefresh,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: const Color(0xFF64FFDA).withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRotation(
              turns: _isRefreshing ? 1 : 0,
              duration: const Duration(seconds: 1),
              child: const Icon(
                Icons.refresh,
                size: 14,
                color: Color(0xFF64FFDA),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Refresh',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _isRefreshing
                    ? const Color(0xFF64FFDA).withValues(alpha: 0.6)
                    : const Color(0xFF64FFDA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: Color(0xFF64FFDA),
            ),
            const SizedBox(height: 16),
            const Text(
              'No recommendations available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start ordering to get personalized suggestions!',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.explore, size: 16),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64FFDA),
                foregroundColor: const Color(0xFF0A192F),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsGrid(ThemeData theme) {
    return Column(
      children: [
        // Recommendations Grid
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount:
                _recommendations.length > 6 ? 6 : _recommendations.length,
            itemBuilder: (context, index) {
              final recommendation = _recommendations[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < _recommendations.length - 1 ? 16 : 0,
                ),
                child: _buildRecommendationCard(
                  context,
                  theme,
                  recommendation,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        // View All Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RecommendationsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('View All Recommendations'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: const Color(0xFF0A192F),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    ThemeData theme,
    FoodRecommendation recommendation,
  ) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF64FFDA).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64FFDA).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Container(
                  height: 140,
                  width: 220,
                  decoration: BoxDecoration(
                    image: (recommendation.image?.isNotEmpty ?? false)
                        ? DecorationImage(
                            image: NetworkImage(recommendation.image!),
                            fit: BoxFit.cover,
                            onError: (error, stackTrace) {
                              // Handle image loading error
                            },
                          )
                        : null,
                    color: const Color(0xFF2A3441),
                  ),
                  child: (recommendation.image?.isEmpty ?? true)
                      ? const Center(
                          child: Icon(
                            Icons.restaurant,
                            color: Color(0xFF64FFDA),
                            size: 32,
                          ),
                        )
                      : null,
                ),
                // Confidence Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF64FFDA), Color(0xFF4FD1C7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF64FFDA).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${(recommendation.score * 100).toInt()}%',
                      style: const TextStyle(
                        color: Color(0xFF0A192F),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Price Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A192F).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF64FFDA).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Rs. ${recommendation.price}',
                      style: const TextStyle(
                        color: Color(0xFF64FFDA),
                        fontSize: 11,
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    recommendation.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    recommendation.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Tags Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // Cuisine Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64FFDA).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFF64FFDA).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          recommendation.cuisine ?? 'Pakistani',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64FFDA),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Spice Level Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSpiceLevelColor(
                                  recommendation.spiceLevel ?? 'mild')
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getSpiceLevelColor(
                                    recommendation.spiceLevel ?? 'mild')
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _getSpiceLevelText(
                              recommendation.spiceLevel ?? 'mild'),
                          style: TextStyle(
                            fontSize: 10,
                            color: _getSpiceLevelColor(
                                recommendation.spiceLevel ?? 'mild'),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleAddToCart(recommendation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64FFDA),
                        foregroundColor: const Color(0xFF0A192F),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
    );
  }

  // Helper method to get spice level color
  Color _getSpiceLevelColor(String spiceLevel) {
    switch (spiceLevel.toLowerCase()) {
      case 'mild':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hot':
        return Colors.red;
      case 'very_hot':
        return Colors.deepOrange;
      default:
        return Colors.green;
    }
  }

  // Helper method to get spice level text
  String _getSpiceLevelText(String spiceLevel) {
    switch (spiceLevel.toLowerCase()) {
      case 'mild':
        return '🌶️ Mild';
      case 'medium':
        return '🌶️🌶️ Medium';
      case 'hot':
        return '🌶️🌶️🌶️ Hot';
      case 'very_hot':
        return '🌶️🌶️🌶️🌶️ Very Hot';
      default:
        return '🌶️ Mild';
    }
  }
}
