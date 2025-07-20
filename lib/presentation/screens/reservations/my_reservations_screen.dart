import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../services/reservation_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final ReservationService _reservationService = ReservationService();
  List<ReservationModel> _reservations = [];
  List<ReservationModel> _upcomingReservations = [];
  List<ReservationModel> _pastReservations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reservationService.initialize();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reservations = await _reservationService.getUserReservations();
      _separateReservations(reservations);
      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Fallback to dummy data for development
        _reservations = ReservationModel.dummyReservations();
        _separateReservations(_reservations);
      });
    }
  }

  void _separateReservations(List<ReservationModel> reservations) {
    final now = DateTime.now();
    _upcomingReservations.clear();
    _pastReservations.clear();

    for (final reservation in reservations) {
      final reservationDate = reservation.reservationDate;
      if (reservationDate.isAfter(now) ||
          reservationDate
              .isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
        _upcomingReservations.add(reservation);
      } else {
        _pastReservations.add(reservation);
      }
    }

    // Sort upcoming reservations by date (earliest first)
    _upcomingReservations
        .sort((a, b) => a.reservationDate.compareTo(b.reservationDate));

    // Sort past reservations by date (most recent first)
    _pastReservations
        .sort((a, b) => b.reservationDate.compareTo(a.reservationDate));
  }

  Future<void> _cancelReservation(ReservationModel reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content:
            const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result =
          await _reservationService.cancelReservation(reservation.id);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] ?? 'Reservation cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReservations(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to cancel reservation'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Reservations'),
        ),
        body: const Center(
          child: Text('Please login to view your reservations'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadReservations,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading your reservations...')
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
                        'Error loading reservations',
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
                        onPressed: _loadReservations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _reservations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_bar_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reservations found',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You haven\'t made any table reservations yet.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReservations,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Upcoming Reservations Section
                            Text(
                              'Upcoming Reservations',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_upcomingReservations.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 48,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No upcoming reservations found',
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...(_upcomingReservations.map((reservation) =>
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildReservationCard(reservation,
                                        isUpcoming: true),
                                  ))),

                            const SizedBox(height: 32),

                            // Past Reservations Section
                            Text(
                              'Past Reservations',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_pastReservations.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.history_outlined,
                                      size: 48,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No past reservations found',
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...(_pastReservations.map((reservation) =>
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildReservationCard(reservation,
                                        isUpcoming: false),
                                  ))),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildReservationCard(ReservationModel reservation,
      {bool isUpcoming = true}) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    String displayStatus;

    // Override status based on whether reservation is upcoming or past
    if (isUpcoming) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      displayStatus = 'CONFIRMED';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.history;
      displayStatus = 'PAST';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reservation #${reservation.id.substring(0, 8)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        displayStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Table info
            if (reservation.table != null) ...[
              Text(
                'Table ${reservation.table!.tableNumber}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Location: ${reservation.table!.location}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Date and time
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMM dd, yyyy')
                      .format(reservation.reservationDate),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  reservation.endTime != null
                      ? '${reservation.timeSlot} - ${reservation.endTime}'
                      : reservation.timeSlot,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Party size
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${reservation.partySize} people',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),

            // Occasion
            if (reservation.occasion != null &&
                reservation.occasion!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.celebration,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Occasion: ${reservation.occasion}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],

            // Special requests
            if (reservation.specialRequests != null &&
                reservation.specialRequests!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Special Requests:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                reservation.specialRequests!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],

            // Actions - only show cancel for upcoming reservations
            if (isUpcoming) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _cancelReservation(reservation),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
