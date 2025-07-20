import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../services/order_service.dart' as order_service_lib;
import '../../../data/models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final order_service_lib.OrderService _orderService =
      order_service_lib.OrderService();
  List<OrderModel> _orders = [];
  List<OrderModel> _filteredOrders = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = [
    'all',
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'out_for_delivery',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _orderService.initialize();
    _loadOrders();
    _searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // For now, use dummy data since the service returns a different OrderModel type
      // TODO: Fix the OrderModel type conflict between service and data models
      setState(() {
        _orders = _createDummyOrders();
        _filteredOrders = _orders;
        _isLoading = false;
      });
      _filterOrders();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Fallback to dummy data for development
        _orders = _createDummyOrders();
        _filteredOrders = _orders;
      });
      _filterOrders();
    }
  }

  List<OrderModel> _createDummyOrders() {
    return OrderModel.dummyOrders();
  }

  void _filterOrders() {
    setState(() {
      _filteredOrders = _orders.where((order) {
        final matchesSearch = _searchController.text.isEmpty ||
            order.id
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            order.items.any((item) => item.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()));

        final matchesFilter = _selectedFilter == 'all' ||
            order.status.toLowerCase() == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _updateOrderStatus(OrderModel order, String newStatus) async {
    try {
      final result = await _orderService.updateOrderStatus(order.id, newStatus);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Order status updated to ${_getStatusDisplayText(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated ||
        authProvider.currentUser?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Orders'),
        ),
        body: const Center(
          child: Text('Access denied. Admin privileges required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label:
                              Text(_getStatusDisplayText(filter).toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                            _filterOrders();
                          },
                          selectedColor:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          checkmarkColor: theme.colorScheme.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading orders...')
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading orders',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadOrders,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No orders found',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.isNotEmpty ||
                                          _selectedFilter != 'all'
                                      ? 'Try adjusting your search or filter'
                                      : 'No orders available',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadOrders,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = _filteredOrders[index];
                                return _buildOrderCard(order);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;

    switch (order.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 'preparing':
        statusColor = Colors.purple;
        statusIcon = Icons.restaurant;
        break;
      case 'ready':
        statusColor = Colors.green;
        statusIcon = Icons.done;
        break;
      case 'out_for_delivery':
        statusColor = Colors.teal;
        statusIcon = Icons.delivery_dining;
        break;
      case 'delivered':
        statusColor = Colors.green;
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusDisplayText(order.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Order Items
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: order.items
                  .take(2)
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${item.quantity}x ${item.name}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ))
                  .toList(),
            ),
            if (order.items.length > 2)
              Text(
                '... and ${order.items.length - 2} more item${order.items.length - 2 > 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),

            const SizedBox(height: 8),

            // Order Details
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(order.orderTime),
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Delivery Address
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress ?? 'No address',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // ETA
            if (order.deliveryTime != null && order.status != 'delivered') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ETA: ${DateFormat('hh:mm a').format(order.deliveryTime!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            // Action Buttons
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (order.status.toLowerCase() == 'pending') ...[
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus(order, 'confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Confirm'),
                  ),
                  OutlinedButton(
                    onPressed: () => _updateOrderStatus(order, 'cancelled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
                if (order.status.toLowerCase() == 'confirmed') ...[
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus(order, 'preparing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Start Preparing'),
                  ),
                ],
                if (order.status.toLowerCase() == 'preparing') ...[
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus(order, 'ready'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Mark Ready'),
                  ),
                ],
                if (order.status.toLowerCase() == 'ready') ...[
                  ElevatedButton(
                    onPressed: () =>
                        _updateOrderStatus(order, 'out_for_delivery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Out for Delivery'),
                  ),
                ],
                if (order.status.toLowerCase() == 'out_for_delivery') ...[
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus(order, 'delivered'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Mark Delivered'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
