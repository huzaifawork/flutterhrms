import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../data/models/table_model.dart';
import '../../../services/reservation_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import 'reservation_confirmation_screen.dart';
import '../payment/payment_screen.dart';

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
  final ReservationService _reservationService = ReservationService();
  final _formKey = GlobalKey<FormState>();

  // Date and Time
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '19:00';
  String _selectedEndTime = '21:00';

  // Guest and Personal Info
  int _partySize = 2;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specialRequestsController =
      TextEditingController();
  final TextEditingController _occasionController = TextEditingController();

  // State management
  bool _isLoading = false;
  bool _isCheckingAvailability = false;
  bool _isAvailable = true;
  String? _availabilityMessage;

  final List<String> _timeSlots = [
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
    '20:30',
    '21:00',
    '21:30',
    '22:00'
  ];

  final List<String> _occasions = [
    'Birthday',
    'Anniversary',
    'Date Night',
    'Business Meeting',
    'Family Gathering',
    'Celebration',
    'Other'
  ];

  // Reservation fee - $10 per person
  double get _reservationFee =>
      _partySize * 500.0; // Rs. 500 per person (matching website)

  @override
  void initState() {
    super.initState();
    _reservationService.initialize();
    _initializeUserData();
    _checkAvailability();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    _occasionController.dispose();
    super.dispose();
  }

  void _initializeUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      _fullNameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  void _updateEndTime() {
    // Auto-calculate end time (2 hours after start time)
    final startHour = int.parse(_selectedTimeSlot.split(':')[0]);
    final startMinute = int.parse(_selectedTimeSlot.split(':')[1]);
    final endHour = (startHour + 2) % 24;
    _selectedEndTime =
        '${endHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
  }

  Future<void> _checkAvailability() async {
    setState(() {
      _isCheckingAvailability = true;
    });

    try {
      final result = await _reservationService.checkTableAvailability(
        tableId: widget.table.id,
        reservationDate: _selectedDate,
        timeSlot: _selectedTimeSlot,
        endTime: _selectedEndTime,
      );

      setState(() {
        _isAvailable = result['available'];
        _availabilityMessage = result['message'];
        _isCheckingAvailability = false;
      });
    } catch (e) {
      setState(() {
        _isAvailable = false;
        _availabilityMessage = 'Error checking availability';
        _isCheckingAvailability = false;
      });
    }
  }

  Future<void> _makeReservation() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAvailable) return;

    // Navigate to payment screen first
    final paymentResult =
        await Navigator.of(context).push<Map<String, dynamic>?>(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          amount: _reservationFee,
          description: 'Table Reservation - Table ${widget.table.tableNumber}',
          type: 'reservation',
          itemId: widget.table.id,
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
      final result = await _reservationService.createReservation(
        tableId: widget.table.id,
        reservationDate: _selectedDate,
        timeSlot: _selectedTimeSlot,
        endTime: _selectedEndTime,
        partySize: _partySize,
        specialRequests: _specialRequestsController.text.trim().isEmpty
            ? null
            : _specialRequestsController.text.trim(),
        occasion: _occasionController.text.trim().isEmpty
            ? null
            : _occasionController.text.trim(),
        tableNumber: widget.table.tableNumber,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        paymentMethod: 'card',
        paymentMethodId: paymentIntentId,
      );

      if (!mounted) return;

      if (result['success']) {
        // Debug: Print the reservation data to see what we're getting
        print('Reservation result: ${result['reservation']}');

        // Convert the Map to ReservationModel using the service method
        final reservationData = result['reservation'] as Map<String, dynamic>;

        try {
          final reservationModel =
              _reservationService.mapApiToReservationModel(reservationData);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) =>
                  ReservationConfirmationScreen(reservation: reservationModel),
            ),
          );
        } catch (e) {
          print('Error converting reservation data: $e');
          print('Reservation data structure: $reservationData');

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error processing reservation: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Reservation failed'),
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

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reserve Table'),
        ),
        body: const Center(
          child: Text('Please login to make a reservation'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserve Table'),
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Making your reservation...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.table.imageUrl ?? '',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: theme.colorScheme.surface,
                                    child: const Icon(Icons.table_bar),
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
                                    'Table ${widget.table.tableNumber}',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Capacity: ${widget.table.capacity} people',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Location: ${widget.table.location}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Date Selection
                    Text(
                      'Select Date',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TableCalendar<DateTime>(
                          firstDay: DateTime.now(),
                          lastDay: DateTime.now().add(const Duration(days: 90)),
                          focusedDay: _selectedDate,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDate, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDate = selectedDay;
                            });
                            _checkAvailability();
                          },
                          calendarFormat: CalendarFormat.month,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            selectedDecoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Start Time Selection
                    Text(
                      'Start Time',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _timeSlots.map((time) {
                          final isSelected = _selectedTimeSlot == time;
                          return ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 60,
                              maxWidth: 80,
                            ),
                            child: FilterChip(
                              label: Text(
                                time,
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedTimeSlot = time;
                                  _updateEndTime(); // Auto-update end time
                                });
                                _checkAvailability();
                              },
                              selectedColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                              checkmarkColor: theme.colorScheme.primary,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // End Time Selection
                    Text(
                      'End Time',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _timeSlots.map((time) {
                          final isSelected = _selectedEndTime == time;
                          final startHour =
                              int.parse(_selectedTimeSlot.split(':')[0]);
                          final endHour = int.parse(time.split(':')[0]);
                          final isValidEndTime = endHour > startHour ||
                              (endHour == startHour &&
                                  int.parse(time.split(':')[1]) >
                                      int.parse(
                                          _selectedTimeSlot.split(':')[1]));

                          return ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 60,
                              maxWidth: 80,
                            ),
                            child: FilterChip(
                              label: Text(
                                time,
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: isSelected,
                              onSelected: isValidEndTime
                                  ? (selected) {
                                      setState(() {
                                        _selectedEndTime = time;
                                      });
                                      _checkAvailability();
                                    }
                                  : null,
                              selectedColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                              checkmarkColor: theme.colorScheme.primary,
                              backgroundColor: isValidEndTime
                                  ? null
                                  : theme.colorScheme.surface
                                      .withValues(alpha: 0.3),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Party Size
                    Text(
                      'Party Size',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _partySize > 1
                              ? () {
                                  setState(() {
                                    _partySize--;
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
                          '$_partySize people',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: _partySize < widget.table.capacity
                              ? () {
                                  setState(() {
                                    _partySize++;
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

                    const SizedBox(height: 24),

                    // Personal Information Section
                    Text(
                      'Personal Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Occasion
                    Text(
                      'Occasion (Optional)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _occasionController.text.isEmpty
                          ? null
                          : _occasionController.text,
                      decoration: const InputDecoration(
                        hintText: 'Select an occasion',
                        border: OutlineInputBorder(),
                      ),
                      items: _occasions.map((occasion) {
                        return DropdownMenuItem(
                          value: occasion,
                          child: Text(occasion),
                        );
                      }).toList(),
                      onChanged: (value) {
                        _occasionController.text = value ?? '';
                      },
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
                                        ? 'Table is available'
                                        : 'Table is not available'),
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

                    // Reservation Fee
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reservation Fee',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Fee per person:',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  'Rs. 500',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Party size:',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  '$_partySize people',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Fee:',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Rs. ${_reservationFee.toStringAsFixed(0)}',
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

                    // Reservation Summary
                    Card(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reservation Summary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryRow(
                                'Table:', 'Table ${widget.table.tableNumber}'),
                            _buildSummaryRow(
                                'Date:',
                                DateFormat('MMM dd, yyyy')
                                    .format(_selectedDate)),
                            _buildSummaryRow('Time:',
                                '$_selectedTimeSlot - $_selectedEndTime'),
                            _buildSummaryRow(
                                'Number of Guests:', '$_partySize'),
                            const Divider(height: 20),
                            _buildSummaryRow(
                              'Total Price:',
                              'Rs. ${_reservationFee.toStringAsFixed(0)}',
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Reserve Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isAvailable && !_isCheckingAvailability
                            ? _makeReservation
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isAvailable ? 'Reserve Table' : 'Not Available',
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

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
