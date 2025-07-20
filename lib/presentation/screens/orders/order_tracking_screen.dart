import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/order_model.dart';
import '../../../services/order_service.dart';
import '../../../services/socket_service.dart';
import '../../widgets/loading_widget.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderService _orderService = OrderService();
  final SocketService _socketService = SocketService();
  OrderModel? _order;
  bool _isLoading = true;
  String? _error;
  Function? _unsubscribeSocket;
  bool _socketConnected = false;
  String _socketStatus = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _orderService.initialize();
    _loadOrder();
    _initializeSocket();
  }

  void _initializeSocket() async {
    if (widget.orderId.isEmpty) {
      setState(() {
        _socketStatus = 'Invalid order ID';
      });
      return;
    }

    setState(() {
      _socketStatus = 'Testing connection...';
    });

    // Test connection first
    final canConnect = await _socketService.testConnection();
    if (!canConnect) {
      setState(() {
        _socketStatus = 'Connection failed - using offline mode';
        _socketConnected = false;
      });
      return;
    }

    setState(() {
      _socketStatus = 'Connecting to tracking server...';
    });

    // Check if order is already delivered before starting tracking
    if (_order != null && _order!.status == 'delivered') {
      setState(() {
        _socketStatus = 'Order already delivered';
        _socketConnected = false;
      });
      print(
          '[OrderTracking] Order already delivered, skipping socket connection');
      return;
    }

    // Initialize socket connection
    final socket = _socketService.initializeSocket(widget.orderId);
    setState(() {
      _socketConnected = socket != null && _socketService.isConnected;
    });

    // Subscribe to order updates
    _unsubscribeSocket = _socketService.subscribeToOrderUpdates((data) {
      print('[OrderTracking] Received update: $data');

      if (mounted) {
        setState(() {
          _socketStatus = 'Connected - Live tracking active';
          _socketConnected = true;
        });

        // Update order status based on socket data
        if (_order != null && data['orderId'] == widget.orderId) {
          final newStatus = _mapSocketStatusToOrderStatus(data['status']);
          if (newStatus != _order!.status) {
            setState(() {
              _order = _order!.copyWith(status: newStatus);
            });

            // Show notification for status change
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order Status: ${data['status']}'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );

            // If delivered, show completion message and disconnect
            if (newStatus == 'delivered') {
              _showDeliveryCompletedDialog();
              _socketService.disconnectSocket();
              setState(() {
                _socketConnected = false;
                _socketStatus = 'Order delivered - Tracking complete';
              });
            }
          }
        }
      }
    });

    // Only start simulation if order is not already delivered
    if (_order != null &&
        _order!.status != 'delivered' &&
        _isOrderActive(_order!.status)) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _order != null && _isOrderActive(_order!.status)) {
          _socketService.simulateOrderProgression(widget.orderId);
        }
      });
    }
  }

  @override
  void dispose() {
    // Clean up socket connection
    if (_unsubscribeSocket != null) {
      _unsubscribeSocket!();
    }
    _socketService.disconnectSocket();
    super.dispose();
  }

  String _mapSocketStatusToOrderStatus(String socketStatus) {
    switch (socketStatus.toLowerCase()) {
      case 'order received':
        return 'pending';
      case 'preparing':
        return 'preparing';
      case 'ready for pickup':
        return 'ready';
      case 'on the way':
        return 'out_for_delivery';
      case 'arriving soon':
        return 'out_for_delivery';
      case 'delivered':
        return 'delivered';
      default:
        return 'pending';
    }
  }

  void _showDeliveryCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Order Delivered!'),
            ],
          ),
          content: const Text(
            'Your order has been delivered successfully. Thank you for choosing us!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Great!'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _orderService.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        elevation: 0,
        actions: [
          // Socket status indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _socketConnected ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: _socketConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _socketConnected ? 'Live' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: _socketConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadOrder,
            icon: const Icon(Icons.refresh),
          ),
          // Debug button for testing socket connection
          IconButton(
            onPressed: () async {
              setState(() {
                _socketStatus = 'Testing connection...';
              });

              final canConnect = await _socketService.testConnection();

              setState(() {
                _socketStatus = canConnect
                    ? 'Connection test successful'
                    : 'Connection test failed';
              });

              if (canConnect && !_socketConnected) {
                _initializeSocket();
              }
            },
            icon: const Icon(Icons.network_check),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading order details...')
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
                        'Error loading order',
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
                        onPressed: _loadOrder,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _order == null
                  ? const Center(child: Text('Order not found'))
                  : RefreshIndicator(
                      onRefresh: _loadOrder,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Enhanced Order Header with gradient
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getStatusColor(_order!.status),
                                    _getStatusColor(_order!.status)
                                        .withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getStatusColor(_order!.status)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.receipt_long,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Order #${_order!.id.substring(0, 8)}',
                                                style: theme
                                                    .textTheme.titleLarge
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                _getStatusText(_order!.status),
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Live tracking indicator
                                        if (_socketConnected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.wifi,
                                                    color: Colors.white,
                                                    size: 12),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'LIVE',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.white
                                              .withValues(alpha: 0.8),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Ordered on ${DateFormat('MMM dd, yyyy - hh:mm a').format(_order!.orderTime.toLocal())}',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_order!.deliveryTime != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Estimated delivery: ${DateFormat('hh:mm a').format(_order!.deliveryTime!)}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.attach_money,
                                          color: Colors.white
                                              .withValues(alpha: 0.8),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Total: PKR ${_order!.total.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Order Progress
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order Progress',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildProgressTimeline(),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Delivery Information
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delivery Information',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 20,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _order!.deliveryAddress ??
                                                'No address provided',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_order!.notes != null &&
                                        _order!.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.note,
                                            size: 20,
                                            color: theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Special Instructions:',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  _order!.notes!,
                                                  style: theme
                                                      .textTheme.bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Order Items
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order Items',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ..._order!.items
                                        .map((item) => _buildOrderItem(item)),
                                    const Divider(),
                                    _buildPriceRow(
                                        'Subtotal', _order!.subtotal),
                                    _buildPriceRow(
                                        'Delivery Fee', _order!.deliveryFee),
                                    _buildPriceRow('Tax', _order!.tax),
                                    const SizedBox(height: 8),
                                    _buildPriceRow('Total', _order!.total,
                                        isTotal: true),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Action Buttons
                            if (_isOrderActive(_order!.status)) ...[
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    // TODO: Implement cancel order functionality
                                    _showCancelOrderDialog();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: const Text(
                                    'Cancel Order',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildProgressTimeline() {
    final steps = [
      {
        'status': 'pending',
        'title': 'Order Placed',
        'description': 'Your order has been received'
      },
      {
        'status': 'confirmed',
        'title': 'Order Confirmed',
        'description': 'Restaurant confirmed your order'
      },
      {
        'status': 'preparing',
        'title': 'Preparing',
        'description': 'Your food is being prepared'
      },
      {
        'status': 'ready',
        'title': 'Ready for Pickup',
        'description': 'Your order is ready'
      },
      {
        'status': 'out_for_delivery',
        'title': 'Out for Delivery',
        'description': 'Driver is on the way'
      },
      {
        'status': 'delivered',
        'title': 'Delivered',
        'description': 'Order delivered successfully'
      },
    ];

    final currentStatusIndex =
        steps.indexWhere((step) => step['status'] == _order!.status);

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = index <= currentStatusIndex;
        final isCurrent = index == currentStatusIndex;

        return _buildTimelineStep(
          step['title']!,
          step['description']!,
          isCompleted,
          isCurrent,
          index < steps.length - 1,
        );
      }).toList(),
    );
  }

  Widget _buildTimelineStep(String title, String description, bool isCompleted,
      bool isCurrent, bool hasNext) {
    final theme = Theme.of(context);
    final color = isCompleted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            if (hasNext)
              Container(
                width: 2,
                height: 40,
                color: color,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Current Status',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(OrderItemModel item) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.quantity}x ${item.name}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)
                : theme.textTheme.bodyMedium,
          ),
          Text(
            'PKR ${amount.toStringAsFixed(0)}',
            style: isTotal
                ? theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )
                : theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'out_for_delivery':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  void _showCancelOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
            'Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement cancel order API call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order cancellation feature coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  bool _isOrderActive(String status) {
    return ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery']
        .contains(status.toLowerCase());
  }
}
