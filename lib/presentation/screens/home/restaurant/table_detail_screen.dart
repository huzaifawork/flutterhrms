import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/table_model.dart';
import '../../../providers/auth_provider.dart';
import '../../reservations/table_reservation_screen.dart';

class TableDetailScreen extends StatelessWidget {
  final TableModel table;

  const TableDetailScreen({
    super.key,
    required this.table,
  });

  @override
  Widget build(BuildContext context) {
    // Get status color based on table status
    Color statusColor;
    switch (table.status.toLowerCase()) {
      case 'available':
        statusColor = table.isReserved ? Colors.orange : Colors.green;
        break;
      case 'occupied':
        statusColor = Colors.red;
        break;
      case 'maintenance':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with table image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Table image
                  table.imageUrl != null
                      ? Image.network(
                          table.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.table_bar,
                            size: 100,
                            color: Colors.white,
                          ),
                        ),
                  // Gradient overlay for better text visibility
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black45,
                        ],
                        stops: [0.7, 1.0],
                      ),
                    ),
                  ),
                  // Status badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        table.isReserved
                            ? 'Reserved'
                            : table.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Table details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table number and location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Table ${table.tableNumber}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          table.location,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Capacity and availability
                  Row(
                    children: [
                      _buildInfoItem(
                        context,
                        Icons.people,
                        'Capacity',
                        '${table.capacity} ${table.capacity > 1 ? 'Persons' : 'Person'}',
                      ),
                      const SizedBox(width: 24),
                      _buildInfoItem(
                        context,
                        Icons.event_available,
                        'Availability',
                        table.isReserved ? 'Reserved' : table.status,
                        color: statusColor,
                      ),
                    ],
                  ),

                  // Reservation details if reserved
                  if (table.isReserved && table.reservationTime != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Reservation',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildReservationDetail(
                              context,
                              'Reserved By',
                              table.reservedBy ?? 'Unknown',
                              Icons.person,
                            ),
                            const SizedBox(height: 8),
                            _buildReservationDetail(
                              context,
                              'Time',
                              DateFormat('E, MMM d, yyyy h:mm a')
                                  .format(table.reservationTime!),
                              Icons.access_time,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Features and amenities
                  const SizedBox(height: 24),
                  Text(
                    'Features',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getTableFeatures(table).map((feature) {
                      return Chip(
                        label: Text(feature),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),

                  // Description
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTableDescription(table),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  // Similar tables
                  const SizedBox(height: 24),
                  Text(
                    'Similar Tables',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          5, // Dummy data - in a real app, we'd have similar tables
                      itemBuilder: (context, index) {
                        return Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.table_bar, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Table T${index + 6}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${table.capacity} Persons',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 100), // Space for the bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: (table.status == 'available' && !table.isReserved)
          ? FloatingActionButton.extended(
              onPressed: () {
                final user =
                    Provider.of<AuthProvider>(context, listen: false).user;
                if (user != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TableReservationScreen(table: table),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please login to reserve a table'),
                    ),
                  );
                }
              },
              label: const Text('Reserve Table'),
              icon: const Icon(Icons.book_online),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReservationDetail(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper method to get table features based on location and capacity
  List<String> _getTableFeatures(TableModel table) {
    final features = <String>[];

    // Add features based on location
    if (table.location.toLowerCase().contains('window')) {
      features.add('Window View');
    }
    if (table.location.toLowerCase().contains('balcony')) {
      features.add('Outdoor Seating');
    }
    if (table.location.toLowerCase().contains('private')) {
      features.add('Private Area');
    }
    if (table.location.toLowerCase().contains('center')) {
      features.add('Central Location');
    }

    // Add features based on capacity
    if (table.capacity >= 6) {
      features.add('Large Group');
    }
    if (table.capacity <= 2) {
      features.add('Intimate Setting');
    }

    // Add some default features
    features.add('Comfortable Chairs');
    features.add('Table Service');

    return features;
  }

  // Helper method to get table description
  String _getTableDescription(TableModel table) {
    switch (table.location.toLowerCase()) {
      case 'window':
        return 'Enjoy your meal with a beautiful view from our window-side table. Perfect for a ${table.capacity <= 2 ? 'romantic dinner' : 'family gathering'} with comfortable seating and excellent service.';
      case 'balcony':
        return 'Experience dining under the stars on our beautiful balcony. This table offers a unique outdoor dining experience with a breathtaking view, perfect for ${table.capacity <= 2 ? 'couples' : 'groups'}.';
      case 'private room':
        return 'Our private room offers an exclusive dining experience for your group. With dedicated staff and a secluded atmosphere, it\'s perfect for special occasions and meetings.';
      case 'center':
        return 'Located in the heart of our restaurant, this table puts you in the center of the vibrant dining atmosphere. Enjoy the buzz of the restaurant while savoring your meal.';
      default:
        return 'This table offers a comfortable dining experience in our restaurant. With professional service and a welcoming atmosphere, it\'s a perfect spot to enjoy your meal.';
    }
  }
}
