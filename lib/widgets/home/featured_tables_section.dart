import 'package:flutter/material.dart';
import 'package:hrms_mobile_app/core/config/environment.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../presentation/screens/reservations/table_reservation_page.dart';

class FeaturedTablesSection extends StatefulWidget {
  const FeaturedTablesSection({Key? key}) : super(key: key);

  @override
  State<FeaturedTablesSection> createState() => _FeaturedTablesSectionState();
}

class _FeaturedTablesSectionState extends State<FeaturedTablesSection> {
  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedTables();
  }

  Future<void> _loadFeaturedTables() async {
    print('🔄 Starting to load featured tables...');

    try {
      // Use simple API call to get tables directly
      final response = await http.get(
        Uri.parse('${Environment.currentApiUrl}/api/tables'),
      );

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Featured tables loaded: ${data.length} tables');

        // Take only first 3 tables for featured section
        final featuredTables = data
            .take(3)
            .map<Map<String, dynamic>>((table) => {
                  '_id': table['_id'] ?? '',
                  'tableName': table['tableName'] ?? '',
                  'tableType': table['tableType'] ?? '',
                  'capacity': table['capacity'] ?? 0,
                  'status': table['status'] ?? 'Available',
                  'location': table['location'] ?? '',
                  'image': table['image'] ?? '',
                  'avgRating': table['avgRating'] ?? 4.5,
                  'description': table['description'] ?? '',
                })
            .toList();

        setState(() {
          _tables = featuredTables;
          _isLoading = false;
        });
        print(
            '🎯 State updated - _isLoading: $_isLoading, _tables.length: ${_tables.length}');
      } else {
        print('❌ Response not successful: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('💥 Error loading featured tables: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return 'https://via.placeholder.com/300x200?text=Table';
    }
    if (imagePath.startsWith('http')) return imagePath;
    final cleanPath = imagePath.replaceAll(RegExp(r'^/+'), '');
    return cleanPath.contains('uploads')
        ? '${Environment.currentApiUrl}/$cleanPath'
        : '${Environment.currentApiUrl}/uploads/$cleanPath';
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TableReservationPage(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
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
                  _getImageUrl(table['image']),
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
                    table['tableName'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    table['location'] ?? '',
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
                        (table['avgRating'] ?? 4.5).toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        table['status'] ?? 'Available',
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Tables',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _tables.isEmpty
                  ? const Text('No featured tables available.',
                      style: TextStyle(color: Colors.white))
                  : LayoutBuilder(
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

                        return GridView.builder(
                          itemCount: _tables.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemBuilder: (context, index) {
                            return _buildTableCard(_tables[index]);
                          },
                        );
                      },
                    ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TableReservationPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.table_restaurant),
            label: const Text(
              'View All Tables',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
