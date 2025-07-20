import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/recommendation_service.dart';
import '../models/table_model.dart';
import '../data/models/table_model.dart' as data_table;
import '../presentation/screens/reservations/table_reservation_screen.dart';

class FeaturedTablesWidget extends StatefulWidget {
  const FeaturedTablesWidget({Key? key}) : super(key: key);

  @override
  State<FeaturedTablesWidget> createState() => _FeaturedTablesWidgetState();
}

class _FeaturedTablesWidgetState extends State<FeaturedTablesWidget> {
  List<TableModel> _tables = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeaturedTables();
  }

  Future<void> _loadFeaturedTables() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final response = await RecommendationService.getTableRecommendations(
        userId: userId,
        occasion: 'casual',
        partySize: 2,
        timeSlot: 'evening',
        numRecommendations: 3, // Show only 3 tables like website
      );

      if (response['success'] == true) {
        final List<dynamic> tablesData = response['recommendations'] ??
            response['popularTables'] ??
            response['tables'] ??
            [];

        setState(() {
          _tables = tablesData.map((data) {
            // Handle both recommendation format and direct table format
            final tableData = data['table'] ?? data;
            return TableModel.fromJson(tableData);
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load featured tables';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading featured tables: $e';
        _isLoading = false;
      });
    }
  }

  String _getRecommendationBadge(String? reason) {
    switch (reason) {
      case 'collaborative_filtering':
        return 'Similar Users';
      case 'content_based':
        return 'Your Taste';
      case 'popularity':
        return 'Trending';
      case 'contextual':
        return 'Perfect Match';
      default:
        return 'Featured';
    }
  }

  Color _getBadgeColor(String? reason) {
    switch (reason) {
      case 'collaborative_filtering':
        return Colors.green;
      case 'content_based':
        return Colors.blue;
      case 'popularity':
        return Colors.orange;
      case 'contextual':
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: const Text(
                'Featured Tables',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Content
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_tables.isEmpty)
            _buildEmptyState()
          else
            _buildTablesGrid(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 300,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load tables',
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeaturedTables,
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
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant_outlined, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No featured tables available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablesGrid() {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tables.length,
        itemBuilder: (context, index) {
          final table = _tables[index];
          return Container(
            width: 280,
            margin: EdgeInsets.only(right: index < _tables.length - 1 ? 16 : 0),
            child: _buildTableCard(table),
          );
        },
      ),
    );
  }

  Widget _buildTableCard(TableModel table) {
    return GestureDetector(
      onTap: () {
        // Record interaction
        RecommendationService.recordTableInteraction(
          tableId: table.id,
          interactionType: 'view',
        );

        // Navigate to table reservation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TableReservationScreen(table: _convertToDataTableModel(table)),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E293B),
              const Color(0xFF334155),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Table Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: table.image != null
                  ? Image.network(
                      table.image!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.table_restaurant,
                              size: 64, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.table_restaurant,
                          size: 64, color: Colors.grey),
                    ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Status Badge
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      table.status == 'Available' ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      table.status == 'Available'
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      table.status,
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

            // Table Details
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.tableName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      table.tableType ?? 'Standard Table',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFeatureIcon(
                            Icons.people, '${table.capacity} Guests'),
                        const SizedBox(width: 16),
                        _buildFeatureIcon(
                            Icons.location_on, table.location ?? 'Main Hall'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: table.status == 'Available'
                            ? () {
                                // Navigate to reservation
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TableReservationScreen(
                                            table: _convertToDataTableModel(
                                                table)),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: table.status == 'Available'
                              ? const Color(0xFF6366F1)
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          table.status == 'Available'
                              ? 'RESERVE TABLE'
                              : 'UNAVAILABLE',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  data_table.TableModel _convertToDataTableModel(TableModel table) {
    return data_table.TableModel(
      id: table.id,
      tableNumber: table.tableName,
      capacity: table.capacity,
      location: table.location ?? 'Main Hall',
      status: table.status,
      imageUrl: table.image,
    );
  }
}
