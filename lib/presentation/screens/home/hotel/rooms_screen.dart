import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_utils.dart';
import '../../../../data/models/room_model.dart';
import '../../../../services/room_service.dart';
import 'room_detail_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> with SingleTickerProviderStateMixin {
  late List<RoomModel> _rooms;
  late List<RoomModel> _filteredRooms;
  
  // Filter states
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Available', 'Occupied', 'Maintenance'];
  String _searchQuery = '';
  String _selectedRoomType = 'All';
  List<String> _roomTypes = ['All'];
  int _minCapacity = 0;
  String _sortBy = 'price_asc';
  
  // Date range selection
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Animation controller
  late AnimationController _animationController;
  
  // Text editing controller
  final TextEditingController _searchController = TextEditingController();
  
  // Room service
  final RoomService _roomService = RoomService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _loadRooms();
  }
  
  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final rooms = await _roomService.getRooms();
      setState(() {
        _rooms = rooms.isNotEmpty ? rooms : RoomModel.dummyRooms();
        _filteredRooms = List.from(_rooms);
        
        // Extract unique room types
        _roomTypes = ['All', ..._rooms.map((room) => room.roomType).toSet().toList()];
        _roomTypes.sort((a, b) => a.compareTo(b));
      });
    } catch (e) {
      print('Error loading rooms: $e');
      setState(() {
        _rooms = RoomModel.dummyRooms();
        _filteredRooms = List.from(_rooms);
        
        // Extract unique room types
        _roomTypes = ['All', ..._rooms.map((room) => room.roomType).toSet().toList()];
        _roomTypes.sort((a, b) => a.compareTo(b));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      // Start animation
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterRooms() {
    setState(() {
      _filteredRooms = _rooms.where((room) {
        // Filter by status
        if (_selectedFilter != 'All' && 
            room.status.toLowerCase() != _selectedFilter.toLowerCase()) {
          return false;
        }
        
        // Filter by room type
        if (_selectedRoomType != 'All' && 
            room.roomType.toLowerCase() != _selectedRoomType.toLowerCase()) {
          return false;
        }
        
        // Filter by capacity
        if (_minCapacity > 0 && room.capacity < _minCapacity) {
          return false;
        }
        
        // Filter by search query
        if (_searchQuery.isNotEmpty &&
            !room.roomNumber.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !room.roomType.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !room.description!.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
        
        return true;
      }).toList();
      
      // Sort rooms
      _sortRooms();
    });
  }
  
  void _sortRooms() {
    switch(_sortBy) {
      case 'price_asc':
        _filteredRooms.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
        break;
      case 'price_desc':
        _filteredRooms.sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));
        break;
      case 'capacity_asc':
        _filteredRooms.sort((a, b) => a.capacity.compareTo(b.capacity));
        break;
      case 'capacity_desc':
        _filteredRooms.sort((a, b) => b.capacity.compareTo(a.capacity));
        break;
    }
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now(),
      end: _endDate ?? DateTime.now().add(const Duration(days: 7)),
    );
    
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.secondary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (dateRange != null) {
      setState(() {
        _startDate = dateRange.start;
        _endDate = dateRange.end;
      });
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
                    'Loading rooms...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 180.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Rooms',
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
                          'https://images.unsplash.com/photo-1618773928121-c32242e63f39?ixlib=rb-4.0.3&auto=format&fit=crop&w=1170&q=80',
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
                      icon: const Icon(
                        Icons.filter_list,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _showFilterBottomSheet(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.date_range,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _selectDateRange(context);
                      },
                    ),
                  ],
                ),
                
                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search rooms...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                      _filterRooms();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _filterRooms();
                          },
                        ),
                        
                        // Date range selection
                        if (_startDate != null && _endDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.date_range,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _startDate = null;
                                        _endDate = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Filter chips
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: _filters.map((filter) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: _selectedFilter == filter,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                                _filterRooms();
                              }
                            },
                            backgroundColor: theme.colorScheme.surface,
                            selectedColor: theme.colorScheme.primary,
                            labelStyle: TextStyle(
                              color: _selectedFilter == filter
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                // Room stats
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        _buildStatCard(
                          context,
                          'Total',
                          _rooms.length.toString(),
                          theme.colorScheme.primary,
                        ),
                        _buildStatCard(
                          context,
                          'Available',
                          _rooms.where((room) => room.status.toLowerCase() == 'available').length.toString(),
                          Colors.green,
                        ),
                        _buildStatCard(
                          context,
                          'Occupied',
                          _rooms.where((room) => room.status.toLowerCase() == 'occupied').length.toString(),
                          Colors.orange,
                        ),
                        _buildStatCard(
                          context,
                          'Maintenance',
                          _rooms.where((room) => room.status.toLowerCase() == 'maintenance').length.toString(),
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Sorting dropdown
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_filteredRooms.length} Rooms',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _sortBy,
                            icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                            elevation: 16,
                            underline: Container(height: 0),
                            onChanged: (String? newValue) {
                              setState(() {
                                _sortBy = newValue!;
                                _sortRooms();
                              });
                            },
                            dropdownColor: theme.colorScheme.surface,
                            items: <String>[
                              'price_asc',
                              'price_desc',
                              'capacity_asc',
                              'capacity_desc',
                            ].map<DropdownMenuItem<String>>((String value) {
                              String label = '';
                              switch (value) {
                                case 'price_asc':
                                  label = 'Price: Low to High';
                                  break;
                                case 'price_desc':
                                  label = 'Price: High to Low';
                                  break;
                                case 'capacity_asc':
                                  label = 'Capacity: Low to High';
                                  break;
                                case 'capacity_desc':
                                  label = 'Capacity: High to Low';
                                  break;
                              }
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(label),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Room list
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: _filteredRooms.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 40),
                                Icon(
                                  Icons.hotel_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No rooms found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
                      : SliverAnimatedList(
                          initialItemCount: _filteredRooms.length,
                          itemBuilder: (context, index, animation) {
                            final room = _filteredRooms[index];
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              )),
                              child: FadeTransition(
                                opacity: animation,
                                child: _buildRoomCard(context, room),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show a message that user needs to select a room first
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please select a room to book it.'),
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
        label: const Text('Book Room'),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Wrap(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Rooms',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedFilter = 'All';
                            _selectedRoomType = 'All';
                            _minCapacity = 0;
                          });
                          this.setState(() {});
                          _filterRooms();
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Room Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _roomTypes.map((type) {
                      return ChoiceChip(
                        label: Text(type),
                        selected: _selectedRoomType == type,
                        onSelected: (selected) {
                          setState(() {
                            _selectedRoomType = selected ? type : 'All';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Minimum Capacity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [1, 2, 3, 4, 5].map((capacity) {
                      return ChoiceChip(
                        label: Text('$capacity+'),
                        selected: _minCapacity == capacity,
                        onSelected: (selected) {
                          setState(() {
                            _minCapacity = selected ? capacity : 0;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _filterRooms();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, RoomModel room) {
    final theme = Theme.of(context);
    
    // Status indicator color
    Color statusColor;
    switch (room.status.toLowerCase()) {
      case 'available':
        statusColor = theme.colorScheme.primary; // Use theme teal color
        break;
      case 'occupied':
        statusColor = Colors.orange;
        break;
      case 'maintenance':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RoomDetailScreen(room: room),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room image with status badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    room.imageUrls.first,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: theme.colorScheme.surface,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Image not available',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      room.roomNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 5,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            
            // Room details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Room type
                      Text(
                        room.roomType.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '\$${room.pricePerNight.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Room description
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      room.description ?? 'No description available',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Room details (capacity, size, floor)
                  Row(
                    children: [
                      // Capacity
                      _buildRoomDetail(
                        Icons.person,
                        '${room.capacity} Person${room.capacity > 1 ? 's' : ''}',
                        theme,
                      ),
                      const SizedBox(width: 16),
                      // Size
                      _buildRoomDetail(
                        Icons.square_foot,
                        room.size,
                        theme,
                      ),
                      const SizedBox(width: 16),
                      // Floor
                      _buildRoomDetail(
                        Icons.layers,
                        'Floor ${room.floor}',
                        theme,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Amenities chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: room.amenities.take(4).map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          amenity,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  if (room.amenities.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+${room.amenities.length - 4} more',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
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
  
  Widget _buildRoomDetail(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
} 