import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/table_model.dart';
import '../../../widgets/qr_code_widget.dart';

class TableReservationConfirmationScreen extends StatelessWidget {
  final TableModel table;
  final int guestCount;
  final String occasion;
  final String? specialRequests;
  final DateTime? reservationDate;
  final TimeOfDay? reservationTime;
  final TimeOfDay? endTime;

  const TableReservationConfirmationScreen({
    super.key,
    required this.table,
    required this.guestCount,
    required this.occasion,
    this.specialRequests,
    this.reservationDate,
    this.reservationTime,
    this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    final reservationId =
        'T${table.tableNumber}-${DateTime.now().millisecondsSinceEpoch}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Confirmed'),
        actions: [
          IconButton(
            onPressed: () {
              // Share functionality would be implemented here
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
                    'Table Reserved!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your table reservation has been confirmed.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Reservation ID
            _buildInfoRow(
              context,
              'Reservation ID',
              reservationId,
              showCopyButton: true,
            ),
            const SizedBox(height: 24),

            // QR Code
            Center(
              child: Column(
                children: [
                  QRCodeWidget(data: reservationId),
                  const SizedBox(height: 8),
                  Text(
                    'Show this QR code at the restaurant',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reservation details card
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
                      'Reservation Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      'Table',
                      'Table ${table.tableNumber} - ${table.location}',
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      'Date',
                      reservationDate != null
                          ? DateFormat('EEEE, MMMM d, yyyy')
                              .format(reservationDate!)
                          : 'Date not available',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      'Time',
                      reservationTime != null && endTime != null
                          ? '${reservationTime!.format(context)} - ${endTime!.format(context)}'
                          : 'Time not available',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      'Guests',
                      '$guestCount ${guestCount > 1 ? 'People' : 'Person'}',
                    ),
                    if (occasion != 'None') ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        'Occasion',
                        occasion,
                      ),
                    ],
                    if (specialRequests != null &&
                        specialRequests!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        'Special Requests',
                        specialRequests!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Restaurant info card
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
                      'Restaurant Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(
                      context,
                      'Address',
                      '123 Restaurant St, City, State 12345',
                      Icons.location_on,
                    ),
                    _buildInfoItem(
                      context,
                      'Phone',
                      '+1 (123) 456-7890',
                      Icons.phone,
                    ),
                    _buildInfoItem(
                      context,
                      'Hours',
                      'Mon-Sun: 11:00 AM - 10:00 PM',
                      Icons.access_time,
                    ),
                    _buildInfoItem(
                      context,
                      'Website',
                      'www.restaurant.com',
                      Icons.language,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Policy reminders
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
                      'Important Reminders',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildReminderItem(
                      context,
                      'Please arrive on time. The table will be held for 15 minutes past your reservation time.',
                    ),
                    _buildReminderItem(
                      context,
                      'If you need to cancel, please do so at least 2 hours before your reservation time.',
                    ),
                    _buildReminderItem(
                      context,
                      'For parties of 6 or more, an 18% gratuity may be added to your bill.',
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
                      // Calendar add functionality would be implemented here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Calendar functionality will be implemented soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Add to Calendar'),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildInfoItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(
    BuildContext context,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
