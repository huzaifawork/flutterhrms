import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../../core/utils/app_utils.dart';
import '../../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _userStats = {};
  Map<String, dynamic> _userHistory = {};
  bool _isLoadingStats = true;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    await Future.wait([
      _fetchUserStats(),
      _fetchUserHistory(),
    ]);
  }

  Future<void> _fetchUserStats() async {
    try {
      setState(() => _isLoadingStats = true);

      final dio = Dio();
      final token = await _getToken();
      print('[Profile] Token: ${token != null ? 'Available' : 'Null'}');

      if (token == null) {
        print('[Profile] No token available, using default values');
        setState(() {
          _userStats = {
            'totalBookings': 0,
            'totalOrders': 0,
            'totalReservations': 0,
            'totalSpent': 0,
            'loyaltyPoints': 0,
          };
          _isLoadingStats = false;
        });
        return;
      }

      print('[Profile] Fetching user data from APIs...');

      // Fetch data from the same APIs as web frontend with better error handling
      print('[Profile] Making API calls to fetch user data...');

      final responses = await Future.wait([
        dio
            .get('${APIService.baseUrl}/api/reservations/user',
                options: Options(headers: {'Authorization': 'Bearer $token'}))
            .catchError((e) {
          print('[Profile] Reservations API error: $e');
          if (e is DioException) {
            print(
                '[Profile] Reservations API status: ${e.response?.statusCode}');
            print('[Profile] Reservations API response: ${e.response?.data}');
          }
          return Response(data: [], requestOptions: RequestOptions(path: ''));
        }),
        dio.get('${APIService.baseUrl}/api/orders',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
            queryParameters: {'limit': 100}).catchError((e) {
          print('[Profile] Orders API error: $e');
          if (e is DioException) {
            print('[Profile] Orders API status: ${e.response?.statusCode}');
            print('[Profile] Orders API response: ${e.response?.data}');
          }
          return Response(
              data: {'orders': []}, requestOptions: RequestOptions(path: ''));
        }),
        dio
            .get('${APIService.baseUrl}/api/bookings/user',
                options: Options(headers: {'Authorization': 'Bearer $token'}))
            .catchError((e) {
          print('[Profile] Bookings API error: $e');
          if (e is DioException) {
            print('[Profile] Bookings API status: ${e.response?.statusCode}');
            print('[Profile] Bookings API response: ${e.response?.data}');
          }
          return Response(data: [], requestOptions: RequestOptions(path: ''));
        }),
      ]);

      final reservationsResponse = responses[0];
      final ordersResponse = responses[1];
      final bookingsResponse = responses[2];

      print('[Profile] API Responses received');
      print('[Profile] Reservations: ${reservationsResponse.data}');
      print('[Profile] Orders: ${ordersResponse.data}');
      print('[Profile] Bookings: ${bookingsResponse.data}');

      final reservations = reservationsResponse.data as List? ?? [];
      final orders = (ordersResponse.data as Map?)?['orders'] as List? ??
          (ordersResponse.data as List? ?? []);
      final bookings = bookingsResponse.data as List? ?? [];

      print(
          '[Profile] Parsed data - Reservations: ${reservations.length}, Orders: ${orders.length}, Bookings: ${bookings.length}');

      // Debug: Print sample data to see field structure
      if (orders.isNotEmpty) {
        print('[Profile] Sample order data: ${orders.first}');
      }
      if (bookings.isNotEmpty) {
        print('[Profile] Sample booking data: ${bookings.first}');
      }
      if (reservations.isNotEmpty) {
        print('[Profile] Sample reservation data: ${reservations.first}');
      }

      // Calculate total spent with proper field checking (backend uses totalPrice)
      double totalSpent = 0;

      for (var order in orders) {
        final amount = order['totalPrice'] ??
            order['totalAmount'] ??
            order['total'] ??
            order['amount'] ??
            0;
        totalSpent += (amount is num ? amount.toDouble() : 0);
        print('[Profile] Order amount: $amount (from totalPrice field)');
      }

      for (var booking in bookings) {
        final amount = booking['totalPrice'] ??
            booking['totalAmount'] ??
            booking['total'] ??
            booking['amount'] ??
            0;
        totalSpent += (amount is num ? amount.toDouble() : 0);
        print('[Profile] Booking amount: $amount (from totalPrice field)');
      }

      for (var reservation in reservations) {
        final amount = reservation['totalPrice'] ??
            reservation['totalAmount'] ??
            reservation['total'] ??
            reservation['amount'] ??
            0;
        totalSpent += (amount is num ? amount.toDouble() : 0);
        print('[Profile] Reservation amount: $amount (from totalPrice field)');
      }

      print('[Profile] Total spent calculated: $totalSpent');

      setState(() {
        _userStats = {
          'totalBookings': bookings.length,
          'totalOrders': orders.length,
          'totalReservations': reservations.length,
          'totalSpent': totalSpent,
          'loyaltyPoints': (totalSpent / 10).floor(),
        };
        _isLoadingStats = false;
      });
    } catch (e) {
      print('[Profile] Error fetching user stats: $e');
      setState(() {
        _userStats = {
          'totalBookings': 0,
          'totalOrders': 0,
          'totalReservations': 0,
          'totalSpent': 0,
          'loyaltyPoints': 0,
        };
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _fetchUserHistory() async {
    try {
      setState(() => _isLoadingHistory = true);

      final dio = Dio();
      final token = await _getToken();
      if (token == null) return;

      final response = await dio.get(
        '${APIService.baseUrl}/api/user/history',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      setState(() {
        _userHistory = response.data;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _userHistory = {};
        _isLoadingHistory = false;
      });
    }
  }

  Future<String?> _getToken() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Ensure the auth service has loaded the token from storage
      await authProvider.checkAuth();

      final token = authProvider.token;
      print(
          '[Profile] Token retrieved: ${token != null ? 'Available (${token.substring(0, 20)}...)' : 'Null'}');
      return token;
    } catch (e) {
      print('[Profile] Error getting token: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text('User not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(user, themeProvider),
          _buildStatsTab(),
          _buildHistoryTab(),
          _buildSettingsTab(themeProvider),
        ],
      ),
    );
  }

  Widget _buildProfileTab(dynamic user, ThemeProvider themeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Text(
                    AppUtils.getInitials(user.name),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome back, ${user.name}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  user.role,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                // Quick Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickStat('Activities',
                        '${(_userStats['totalBookings'] ?? 0) + (_userStats['totalOrders'] ?? 0) + (_userStats['totalReservations'] ?? 0)}'),
                    _buildQuickStat(
                        'Spent', 'PKR ${_userStats['totalSpent'] ?? 0}'),
                    _buildQuickStat(
                        'Points', '${_userStats['loyaltyPoints'] ?? 0}'),
                  ],
                ),
              ],
            ),
          ),
          // Personal information
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
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    'Email',
                    user.email,
                    Icons.email,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    'Phone',
                    user.phoneNumber,
                    Icons.phone,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    'Joined',
                    AppUtils.formatDate(user.createdAt),
                    Icons.calendar_today,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    context,
                    'Last Login',
                    user.lastLoginAt != null
                        ? AppUtils.formatRelativeTime(user.lastLoginAt!)
                        : 'N/A',
                    Icons.access_time,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isLoadingStats)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildStatCard(
                'Total Bookings',
                '${_userStats['totalBookings'] ?? 0}',
                Icons.hotel,
                Colors.blue),
            const SizedBox(height: 16),
            _buildStatCard('Total Orders', '${_userStats['totalOrders'] ?? 0}',
                Icons.restaurant, Colors.green),
            const SizedBox(height: 16),
            _buildStatCard(
                'Total Reservations',
                '${_userStats['totalReservations'] ?? 0}',
                Icons.table_bar,
                Colors.orange),
            const SizedBox(height: 16),
            _buildStatCard(
                'Total Spent',
                'PKR ${_userStats['totalSpent'] ?? 0}',
                Icons.attach_money,
                Colors.purple),
            const SizedBox(height: 16),
            _buildStatCard(
                'Loyalty Points',
                '${_userStats['loyaltyPoints'] ?? 0}',
                Icons.star,
                Colors.amber),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isLoadingHistory)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Recent Orders Section
            if (_userStats['totalOrders'] != null &&
                _userStats['totalOrders'] > 0) ...[
              _buildHistorySection(
                'Recent Orders',
                Icons.restaurant,
                Colors.green,
                'View your recent food orders',
                () => _navigateToOrderHistory(),
              ),
              const SizedBox(height: 16),
            ],

            // Recent Bookings Section
            if (_userStats['totalBookings'] != null &&
                _userStats['totalBookings'] > 0) ...[
              _buildHistorySection(
                'Room Bookings',
                Icons.hotel,
                Colors.blue,
                'View your room booking history',
                () => _navigateToBookingHistory(),
              ),
              const SizedBox(height: 16),
            ],

            // Recent Reservations Section
            if (_userStats['totalReservations'] != null &&
                _userStats['totalReservations'] > 0) ...[
              _buildHistorySection(
                'Table Reservations',
                Icons.table_bar,
                Colors.orange,
                'View your table reservation history',
                () => _navigateToReservationHistory(),
              ),
              const SizedBox(height: 16),
            ],

            // Activity Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Activity Summary',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Total Activities',
                        '${(_userStats['totalOrders'] ?? 0) + (_userStats['totalBookings'] ?? 0) + (_userStats['totalReservations'] ?? 0)}'),
                    _buildSummaryRow(
                        'Total Spent', 'PKR ${_userStats['totalSpent'] ?? 0}'),
                    _buildSummaryRow('Loyalty Points',
                        '${_userStats['loyaltyPoints'] ?? 0}'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _refreshHistory(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh History'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Empty state if no history
            if ((_userStats['totalOrders'] ?? 0) == 0 &&
                (_userStats['totalBookings'] ?? 0) == 0 &&
                (_userStats['totalReservations'] ?? 0) == 0) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Activity Yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start by placing an order, booking a room, or making a reservation!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Helper method to build history sections
  Widget _buildHistorySection(String title, IconData icon, Color color,
      String subtitle, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // Helper method to build summary rows
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToOrderHistory() {
    Navigator.of(context).pushNamed('/my-orders');
  }

  void _navigateToBookingHistory() {
    Navigator.of(context).pushNamed('/my-bookings');
  }

  void _navigateToReservationHistory() {
    Navigator.of(context).pushNamed('/my-reservations');
  }

  void _refreshHistory() {
    setState(() {
      _isLoadingHistory = true;
    });
    _fetchUserData().then((_) {
      setState(() {
        _isLoadingHistory = false;
      });
    });
  }

  Widget _buildSettingsTab(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: Text(
                      themeProvider.isDarkMode ? 'Enabled' : 'Disabled',
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                    secondary: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                  ),
                  ListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Manage notification settings'),
                    leading: const Icon(Icons.notifications),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Notification settings will be implemented soon',
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Privacy Settings'),
                    subtitle: const Text('Manage privacy preferences'),
                    leading: const Icon(Icons.privacy_tip),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Privacy settings will be implemented soon',
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Help & Support'),
                    subtitle: const Text('Get help and contact support'),
                    leading: const Icon(Icons.help),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Help & support will be implemented soon',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await AppUtils.showConfirmationDialog(
                  context,
                  title: 'Logout',
                  message: 'Are you sure you want to logout?',
                  confirmText: 'Logout',
                  cancelText: 'Cancel',
                );

                if (confirm && context.mounted) {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
