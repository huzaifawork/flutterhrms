import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/order_model.dart';
import '../../../services/order_service.dart';
import '../../../services/global_socket_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import 'order_tracking_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final OrderService _orderService = OrderService();
  final GlobalSocketService _globalSocketService = GlobalSocketService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _error;
  Function? _unsubscribeGlobalSocket;

  @override
  void initState() {
    super.initState();
    _orderService.initialize();
    _loadOrders();

    // Subscribe to global socket updates for 5-minute auto-progression
    _unsubscribeGlobalSocket =
        _globalSocketService.subscribeToGlobalUpdates((data) {
      if (mounted && data['orderId'] != null) {
        // Find and update the specific order
        final orderId = data['orderId'];
        final newStatus = data['status'];

        setState(() {
          _orders = _orders.map((order) {
            if (order.id == orderId) {
              return order.copyWith(status: newStatus);
            }
            return order;
          }).toList();
        });

        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Order ${orderId.substring(0, 8)} updated to: $newStatus'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    // Auto-refresh orders every 30 seconds to get latest status from database
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadOrders();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    if (_unsubscribeGlobalSocket != null) {
      _unsubscribeGlobalSocket!();
    }
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _orderService.getUserOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Fallback to dummy data for development
        _orders = _createDummyOrders();
      });
    }
  }

  List<OrderModel> _createDummyOrders() {
    return [
      OrderModel(
        id: '1',
        userId: 'user1',
        items: [
          OrderItemModel(
            menuItemId: '1',
            name: 'Margherita Pizza',
            price: 18.99,
            quantity: 1,
            specialInstructions: 'Well done',
          ),
          OrderItemModel(
            menuItemId: '2',
            name: 'Caesar Salad',
            price: 12.99,
            quantity: 1,
            specialInstructions: null,
          ),
        ],
        status: 'delivered',
        orderTime: DateTime.now().subtract(const Duration(hours: 3)),
        deliveryTime:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        orderType: 'delivery',
        subtotal: 31.98,
        tax: 2.56,
        tip: 0.0,
        deliveryFee: 3.99,
        total: 38.53,
        paymentMethod: 'card',
        paymentId: 'pi_1234567890',
        isPaid: true,
        deliveryAddress: '123 Main St, City, State',
        notes: 'Ring doorbell twice',
      ),
      OrderModel(
        id: '2',
        userId: 'user1',
        items: [
          OrderItemModel(
            menuItemId: '3',
            name: 'Chicken Burger',
            price: 15.99,
            quantity: 2,
            specialInstructions: null,
          ),
        ],
        status: 'preparing',
        orderTime: DateTime.now().subtract(const Duration(minutes: 15)),
        deliveryTime: DateTime.now().add(const Duration(minutes: 25)),
        orderType: 'delivery',
        subtotal: 31.98,
        tax: 2.56,
        tip: 0.0,
        deliveryFee: 3.99,
        total: 38.53,
        paymentMethod: 'cash',
        isPaid: false,
        deliveryAddress: '456 Oak Ave, City, State',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
        ),
        body: const Center(
          child: Text('Please login to view your orders'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading your orders...')
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
              : _orders.isEmpty
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
                            'You haven\'t placed any food orders yet.',
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
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _buildOrderCard(order);
                        },
                      ),
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
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(orderId: order.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
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
                          _getStatusText(order.status),
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

              // Order date
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a')
                        .format(order.orderTime),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Items summary
              Text(
                '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),

              // Show first few items
              const SizedBox(height: 8),
              ...order.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${item.quantity}x ${item.name}',
                      style: theme.textTheme.bodySmall,
                    ),
                  )),
              if (order.items.length > 2)
                Text(
                  '... and ${order.items.length - 2} more item${order.items.length - 2 > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),

              const SizedBox(height: 12),

              // Total amount and delivery info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: \$${order.total.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (order.deliveryTime != null &&
                          _isOrderActive(order.status))
                        Text(
                          'ETA: ${DateFormat('hh:mm a').format(order.deliveryTime!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      if (_isOrderActive(order.status)) ...[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    OrderTrackingScreen(orderId: order.id),
                              ),
                            );
                          },
                          child: const Text('Track'),
                        ),
                      ] else ...[
                        TextButton(
                          onPressed: () {
                            // TODO: Implement reorder functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reorder feature coming soon'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          child: const Text('Reorder'),
                        ),
                      ],
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isOrderActive(String status) {
    return ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery']
        .contains(status.toLowerCase());
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'confirmed':
        return 'CONFIRMED';
      case 'preparing':
        return 'PREPARING';
      case 'ready':
        return 'READY';
      case 'out_for_delivery':
        return 'OUT FOR DELIVERY';
      case 'delivered':
        return 'DELIVERED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }
}
