import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import 'admin_bookings_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call - replace with actual API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _dashboardData = {
        'totalBookings': 156,
        'totalOrders': 342,
        'totalUsers': 89,
        'totalRevenue': 15420.50,
        'todayBookings': 12,
        'todayOrders': 28,
        'pendingBookings': 8,
        'pendingOrders': 15,
        'monthlyRevenue': [
          {'month': 'Jan', 'revenue': 12000},
          {'month': 'Feb', 'revenue': 15000},
          {'month': 'Mar', 'revenue': 18000},
          {'month': 'Apr', 'revenue': 14000},
          {'month': 'May', 'revenue': 16000},
          {'month': 'Jun', 'revenue': 20000},
        ],
        'bookingsByType': [
          {'type': 'Standard', 'count': 45},
          {'type': 'Deluxe', 'count': 32},
          {'type': 'Suite', 'count': 18},
          {'type': 'Executive', 'count': 12},
        ],
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Check if user is admin
    if (!authProvider.isAuthenticated || authProvider.currentUser?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
        ),
        body: const Center(
          child: Text('Access denied. Admin privileges required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading dashboard data...')
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Text(
                      'Welcome back, ${authProvider.currentUser?.name ?? 'Admin'}!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here\'s what\'s happening with your business today.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'Total Bookings',
                          _dashboardData['totalBookings'].toString(),
                          Icons.hotel,
                          Colors.blue,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminBookingsScreen()),
                          ),
                        ),
                        _buildStatCard(
                          'Total Orders',
                          _dashboardData['totalOrders'].toString(),
                          Icons.restaurant,
                          Colors.green,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                          ),
                        ),
                        _buildStatCard(
                          'Total Users',
                          _dashboardData['totalUsers'].toString(),
                          Icons.people,
                          Colors.orange,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                          ),
                        ),
                        _buildStatCard(
                          'Total Revenue',
                          '\$${_dashboardData['totalRevenue'].toStringAsFixed(0)}',
                          Icons.attach_money,
                          Colors.purple,
                          null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Today's Activity
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today\'s Activity',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTodayStatItem(
                                    'Bookings',
                                    _dashboardData['todayBookings'].toString(),
                                    Icons.hotel,
                                    Colors.blue,
                                  ),
                                ),
                                Expanded(
                                  child: _buildTodayStatItem(
                                    'Orders',
                                    _dashboardData['todayOrders'].toString(),
                                    Icons.restaurant,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTodayStatItem(
                                    'Pending Bookings',
                                    _dashboardData['pendingBookings'].toString(),
                                    Icons.schedule,
                                    Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  child: _buildTodayStatItem(
                                    'Pending Orders',
                                    _dashboardData['pendingOrders'].toString(),
                                    Icons.pending_actions,
                                    Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Revenue Chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Revenue',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                                            return Text(months[value.toInt()]);
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _dashboardData['monthlyRevenue']
                                          .asMap()
                                          .entries
                                          .map<FlSpot>((entry) => FlSpot(
                                                entry.key.toDouble(),
                                                entry.value['revenue'].toDouble(),
                                              ))
                                          .toList(),
                                      isCurved: true,
                                      color: theme.colorScheme.primary,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Actions',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildActionChip(
                                  'Manage Bookings',
                                  Icons.hotel,
                                  () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const AdminBookingsScreen()),
                                  ),
                                ),
                                _buildActionChip(
                                  'Manage Orders',
                                  Icons.restaurant,
                                  () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                                  ),
                                ),
                                _buildActionChip(
                                  'Manage Users',
                                  Icons.people,
                                  () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                                  ),
                                ),
                                _buildActionChip(
                                  'View Reports',
                                  Icons.analytics,
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Reports feature coming soon'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback? onTap) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (onTap != null) Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                ],
              ),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStatItem(String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onPressed) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
