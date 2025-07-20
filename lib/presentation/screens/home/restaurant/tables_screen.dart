import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/table_model.dart';
import '../../../../services/table_service.dart';
import 'table_detail_screen.dart';
import 'table_reservation_screen.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen>
    with SingleTickerProviderStateMixin {
  late List<TableModel> _tables;
  late AnimationController _animationController;

  // Service
  final TableService _tableService = TableService();

  // State variables
  String _selectedLocation = 'All';
  int _selectedCapacity = 0;
  String _searchQuery = '';
  bool _showAvailableOnly = false;
  bool _isLoading = true;
  String? _errorMessage;

  // Reservation date and time
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Load tables data
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tables = await _tableService.getTables();
      setState(() {
        _tables = tables.isNotEmpty ? tables : TableModel.dummyTables();
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      print('Error loading tables: $e');
      setState(() {
        _tables = TableModel.dummyTables();
        _isLoading = false;
        _errorMessage =
            'Could not load tables from server. Using demo data instead.';
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<String> get _locations {
    final locations = _tables.map((table) => table.location).toSet().toList();
    locations.sort();
    return ['All', ...locations];
  }

  List<TableModel> get _filteredTables {
    return _tables.where((table) {
      // Filter by location
      if (_selectedLocation != 'All' && table.location != _selectedLocation) {
        return false;
      }

      // Filter by capacity
      if (_selectedCapacity > 0 && table.capacity < _selectedCapacity) {
        return false;
      }

      // Filter by availability
      if (_showAvailableOnly &&
          (table.status.toLowerCase() != 'available' || table.isReserved)) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty &&
          !table.tableNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) &&
          !table.location.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _findTablesWithAvailability() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Convert TimeOfDay to string format
      final timeString =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      final tables = await _tableService.getTablesWithAvailability(
        date: _selectedDate,
        timeSlot: timeString,
      );

      setState(() {
        _tables = tables.isNotEmpty ? tables : TableModel.dummyTables();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Found ${tables.length} tables for ${DateFormat('EEE, MMM d').format(_selectedDate)} at ${_selectedTime.format(context)}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }

      _animationController.forward();
    } catch (e) {
      print('Error finding tables with availability: $e');
      setState(() {
        _tables = TableModel.dummyTables();
        _isLoading = false;
        _errorMessage =
            'Could not check table availability. Using demo data instead.';
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading tables...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTables,
              color: theme.colorScheme.primary,
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 180.0,
                    floating: false,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text(
                        'Restaurant Tables',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1170&q=80',
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
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
                        ],
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(
                          _showAvailableOnly
                              ? Icons.visibility
                              : Icons.visibility_outlined,
                          color: _showAvailableOnly
                              ? theme.colorScheme.primary
                              : Colors.white,
                        ),
                        tooltip: 'Show available tables only',
                        onPressed: () {
                          setState(() {
                            _showAvailableOnly = !_showAvailableOnly;
                          });
                        },
                      ),
                    ],
                  ),

                  // Error message if any
                  if (_errorMessage != null)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Reservation section
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Make a Reservation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // Date selector
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.3),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            DateFormat('EEE, MMM d')
                                                .format(_selectedDate),
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Time selector
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectTime(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.3),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _selectedTime.format(context),
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _findTablesWithAvailability,
                              icon: const Icon(Icons.search),
                              label: const Text('Find Tables'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search and filter section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search bar
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search tables...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Filters
                          Row(
                            children: [
                              // Location filter
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Location',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surface,
                                  ),
                                  value: _selectedLocation,
                                  items: _locations
                                      .map((location) => DropdownMenuItem(
                                            value: location,
                                            child: Text(location),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedLocation = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Capacity filter
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: 'Capacity',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surface,
                                  ),
                                  value: _selectedCapacity,
                                  items: [0, 2, 4, 6, 8]
                                      .map((capacity) => DropdownMenuItem(
                                            value: capacity,
                                            child: Text(
                                              capacity == 0
                                                  ? 'Any'
                                                  : '$capacity+ Persons',
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedCapacity = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Table count and filter info
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            'Found ${_filteredTables.length} tables',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedLocation != 'All' ||
                              _selectedCapacity > 0 ||
                              _showAvailableOnly)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Wrap(
                                  spacing: 8,
                                  children: [
                                    if (_selectedLocation != 'All')
                                      _buildFilterChip(
                                          'Location: $_selectedLocation'),
                                    if (_selectedCapacity > 0)
                                      _buildFilterChip(
                                          'Min Capacity: $_selectedCapacity'),
                                    if (_showAvailableOnly)
                                      _buildFilterChip('Available Only'),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Tables grid
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: _filteredTables.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.table_bar,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No tables found',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your filters',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final table = _filteredTables[index];
                                return AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    final delay = index * 0.1;
                                    final animation = CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        delay.clamp(0.0, 0.9),
                                        (delay + 0.4).clamp(0.0, 1.0),
                                        curve: Curves.easeOut,
                                      ),
                                    );

                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.2),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _buildTableCard(context, table),
                                );
                              },
                              childCount: _filteredTables.length,
                            ),
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show message to select a table first
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Please select an available table to reserve it.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.colorScheme.primary,
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
                textColor: Colors.white,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Reserve Table'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildTableCard(BuildContext context, TableModel table) {
    final theme = Theme.of(context);

    // Status color
    Color statusColor;
    String statusText;

    switch (table.status.toLowerCase()) {
      case 'available':
        if (table.isReserved) {
          statusColor = Colors.orange;
          statusText = 'Reserved';
        } else {
          statusColor = theme.colorScheme.primary; // Use theme teal color
          statusText = 'Available';
        }
        break;
      case 'occupied':
        statusColor = Colors.red;
        statusText = 'Occupied';
        break;
      case 'maintenance':
        statusColor = Colors.grey;
        statusText = 'Maintenance';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TableDetailScreen(table: table),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table image with status badge
            Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: table.imageUrl != null && table.imageUrl!.isNotEmpty
                      ? Image.network(
                          table.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print(
                                'Error loading table image: ${table.imageUrl} - $error');
                            return Container(
                              color: theme.colorScheme.surface,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Image unavailable',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          color: theme.colorScheme.surface,
                          child: Icon(
                            Icons.table_bar,
                            color: Colors.grey.shade600,
                            size: 48,
                          ),
                        ),
                ),
                // Table number badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      table.tableNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: statusColor.withOpacity(0.9),
                    child: Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Table details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  Text(
                    table.location,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Capacity
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${table.capacity} Person${table.capacity > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),

                  // Reservation info (if reserved)
                  if (table.isReserved && table.reservationTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Reserved: ${DateFormat('MMM d, HH:mm').format(table.reservationTime!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Reserve button
                  if (table.status.toLowerCase() == 'available' &&
                      !table.isReserved)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  TableReservationScreen(table: table),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('RESERVE'),
                      ),
                    ),

                  // View Details button for non-available tables
                  if (table.status.toLowerCase() != 'available' ||
                      table.isReserved)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TableDetailScreen(table: table),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          side: BorderSide(color: theme.colorScheme.primary),
                        ),
                        child: const Text('VIEW DETAILS'),
                      ),
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

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
