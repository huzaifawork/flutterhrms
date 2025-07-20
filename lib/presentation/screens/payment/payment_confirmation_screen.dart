import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> paymentDetails;
  final Map<String, dynamic> bookingDetails;

  const PaymentConfirmationScreen({
    super.key,
    required this.paymentDetails,
    required this.bookingDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuccess = paymentDetails['success'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Confirmation'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            
            // Status Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSuccess 
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
              ),
              child: Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                size: 60,
                color: isSuccess ? Colors.green : Colors.red,
              ),
            ),

            const SizedBox(height: 24),

            // Status Title
            Text(
              isSuccess ? 'Payment Successful!' : 'Payment Failed',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Status Message
            Text(
              paymentDetails['message'] ?? 
                  (isSuccess ? 'Your booking has been confirmed' : 'Please try again'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Payment Details Card
            if (isSuccess) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDetailRow('Payment Method', 'Credit Card'),
                      _buildDetailRow('Amount', '\$${bookingDetails['totalPrice']?.toStringAsFixed(2) ?? '0.00'}'),
                      _buildDetailRow('Transaction ID', paymentDetails['paymentIntentId'] ?? 'N/A'),
                      _buildDetailRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())),
                      _buildDetailRow('Status', 'Completed'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Booking Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDetailRow('Room Type', bookingDetails['roomType'] ?? 'N/A'),
                      _buildDetailRow('Room Number', bookingDetails['roomNumber'] ?? 'N/A'),
                      _buildDetailRow('Check-in', bookingDetails['checkInDate'] ?? 'N/A'),
                      _buildDetailRow('Check-out', bookingDetails['checkOutDate'] ?? 'N/A'),
                      _buildDetailRow('Guests', '${bookingDetails['guests'] ?? 1}'),
                      _buildDetailRow('Nights', '${bookingDetails['numberOfNights'] ?? 1}'),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate back to home or bookings
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isSuccess ? 'Back to Home' : 'Try Again',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (isSuccess) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to bookings screen
                    Navigator.of(context).pushReplacementNamed('/bookings');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'View My Bookings',
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
