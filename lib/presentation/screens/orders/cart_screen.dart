import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../services/order_service.dart';
import '../../../services/payment_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/loading_widget.dart';
import 'order_confirmation_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final OrderService _orderService = OrderService();
  final TextEditingController _specialInstructionsController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingLocation = false;
  String _selectedPaymentMethod = 'cash';
  Map<String, dynamic>? _deliveryLocation;
  double _deliveryFee = 5.0;
  double _tax = 0.0;

  @override
  void initState() {
    super.initState();
    _orderService.initialize();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _specialInstructionsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address =
            '${placemark.street}, ${placemark.locality}, ${placemark.country}';

        setState(() {
          _deliveryLocation = {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'address': address,
          };
          _addressController.text = address;
        });
      }
    } catch (e) {
      // Set default location if GPS fails
      setState(() {
        _deliveryLocation = {
          'latitude': 34.0522,
          'longitude': -118.2437,
          'address': 'Default Location - Please update your address',
        };
        _addressController.text =
            'Default Location - Please update your address';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_deliveryLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a delivery location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If card payment is selected, show payment dialog
    if (_selectedPaymentMethod == 'card') {
      _showPaymentDialog();
      return;
    }

    // For cash payments, proceed directly
    await _processOrder();
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Required'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose your payment option:'),
              SizedBox(height: 16),
              Text('• Card Payment: Secure online payment'),
              SizedBox(height: 8),
              Text('• Cash Payment: Pay on delivery'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedPaymentMethod = 'cash';
                });
              },
              child: const Text('Use Cash'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processStripePayment();
              },
              child: const Text('Pay with Card'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processStripePayment() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final paymentService = PaymentService();

    setState(() {
      _isLoading = true;
    });

    try {
      final totalAmount = cartProvider.totalAmount + _deliveryFee + _tax;

      // Create payment intent and get client secret
      final result = await paymentService.processCardPayment(
        amount: totalAmount,
        currency: 'pkr',
        description: 'Food Order Payment',
        metadata: {
          'orderType': 'food',
          'itemCount': cartProvider.items.length.toString(),
        },
      );

      if (!mounted) return;

      if (result['success']) {
        if (result['requiresCardInput'] == true) {
          // Show card input dialog for web
          await _showCardInputDialog(
            clientSecret: result['clientSecret'],
            amount: totalAmount,
          );
        } else {
          // Mobile payment sheet completed successfully
          await _processOrder(paymentMethodId: result['paymentIntentId']);
        }
      } else {
        if (result['cancelled'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment was cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Payment failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showCardInputDialog({
    required String clientSecret,
    required double amount,
  }) async {
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvcController = TextEditingController();
    bool isProcessing = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter Card Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Amount: PKR ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: cardNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Card Number',
                        hintText: '4242 4242 4242 4242',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        _CardNumberInputFormatter(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: expiryController,
                            decoration: const InputDecoration(
                              labelText: 'MM/YY',
                              hintText: '12/25',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              _ExpiryDateInputFormatter(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: cvcController,
                            decoration: const InputDecoration(
                              labelText: 'CVC',
                              hintText: '123',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setState(() {
                            isProcessing = true;
                          });

                          final paymentService = PaymentService();
                          final expiry = expiryController.text.split('/');

                          final result =
                              await paymentService.confirmCardPayment(
                            clientSecret: clientSecret,
                            cardNumber: cardNumberController.text,
                            expiryMonth: expiry.isNotEmpty ? expiry[0] : '12',
                            expiryYear: expiry.length > 1 ? expiry[1] : '25',
                            cvc: cvcController.text,
                          );

                          if (!mounted) return;

                          if (result['success']) {
                            Navigator.of(context).pop();
                            await _processOrder(
                                paymentMethodId: result['paymentIntentId']);
                          } else {
                            setState(() {
                              isProcessing = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(result['message'] ?? 'Payment failed'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Pay PKR ${amount.toStringAsFixed(0)}'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processOrder({String? paymentMethodId}) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare order items
      final items = cartProvider.items
          .map((cartItem) => {
                'menuItemId': cartItem.menuItem.id,
                'name': cartItem.menuItem.name,
                'price': cartItem.menuItem.price,
                'quantity': cartItem.quantity,
                'customizations': cartItem.customizations,
                'specialInstructions': cartItem.specialInstructions,
              })
          .toList();

      final result = await _orderService.createOrder(
        items: items,
        deliveryAddress: _addressController.text.trim(),
        deliveryLocation: _deliveryLocation!,
        specialInstructions: _specialInstructionsController.text.trim().isEmpty
            ? null
            : _specialInstructionsController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
        paymentMethodId: paymentMethodId,
        deliveryFee: _deliveryFee,
      );

      if (!mounted) return;

      if (result['success']) {
        // Clear cart
        cartProvider.clearCart();

        // Navigate to confirmation screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(order: result['order']),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order failed'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const Center(
          child: Text('Please login to view your cart'),
        ),
      );
    }

    if (cartProvider.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Your cart is empty',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Add some delicious items to get started!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    _tax = 0.0; // Remove tax calculation to match backend

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Placing your order...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cart Items
                  Text(
                    'Order Items',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...cartProvider.items.map((item) => _buildCartItem(item)),

                  const SizedBox(height: 24),

                  // Delivery Location
                  Text(
                    'Delivery Location',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingLocation)
                    const Center(child: CircularProgressIndicator())
                  else
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Delivery Address',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location),
                        ),
                      ),
                      maxLines: 2,
                      onChanged: (value) {
                        if (_deliveryLocation != null) {
                          _deliveryLocation!['address'] = value;
                        }
                      },
                    ),

                  const SizedBox(height: 24),

                  // Special Instructions
                  Text(
                    'Special Instructions (Optional)',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _specialInstructionsController,
                    decoration: const InputDecoration(
                      hintText: 'Any special requests for your order...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  // Payment Method
                  Text(
                    'Payment Method',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Cash on Delivery'),
                        value: 'cash',
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Credit Card'),
                        value: 'card',
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Order Summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Summary',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:'),
                              Text(
                                  'PKR ${cartProvider.totalAmount.toStringAsFixed(0)}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Delivery Fee:'),
                              Text('PKR ${_deliveryFee.toStringAsFixed(0)}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tax:'),
                              Text('PKR ${_tax.toStringAsFixed(0)}'),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total:',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'PKR ${(cartProvider.totalAmount + _deliveryFee + _tax).toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _deliveryLocation != null ? _placeOrder : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Place Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCartItem(dynamic cartItem) {
    final theme = Theme.of(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                cartItem.menuItem.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: theme.colorScheme.surface,
                    child: const Icon(Icons.restaurant),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.menuItem.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (cartItem.customizations.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Customizations: ${cartItem.customizations.join(', ')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  if (cartItem.specialInstructions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: ${cartItem.specialInstructions}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PKR ${cartItem.menuItem.price.toStringAsFixed(0)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: cartItem.quantity > 1
                                ? () {
                                    cartProvider.updateQuantity(
                                        cartItem.id, cartItem.quantity - 1);
                                  }
                                : null,
                            icon: const Icon(Icons.remove),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              foregroundColor: theme.colorScheme.primary,
                              minimumSize: const Size(32, 32),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${cartItem.quantity}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              cartProvider.updateQuantity(
                                  cartItem.id, cartItem.quantity + 1);
                            },
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              foregroundColor: theme.colorScheme.primary,
                              minimumSize: const Size(32, 32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                cartProvider.removeItem(cartItem.id);
              },
              icon: const Icon(Icons.delete),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

// Input formatters for card details
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
