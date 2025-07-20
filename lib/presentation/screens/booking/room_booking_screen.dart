import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../data/models/room_model.dart';
import '../../../services/booking_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import '../payment/payment_screen.dart';
import '../payment/payment_confirmation_screen.dart';

class RoomBookingScreen extends StatefulWidget {
  final RoomModel room;

  const RoomBookingScreen({
    super.key,
    required this.room,
  });

  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  final BookingService _bookingService = BookingService();
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedCheckInDate = DateTime.now().add(const Duration(days: 1));
  DateTime _selectedCheckOutDate = DateTime.now().add(const Duration(days: 2));
  int _guests = 1;
  final TextEditingController _specialRequestsController =
      TextEditingController();

  bool _isLoading = false;
  bool _isCheckingAvailability = false;
  bool _isAvailable = true;
  String? _availabilityMessage;

  @override
  void initState() {
    super.initState();
    _bookingService.initialize();
    _checkAvailability();
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    setState(() {
      _isCheckingAvailability = true;
      _availabilityMessage = 'Checking availability...';
    });

    try {
      final result = await _bookingService.checkRoomAvailability(
        roomId: widget.room.id,
        checkInDate: _selectedCheckInDate,
        checkOutDate: _selectedCheckOutDate,
      );

      setState(() {
        _isAvailable = result['available'] ?? false;
        _availabilityMessage =
            result['message'] ?? 'Unknown availability status';
        _isCheckingAvailability = false;
      });

      // Show a snackbar with the result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_availabilityMessage ?? 'Availability checked'),
            backgroundColor: _isAvailable ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAvailable = false;
        _availabilityMessage = 'Error checking availability: ${e.toString()}';
        _isCheckingAvailability = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_availabilityMessage ?? 'Error occurred'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _bookRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAvailable) return;

    // Get user details from auth provider (before async operations)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    // Navigate to payment screen first
    final paymentResult =
        await Navigator.of(context).push<Map<String, dynamic>?>(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          amount: _totalAmount,
          description:
              'Room Booking - ${widget.room.roomType} Room ${widget.room.roomNumber}',
          type: 'booking',
          itemId: widget.room.id,
        ),
      ),
    );

    if (paymentResult == null || paymentResult['success'] != true) {
      // Payment was cancelled or failed
      return;
    }

    final paymentIntentId = paymentResult['paymentIntentId'] as String?;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _bookingService.createBooking(
        roomId: widget.room.id,
        checkInDate: _selectedCheckInDate,
        checkOutDate: _selectedCheckOutDate,
        guests: _guests,
        specialRequests: _specialRequestsController.text.trim().isEmpty
            ? null
            : _specialRequestsController.text.trim(),
        roomType: widget.room.roomType,
        roomNumber: widget.room.roomNumber,
        fullName: user?.name ?? '',
        email: user?.email ?? '',
        phone: user?.phoneNumber ?? '',
        paymentMethod: 'card',
        paymentMethodId: paymentIntentId,
        basePrice: widget.room.pricePerNight,
      );

      if (!mounted) return;

      if (result['success']) {
        // Navigate to payment confirmation screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentConfirmationScreen(
              paymentDetails: paymentResult,
              bookingDetails: {
                'roomType': widget.room.roomType,
                'roomNumber': widget.room.roomNumber,
                'checkInDate':
                    DateFormat('MMM dd, yyyy').format(_selectedCheckInDate),
                'checkOutDate':
                    DateFormat('MMM dd, yyyy').format(_selectedCheckOutDate),
                'guests': _guests,
                'numberOfNights': _numberOfNights,
                'totalPrice': _totalAmount,
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Booking failed'),
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

  int get _numberOfNights {
    return _selectedCheckOutDate.difference(_selectedCheckInDate).inDays;
  }

  double get _totalAmount {
    return widget.room.pricePerNight * _numberOfNights;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Book Room'),
        ),
        body: const Center(
          child: Text('Please login to book a room'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Room'),
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.room.imageUrls.isNotEmpty
                                    ? widget.room.imageUrls.first
                                    : '',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: theme.colorScheme.surface,
                                    child: const Icon(Icons.hotel),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.room.roomType.toUpperCase()} - Room ${widget.room.roomNumber}',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${widget.room.pricePerNight.toStringAsFixed(2)} / night',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Capacity: ${widget.room.capacity} guests',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Check-in Date
                    Text(
                      'Check-in Date',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedCheckInDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedCheckInDate = date;
                            if (_selectedCheckOutDate.isBefore(
                                _selectedCheckInDate
                                    .add(const Duration(days: 1)))) {
                              _selectedCheckOutDate = _selectedCheckInDate
                                  .add(const Duration(days: 1));
                            }
                          });
                          _checkAvailability();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(_selectedCheckInDate),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Check-out Date
                    Text(
                      'Check-out Date',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedCheckOutDate,
                          firstDate:
                              _selectedCheckInDate.add(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedCheckOutDate = date;
                          });
                          _checkAvailability();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(_selectedCheckOutDate),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Number of Guests
                    Text(
                      'Number of Guests',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _guests > 1
                              ? () {
                                  setState(() {
                                    _guests--;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            foregroundColor: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$_guests',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: _guests < widget.room.capacity
                              ? () {
                                  setState(() {
                                    _guests++;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            foregroundColor: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Special Requests
                    Text(
                      'Special Requests (Optional)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _specialRequestsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Any special requests or preferences...',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Availability Status
                    if (_isCheckingAvailability)
                      const Center(child: CircularProgressIndicator())
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isAvailable
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isAvailable ? Icons.check_circle : Icons.error,
                              color: _isAvailable ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _availabilityMessage ??
                                    (_isAvailable
                                        ? 'Room is available'
                                        : 'Room is not available'),
                                style: TextStyle(
                                  color:
                                      _isAvailable ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Booking Summary
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking Summary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Number of nights:'),
                                Text('$_numberOfNights'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Price per night:'),
                                Text(
                                    '\$${widget.room.pricePerNight.toStringAsFixed(2)}'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount:',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${_totalAmount.toStringAsFixed(2)}',
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

                    // Book Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isAvailable && !_isCheckingAvailability
                            ? _bookRoom
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isAvailable ? 'Book Now' : 'Not Available',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
