import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../../data/models/table_model.dart';

import '../../../providers/auth_provider.dart';
import '../../../../services/payment_service.dart';
import 'table_reservation_confirmation_screen.dart';

// Card number formatter class
class _CardNumberFormatter extends TextInputFormatter {
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

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Expiry date formatter class
class _ExpiryDateFormatter extends TextInputFormatter {
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

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TableReservationScreen extends StatefulWidget {
  final TableModel table;

  const TableReservationScreen({
    super.key,
    required this.table,
  });

  @override
  State<TableReservationScreen> createState() => _TableReservationScreenState();
}

class _TableReservationScreenState extends State<TableReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specialRequestsController =
      TextEditingController();
  final PaymentService _paymentService = PaymentService();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0); // 7:00 PM
  TimeOfDay _selectedEndTime =
      const TimeOfDay(hour: 21, minute: 0); // 9:00 PM (2 hours later)
  int _guests = 2;
  bool _isLoading = false;
  bool _isCheckingAvailability = false;
  bool _isAvailable = true;
  String _availabilityMessage = '';
  bool _showPaymentForm = false;

  // Payment form fields
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  String? _clientSecret;
  String? _paymentIntentId;

  @override
  void initState() {
    super.initState();
    _paymentService.initialize();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      _fullNameController.text = authProvider.user!.name;
      _emailController.text = authProvider.user!.email;
      // Phone might not be available in user model, so we'll leave it empty for now
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _checkAvailability();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        // Auto-calculate end time (2 hours later)
        _selectedEndTime = TimeOfDay(
          hour: (_selectedTime.hour + 2) % 24,
          minute: _selectedTime.minute,
        );
      });
      _checkAvailability();
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime,
    );
    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
      });
      _checkAvailability();
    }
  }

  Future<void> _checkAvailability() async {
    if (!mounted) return;

    setState(() {
      _isCheckingAvailability = true;
      _availabilityMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.10.6:8080/api/tables/availability').replace(
          queryParameters: {
            'reservationDate': DateFormat('yyyy-MM-dd').format(_selectedDate),
            'time':
                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
            'endTime':
                '${_selectedEndTime.hour.toString().padLeft(2, '0')}:${_selectedEndTime.minute.toString().padLeft(2, '0')}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final tableAvailability = data.firstWhere(
          (t) => t['table']['_id'] == widget.table.id,
          orElse: () => null,
        );

        if (mounted) {
          setState(() {
            _isCheckingAvailability = false;
            if (tableAvailability != null &&
                !tableAvailability['isAvailable']) {
              _isAvailable = false;
              _availabilityMessage =
                  'This table is already reserved during the selected time range. Please choose a different time.';
            } else {
              _isAvailable = true;
              _availabilityMessage = 'Table is available for reservation!';
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingAvailability = false;
          _isAvailable = true;
          _availabilityMessage = '';
        });
      }
    }
  }

  Future<void> _proceedToPayment() async {
    if (_formKey.currentState!.validate()) {
      if (!_isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'This table is not available for the selected time range.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final totalPrice = _guests * 10.0; // $10 per person

        // Create payment intent
        final paymentResult = await _paymentService.createPaymentIntent(
          amount: totalPrice,
          currency: 'usd',
          description:
              'Table ${widget.table.tableNumber} reservation for $_guests guests',
        );

        if (paymentResult['success']) {
          setState(() {
            _clientSecret = paymentResult['clientSecret'];
            _paymentIntentId = paymentResult['paymentIntentId'];
            _showPaymentForm = true;
            _isLoading = false;
          });
        } else {
          throw Exception(paymentResult['message']);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating payment: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _createReservation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null) {
        throw Exception('Please login to make a reservation');
      }

      if (_clientSecret == null) {
        throw Exception('Payment not initialized. Please try again.');
      }

      // Process payment using Stripe
      Map<String, dynamic> paymentResult;

      if (kIsWeb) {
        // For web, use card input form to confirm the existing payment intent
        paymentResult = await _paymentService.confirmCardPayment(
          clientSecret: _clientSecret!,
          cardNumber: _cardNumberController.text.replaceAll(' ', ''),
          expiryMonth: _expiryController.text.split('/')[0],
          expiryYear:
              '20${_expiryController.text.split('/')[1]}', // Convert YY to YYYY
          cvc: _cvcController.text,
        );
      } else {
        // For mobile, create and process payment in one step
        paymentResult = await _paymentService.processCardPayment(
          amount: _guests * 10.0,
          currency: 'usd',
          description:
              'Table ${widget.table.tableNumber} reservation for $_guests guests',
        );
      }

      if (!paymentResult['success']) {
        throw Exception(paymentResult['message']);
      }

      final totalPrice = _guests * 10; // $10 per person

      final reservationData = {
        'tableId': widget.table.id,
        'tableNumber': widget.table.tableNumber,
        'reservationDate': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'time':
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'endTime':
            '${_selectedEndTime.hour.toString().padLeft(2, '0')}:${_selectedEndTime.minute.toString().padLeft(2, '0')}',
        'guests': _guests, // This is already an int
        'payment': 'card',
        'totalPrice': totalPrice, // This is already an int
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'specialRequests': _specialRequestsController.text.trim(),
        'paymentMethodId': paymentResult['paymentMethodId'],
        'paymentIntentId': paymentResult['paymentIntentId'],
      };

      print('Sending reservation data: ${json.encode(reservationData)}');

      final response = await http.post(
        Uri.parse('http://192.168.10.6:8080/api/reservations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: json.encode(reservationData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TableReservationConfirmationScreen(
                table: widget.table,
                guestCount: _guests,
                occasion: 'Dining', // Default occasion
                specialRequests: _specialRequestsController.text,
                reservationDate: _selectedDate,
                reservationTime: _selectedTime,
                endTime: _selectedEndTime,
              ),
            ),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            'Failed to create reservation: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating reservation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserve Table'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Table info card
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.table_bar,
                        size: 40,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Table ${widget.table.tableNumber}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            widget.table.location,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Capacity: ${widget.table.capacity} ${widget.table.capacity > 1 ? 'Persons' : 'Person'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Date and time section
            Text(
              'Select Date & Time',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    context,
                    'Date',
                    DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                    _selectDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    context,
                    'Start Time',
                    _selectedTime.format(context),
                    _selectTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    context,
                    'End Time',
                    _selectedEndTime.format(context),
                    _selectEndTime,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGuestCounter(
                    context,
                    'Number of Guests',
                    _guests,
                    (value) {
                      setState(() {
                        _guests = value;
                      });
                    },
                    1,
                    widget.table.capacity,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Availability message
            if (_isCheckingAvailability)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Checking availability...'),
                    ],
                  ),
                ),
              )
            else if (_availabilityMessage.isNotEmpty)
              Card(
                color: _isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _isAvailable ? Icons.check_circle : Icons.error,
                        color: _isAvailable ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _availabilityMessage,
                          style: TextStyle(
                            color: _isAvailable
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Contact Information section
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Special requests
            Text(
              'Special Requests (Optional)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specialRequestsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter any special requests or preferences...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Restaurant policy
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restaurant Policy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildPolicyItem(
                      context,
                      'Reservation Holding Time',
                      'Tables are held for 15 minutes past reservation time',
                    ),
                    _buildPolicyItem(
                      context,
                      'Cancellation',
                      'Please cancel at least 2 hours before reservation time',
                    ),
                    _buildPolicyItem(
                      context,
                      'Large Parties',
                      'Groups of 6 or more may be subject to a 18% gratuity',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Reservation Summary
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reservation Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryItem(
                        'Table', 'Table ${widget.table.tableNumber}'),
                    _buildSummaryItem('Date',
                        DateFormat('EEE, MMM d, yyyy').format(_selectedDate)),
                    _buildSummaryItem('Time',
                        '${_selectedTime.format(context)} - ${_selectedEndTime.format(context)}'),
                    _buildSummaryItem('Guests',
                        '$_guests ${_guests > 1 ? 'persons' : 'person'}'),
                    _buildSummaryItem('Total Price', '\$${_guests * 10}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            if (!_showPaymentForm) ...[
              ElevatedButton(
                onPressed:
                    (_isLoading || !_isAvailable) ? null : _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Proceed to Payment'),
              ),
            ] else ...[
              // Payment section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Details',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      if (kIsWeb) ...[
                        // Card input form for web
                        Text(
                          'Enter your card details:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _cardNumberController,
                          decoration: InputDecoration(
                            labelText: 'Card Number',
                            hintText: '4242 4242 4242 4242',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.credit_card),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(
                                19), // 16 digits + 3 spaces
                            _CardNumberFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter card number';
                            }
                            final digitsOnly = value.replaceAll(' ', '');
                            if (digitsOnly.length < 13 ||
                                digitsOnly.length > 19) {
                              return 'Please enter a valid card number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _expiryController,
                                decoration: InputDecoration(
                                  labelText: 'MM/YY',
                                  hintText: '12/25',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                  _ExpiryDateFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (!value.contains('/') ||
                                      value.length != 5) {
                                    return 'MM/YY';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _cvcController,
                                decoration: InputDecoration(
                                  labelText: 'CVC',
                                  hintText: '123',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (value.length < 3 || value.length > 4) {
                                    return 'Invalid CVC';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Test Card Numbers:',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Visa: 4242 4242 4242 4242\n• Mastercard: 5555 5555 5555 4444\n• Use any future date for expiry and any 3 digits for CVC',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.blue.shade700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Mobile payment sheet message
                        Text(
                          'Tap the button below to open the secure payment form.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createReservation,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Pay \$${_guests * 10} & Confirm'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
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
                  label == 'Date' ? Icons.calendar_today : Icons.access_time,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestCounter(
    BuildContext context,
    String label,
    int value,
    Function(int) onChanged,
    int min,
    int max,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove),
                style: IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(
    BuildContext context,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
