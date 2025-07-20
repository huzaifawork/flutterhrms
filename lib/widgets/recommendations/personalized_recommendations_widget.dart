import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/recommendation_service.dart';
import '../../data/models/menu_item_model.dart';
import '../../presentation/providers/auth_provider.dart';
import '../menu/menu_item_card.dart';

class PersonalizedRecommendationsWidget extends StatefulWidget {
  final int maxItems;
  final Function(MenuItemModel)? onAddToCart;
  final Function(String, double)? onRate;
  final bool showHeader;

  const PersonalizedRecommendationsWidget({
    super.key,
    this.maxItems = 8,
    this.onAddToCart,
    this.onRate,
    this.showHeader = true,
  });

  @override
  State<PersonalizedRecommendationsWidget> createState() =>
      _PersonalizedRecommendationsWidgetState();
}

class _PersonalizedRecommendationsWidgetState
    extends State<PersonalizedRecommendationsWidget>
    with SingleTickerProviderStateMixin {
  final RecommendationService _recommendationService = RecommendationService();

  List<MenuItemModel> _recommendations = [];
  bool _loading = true;
  String? _error;
  String _activeTab = 'personalized';
  bool _refreshing = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      final isLoggedIn = authProvider.isAuthenticated;

      List<MenuItemModel> recommendations;

      switch (_activeTab) {
        case 'personalized':
          if (isLoggedIn && userId != null) {
            try {
              recommendations = await _recommendationService
                  .getPersonalizedRecommendations(userId, widget.maxItems);
            } catch (personalizedError) {
              print(
                  'Personalized recommendations failed, using popular items: $personalizedError');
              recommendations =
                  await _recommendationService.getPopularItems(widget.maxItems);
            }
          } else {
            recommendations =
                await _recommendationService.getPopularItems(widget.maxItems);
          }
          break;
        case 'popular':
          recommendations =
              await _recommendationService.getPopularItems(widget.maxItems);
          break;
        default:
          recommendations =
              await _recommendationService.getPopularItems(widget.maxItems);
      }

      setState(() {
        _recommendations = recommendations;
        _loading = false;
      });
    } catch (err) {
      print('Error loading recommendations: $err');
      setState(() {
        _error = err.toString();
        _loading = false;
      });

      // Fallback to popular items
      try {
        final fallbackRecommendations =
            await _recommendationService.getPopularItems(widget.maxItems);
        setState(() {
          _recommendations = fallbackRecommendations;
          _error = 'Showing popular items instead';
        });
      } catch (fallbackErr) {
        print('Fallback also failed: $fallbackErr');
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshing = true;
    });
    await _loadRecommendations();
    setState(() {
      _refreshing = false;
    });
  }

  void _handleAddToCart(MenuItemModel menuItem) {
    // Record view interaction
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.user?.id != null) {
      _recommendationService
          .recordInteraction(
            authProvider.user!.id,
            menuItem.id,
            'view',
          )
          .catchError((error) => print('Error recording interaction: $error'));
    }

    if (widget.onAddToCart != null) {
      widget.onAddToCart!(menuItem);
    }
  }

  void _handleRate(String menuItemId, double rating) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.user?.id != null) {
      _recommendationService
          .rateMenuItemInstance(
        authProvider.user!.id,
        menuItemId,
        rating,
      )
          .then((_) {
        // Refresh recommendations after rating
        _loadRecommendations();
      }).catchError((error) => print('Error rating item: $error'));
    }

    if (widget.onRate != null) {
      widget.onRate!(menuItemId, rating);
    }
  }

  String _getTabTitle() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isAuthenticated;

    switch (_activeTab) {
      case 'personalized':
        return isLoggedIn ? 'Recommended for You' : 'Popular Items';
      case 'popular':
        return 'Most Popular Items';
      default:
        return 'Recommendations';
    }
  }

  String _getTabSubtitle() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isAuthenticated;

    switch (_activeTab) {
      case 'personalized':
        return isLoggedIn
            ? 'AI-powered recommendations based on your preferences'
            : 'Discover our most loved dishes';
      case 'popular':
        return 'Customer favorites and trending dishes';
      default:
        return 'Discover delicious food recommendations';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;

    if (_loading && _recommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading delicious recommendations...'),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            // Title Section
            Row(
              children: [
                Icon(
                  _activeTab == 'personalized'
                      ? Icons.person
                      : Icons.trending_up,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getTabTitle(),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _refreshing ? null : _handleRefresh,
                  icon: _refreshing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.refresh,
                          color: theme.colorScheme.primary,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getTabSubtitle(),
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Tab Navigation
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (index) {
                  setState(() {
                    _activeTab = index == 0 ? 'personalized' : 'popular';
                  });
                  _loadRecommendations();
                },
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: theme.colorScheme.primary,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.primary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 4),
                        Text(isLoggedIn ? 'For You' : 'Popular'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, size: 16),
                        SizedBox(width: 4),
                        Text('Trending'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Error Message
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style:
                          const TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

          // Recommendations Grid
          if (_recommendations.isEmpty && !_loading)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recommendations available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLoggedIn
                        ? "Start ordering to get personalized recommendations!"
                        : "Sign in to get personalized food recommendations",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleRefresh,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final recommendation = _recommendations[index];
                return MenuItemCard(
                  menuItem: recommendation,
                  onAddToCart: () => _handleAddToCart(recommendation),
                  onRate: (rating) => _handleRate(recommendation.id, rating),
                  showReason: _activeTab == 'personalized' && isLoggedIn,
                  showConfidence: _activeTab == 'personalized' && isLoggedIn,
                );
              },
            ),
        ],
      ),
    );
  }
}
