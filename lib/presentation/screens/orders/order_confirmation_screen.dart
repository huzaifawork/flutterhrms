import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/order_model.dart';
import '../../../services/socket_service.dart';
import '../../../services/global_socket_service.dart';
import '../../../services/order_service.dart';
import 'order_tracking_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final OrderModel order;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final SocketService _socketService = SocketService();
  final GlobalSocketService _globalSocketService = GlobalSocketService();
  final OrderService _orderService = OrderService();
  late OrderModel _currentOrder;
  Function? _unsubscribeSocket;
  Function? _unsubscribeGlobalSocket;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _orderService.initialize();
    _initializeRealTimeUpdates();
  }

  void _initializeRealTimeUpdates() {
    // Subscribe to socket updates for real-time status changes
    _unsubscribeSocket = _socketService.subscribeToOrderUpdates((data) {
      if (mounted && data['orderId'] == _currentOrder.id) {
        final newStatus = _mapSocketStatusToOrderStatus(data['status']);
        if (newStatus != _currentOrder.status) {
          setState(() {
            _currentOrder = _currentOrder.copyWith(status: newStatus);
          });

          // Show status update notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order Status Updated: ${data['status']}'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });

    // Subscribe to global socket updates for 5-minute auto-progression
    _unsubscribeGlobalSocket =
        _globalSocketService.subscribeToGlobalUpdates((data) {
      if (mounted && data['orderId'] == _currentOrder.id) {
        final newStatus = data['status'];
        if (newStatus != _currentOrder.status) {
          setState(() {
            _currentOrder = _currentOrder.copyWith(status: newStatus);
          });

          // Show status update notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order automatically updated to: $newStatus'),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    });

    // Also refresh order status every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshOrderStatus();
      }
    });
  }

  Future<void> _refreshOrderStatus() async {
    try {
      final updatedOrder = await _orderService.getOrderById(_currentOrder.id);
      if (mounted &&
          updatedOrder != null &&
          updatedOrder.status != _currentOrder.status) {
        setState(() {
          _currentOrder = updatedOrder;
        });
      }
    } catch (e) {
      // Silently handle errors to avoid disrupting user experience
      debugPrint('Error refreshing order status: $e');
    }
  }

  String _mapSocketStatusToOrderStatus(String socketStatus) {
    switch (socketStatus.toLowerCase()) {
      case 'order received':
        return 'pending';
      case 'confirmed':
        return 'confirmed';
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
        return socketStatus.toLowerCase();
    }
  }

  @override
  void dispose() {
    if (_unsubscribeSocket != null) {
      _unsubscribeSocket!();
    }
    if (_unsubscribeGlobalSocket != null) {
      _unsubscribeGlobalSocket!();
    }
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: const Icon(
                Icons.check,
                size: 60,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Order Confirmed!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Thank you for your order. We\'ll start preparing it right away!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Order Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Details',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_currentOrder.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStatusColor(_currentOrder.status)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _currentOrder.status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(_currentOrder.status),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                        'Order ID', '#${_currentOrder.id.substring(0, 8)}'),
                    _buildDetailRow(
                        'Order Date',
                        DateFormat('MMM dd, yyyy - hh:mm a')
                            .format(_currentOrder.orderTime)),
                    _buildDetailRow('Payment Method',
                        _getPaymentMethodText(_currentOrder.paymentMethod)),
                    if (_currentOrder.deliveryTime != null)
                      _buildDetailRow(
                        'Estimated Delivery',
                        DateFormat('hh:mm a')
                            .format(_currentOrder.deliveryTime!),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Delivery Address',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentOrder.deliveryAddress ?? 'No address provided',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (_currentOrder.notes != null &&
                        _currentOrder.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Special Instructions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentOrder.notes!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._currentOrder.items.map((item) => _buildOrderItem(item)),
                    const Divider(),
                    _buildPriceRow('Subtotal', _currentOrder.subtotal),
                    _buildPriceRow('Delivery Fee', _currentOrder.deliveryFee),
                    _buildPriceRow('Tax', _currentOrder.tax),
                    const SizedBox(height: 8),
                    _buildPriceRow(
                      'Total',
                      _currentOrder.total,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderTrackingScreen(orderId: _currentOrder.id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Track Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Continue Shopping',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItemModel item) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Note: customizations not available in data model
                // if (item.customizations.isNotEmpty) ...[
                //   const SizedBox(height: 4),
                //   Text(
                //     'Customizations: ${item.customizations.join(', ')}',
                //     style: theme.textTheme.bodySmall?.copyWith(
                //       color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                //     ),
                //   ),
                // ],
                if (item.specialInstructions != null &&
                    item.specialInstructions!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note: ${item.specialInstructions}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${item.quantity}x',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
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
                ? theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)
                : theme.textTheme.bodyMedium,
          ),
          Text(
            'PKR ${amount.toStringAsFixed(0)}',
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
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

  String _getPaymentMethodText(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash on Delivery';
      case 'card':
        return 'Credit Card';
      case 'stripe':
        return 'Stripe Payment';
      default:
        return method;
    }
  }
}
