import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../services/payment_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String description;
  final String type; // 'booking', 'order', 'reservation'
  final String itemId;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.description,
    required this.type,
    required this.itemId,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  String _selectedPaymentMethod = 'card';

  @override
  void initState() {
    super.initState();
    _paymentService.initialize();
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedPaymentMethod == 'cash') {
        // For cash payments, just mark as pending
        final result = {
          'success': true,
          'message': 'Cash payment selected - pay on delivery/arrival',
          'paymentMethodId': null, // No payment method ID for cash
        };

        _handlePaymentResult(result);
      } else {
        // For card payments, show card input dialog
        setState(() {
          _isLoading = false;
        });
        await _processStripePayment();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop({
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processStripePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create payment intent and get client secret
      final result = await _paymentService.processCardPayment(
        amount: widget.amount,
        currency: 'pkr',
        description: widget.description,
        metadata: {
          'type': widget.type,
          'itemId': widget.itemId,
        },
      );

      if (!mounted) return;

      if (result['success']) {
        if (result['requiresCardInput'] == true) {
          // Show card input dialog for web
          setState(() {
            _isLoading = false;
          });
          await _showCardInputDialog(
            clientSecret: result['clientSecret'],
            amount: widget.amount,
          );
        } else {
          // Mobile payment sheet completed successfully
          _handlePaymentResult({
            'success': true,
            'paymentMethodId': result['paymentIntentId'],
            'message': result['message'],
          });
        }
      } else {
        _handlePaymentResult(result);
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

  void _handlePaymentResult(Map<String, dynamic> result) {
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        // Return payment result with payment method ID
        Navigator.of(context).pop({
          'success': true,
          'paymentMethodId':
              result['paymentMethodId'] ?? result['paymentIntentId'],
          'message': result['message'],
        });
      }
    } else {
      if (result['cancelled'] == true) {
        // User cancelled payment
        if (widget.onCancel != null) {
          widget.onCancel!();
        } else {
          Navigator.of(context).pop({
            'success': false,
            'cancelled': true,
            'message': 'Payment cancelled',
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Payment failed'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop({
          'success': false,
          'message': result['message'] ?? 'Payment failed',
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

    await showDialog<void>(
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
                    const Text(
                      'Please enter your card information to complete the payment.',
                      style: TextStyle(fontSize: 14),
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
                            _handlePaymentResult({
                              'success': true,
                              'paymentMethodId': result['paymentMethodId'] ??
                                  result['paymentIntentId'],
                              'message': result['message'],
                            });
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
                      : Text('Pay \$${amount.toStringAsFixed(2)}'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper method to build summary rows
  Widget _buildSummaryRow(String label, String value, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.white.withValues(alpha: 0.8),
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 20 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
        ),
        body: const Center(
          child: Text('Please login to make a payment'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Processing payment...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Payment Summary Card with gradient
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
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
                              Text(
                                'Payment Summary',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSummaryRow(
                              'Description', widget.description, false),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                              'Type', widget.type.toUpperCase(), false),
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow('Total Amount',
                              'PKR ${widget.amount.toStringAsFixed(0)}', true),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Method Selection
                  Text(
                    'Payment Method',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Credit Card Option
                  Card(
                    child: RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(
                            Icons.credit_card,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text('Credit/Debit Card'),
                        ],
                      ),
                      subtitle: const Text('Pay securely with Stripe'),
                      value: 'card',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Cash Option (for applicable types)
                  if (widget.type == 'order' || widget.type == 'reservation')
                    Card(
                      child: RadioListTile<String>(
                        title: Row(
                          children: [
                            Icon(
                              Icons.money,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(widget.type == 'order'
                                ? 'Cash on Delivery'
                                : 'Pay at Restaurant'),
                          ],
                        ),
                        subtitle: Text(widget.type == 'order'
                            ? 'Pay when your order arrives'
                            : 'Pay when you arrive at the restaurant'),
                        value: 'cash',
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Security Information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Secure Payment',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your payment information is encrypted and secure. We use Stripe for payment processing, which is trusted by millions of businesses worldwide.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Payment Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _selectedPaymentMethod == 'card'
                            ? 'Pay PKR ${widget.amount.toStringAsFixed(0)}'
                            : 'Confirm ${widget.type == 'order' ? 'Cash on Delivery' : 'Pay at Restaurant'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        if (widget.onCancel != null) {
                          widget.onCancel!();
                        } else {
                          Navigator.of(context).pop({
                            'success': false,
                            'cancelled': true,
                            'message': 'Payment cancelled by user',
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Cancel',
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
