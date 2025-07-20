import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_utils.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/models/room_model.dart';
import '../../../widgets/qr_code_widget.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final BookingModel booking;
  final RoomModel room;

  const BookingConfirmationScreen({
    super.key,
    required this.booking,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality will be implemented soon'),
                ),
              );
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success message
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Booking Confirmed!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your booking has been confirmed successfully.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Booking ID
            _buildInfoRow(
              context,
              'Booking ID',
              booking.id,
              showCopyButton: true,
            ),
            const SizedBox(height: 24),
            
            // QR Code
            Center(
              child: Column(
                children: [
                  QRCodeWidget(data: booking.id),
                  const SizedBox(height: 8),
                  Text(
                    'Show this QR code at check-in',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Booking details card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      'Room',
                      'Room ${room.roomNumber} - ${room.roomType}',
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      'Check-in',
                      DateFormat('EEE, MMM dd, yyyy').format(booking.checkInDate),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      'Check-out',
                      DateFormat('EEE, MMM dd, yyyy').format(booking.checkOutDate),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      'Guests',
                      '${booking.adults} ${booking.adults > 1 ? 'Adults' : 'Adult'}${booking.children > 0 ? ', ${booking.children} ${booking.children > 1 ? 'Children' : 'Child'}' : ''}',
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      'Total Amount',
                      AppUtils.formatCurrency(booking.totalAmount),
                      valueStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      'Payment Method',
                      booking.paymentMethod,
                    ),
                    if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        'Special Requests',
                        booking.specialRequests!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Hotel policies
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hotel Policies',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildPolicyItem(
                      context,
                      'Check-in Time',
                      '2:00 PM - 12:00 AM',
                    ),
                    _buildPolicyItem(
                      context,
                      'Check-out Time',
                      'Until 12:00 PM',
                    ),
                    _buildPolicyItem(
                      context,
                      'Cancellation',
                      'Free cancellation until 24 hours before check-in',
                    ),
                    _buildPolicyItem(
                      context,
                      'Identification',
                      'Please present a valid ID at check-in',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement download functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Download functionality will be implemented soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Go to Home'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool showCopyButton = false,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (showCopyButton)
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildPolicyItem(
    BuildContext context,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
} 