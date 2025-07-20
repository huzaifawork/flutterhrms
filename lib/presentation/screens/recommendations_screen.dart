import 'package:flutter/material.dart';
import '../../models/recommendation_model.dart';
import '../../services/recommendation_service.dart';
import '../widgets/recommendation_card.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<FoodRecommendation> _foodRecommendations = [];
  List<TableRecommendation> _tableRecommendations = [];
  bool _isLoadingFood = false;
  bool _isLoadingTables = false;
  String _selectedCuisine = 'All';
  String _selectedOccasion = 'Casual';
  int _partySize = 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFoodRecommendations();
    _loadTableRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodRecommendations() async {
    setState(() => _isLoadingFood = true);

    try {
      // Debug: Check stored values
      final debugValues = await RecommendationService.debugGetStoredValues();
      print('Debug stored values: $debugValues');

      Map<String, dynamic> response;

      if (_selectedCuisine == 'Pakistani') {
        response = await RecommendationService.getPakistaniFoodRecommendations(
            count: 20);
      } else {
        response =
            await RecommendationService.getFoodRecommendations(count: 20);
      }

      if (response['success'] == true) {
        final recommendations =
            response['recommendations'] ?? response['popularItems'] ?? [];
        setState(() {
          _foodRecommendations = recommendations
              .map<FoodRecommendation>(
                  (item) => FoodRecommendation.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading food recommendations: $e');

      // If user not logged in, try to load popular items instead
      if (e.toString().contains('User not logged in')) {
        try {
          final response =
              await RecommendationService.getPopularFoodItems(count: 20);
          if (response['success'] == true) {
            final recommendations = response['popularItems'] ?? [];
            setState(() {
              _foodRecommendations = recommendations
                  .map<FoodRecommendation>(
                      (item) => FoodRecommendation.fromJson(item))
                  .toList();
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Showing popular items (login for personalized recommendations)')),
              );
            }
            return;
          }
        } catch (popularError) {
          print('Error loading popular items: $popularError');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load food recommendations: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingFood = false);
    }
  }

  Future<void> _loadTableRecommendations() async {
    setState(() => _isLoadingTables = true);

    try {
      final response = await RecommendationService.getTableRecommendations(
        occasion: _selectedOccasion,
        partySize: _partySize,
        numRecommendations: 15,
      );

      if (response['success'] == true) {
        final recommendations =
            response['recommendations'] ?? response['popularTables'] ?? [];
        setState(() {
          _tableRecommendations = recommendations
              .map<TableRecommendation>(
                  (item) => TableRecommendation.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading table recommendations: $e');

      // If user not logged in, try to load popular tables instead
      if (e.toString().contains('User not logged in')) {
        try {
          final response =
              await RecommendationService.getPopularTables(limit: 15);
          if (response['success'] == true) {
            final tables = response['popularTables'] ?? [];
            setState(() {
              _tableRecommendations = tables
                  .map<TableRecommendation>((table) => TableRecommendation(
                        tableId: table['_id'] ?? '',
                        table: TableInfo.fromJson(table),
                        score: (table['score'] ?? 0.8).toDouble(),
                        reason: 'popularity',
                        confidence: 'medium',
                        rank: (table['popularityRank'] ?? 1),
                        explanation: 'Popular table with high ratings',
                      ))
                  .toList();
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Showing popular tables (login for personalized recommendations)')),
              );
            }
            return;
          }
        } catch (popularError) {
          print('Error loading popular tables: $popularError');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load table recommendations: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingTables = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Food'),
            Tab(icon: Icon(Icons.table_restaurant), text: 'Tables'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFoodRecommendationsTab(),
          _buildTableRecommendationsTab(),
        ],
      ),
    );
  }

  Widget _buildFoodRecommendationsTab() {
    return Column(
      children: [
        // Cuisine Filter
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Cuisine: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedCuisine,
                  isExpanded: true,
                  items:
                      ['All', 'Pakistani', 'Italian', 'Chinese', 'Continental']
                          .map((cuisine) => DropdownMenuItem(
                                value: cuisine,
                                child: Text(cuisine),
                              ))
                          .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCuisine = value!);
                    _loadFoodRecommendations();
                  },
                ),
              ),
            ],
          ),
        ),

        // Food Recommendations List
        Expanded(
          child: _isLoadingFood
              ? const Center(child: CircularProgressIndicator())
              : _foodRecommendations.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No food recommendations available',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFoodRecommendations,
                      child: ListView.builder(
                        itemCount: _foodRecommendations.length,
                        itemBuilder: (context, index) {
                          final recommendation = _foodRecommendations[index];
                          return FoodRecommendationCard(
                            recommendation: recommendation,
                            onTap: () {
                              // Navigate to food details
                              _showFoodDetails(recommendation);
                            },
                            onAddToCart: () {
                              // Add to cart logic
                              _addToCart(recommendation);
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTableRecommendationsTab() {
    return Column(
      children: [
        // Table Filters
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Occasion: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedOccasion,
                      isExpanded: true,
                      items: [
                        'Casual',
                        'Romantic',
                        'Business',
                        'Family',
                        'Friends',
                        'Celebration'
                      ]
                          .map((occasion) => DropdownMenuItem(
                                value: occasion,
                                child: Text(occasion),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedOccasion = value!);
                        _loadTableRecommendations();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Party Size: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Slider(
                      value: _partySize.toDouble(),
                      min: 1,
                      max: 12,
                      divisions: 11,
                      label: '$_partySize people',
                      onChanged: (value) {
                        setState(() => _partySize = value.round());
                      },
                      onChangeEnd: (value) {
                        _loadTableRecommendations();
                      },
                    ),
                  ),
                  Text('$_partySize'),
                ],
              ),
            ],
          ),
        ),

        // Table Recommendations List
        Expanded(
          child: _isLoadingTables
              ? const Center(child: CircularProgressIndicator())
              : _tableRecommendations.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.table_restaurant,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No table recommendations available',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTableRecommendations,
                      child: ListView.builder(
                        itemCount: _tableRecommendations.length,
                        itemBuilder: (context, index) {
                          final recommendation = _tableRecommendations[index];
                          return TableRecommendationCard(
                            recommendation: recommendation,
                            onTap: () {
                              // Navigate to table details
                              _showTableDetails(recommendation);
                            },
                            onReserve: () {
                              // Reserve table logic
                              _reserveTable(recommendation);
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  void _showFoodDetails(FoodRecommendation recommendation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recommendation.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                recommendation.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Price: Rs. ${recommendation.price.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
              const SizedBox(height: 16),
              if (recommendation.averageRating != null) ...[
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${recommendation.averageRating!.toStringAsFixed(1)} / 5.0',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addToCart(recommendation);
                },
                child: const Text('Add to Cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTableDetails(TableRecommendation recommendation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recommendation.table.tableName,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Capacity: ${recommendation.table.capacity} people',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Location: ${recommendation.table.location}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                recommendation.explanation,
                style:
                    const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _reserveTable(recommendation);
                },
                child: const Text('Reserve Table'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(FoodRecommendation recommendation) {
    // Record order interaction
    RecommendationService.recordFoodInteraction(
      menuItemId: recommendation.menuItemId,
      interactionType: 'order',
      orderQuantity: 1,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${recommendation.name} added to cart')),
    );
  }

  void _reserveTable(TableRecommendation recommendation) {
    // Record booking interaction
    RecommendationService.recordTableInteraction(
      tableId: recommendation.tableId,
      interactionType: 'booking',
      context: {
        'occasion': _selectedOccasion,
        'partySize': _partySize,
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('${recommendation.table.tableName} reservation initiated')),
    );
  }
}
