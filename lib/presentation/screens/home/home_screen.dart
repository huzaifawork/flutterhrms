import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/cart_provider.dart';
import '../auth/login_screen.dart';
import '../bookings/room_booking_page.dart';
import '../reservations/table_reservation_page.dart';
import '../orders/menu_ordering_page.dart';
import 'profile_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../orders/my_orders_screen.dart';
import '../orders/cart_screen.dart';
import '../reservations/my_reservations_screen.dart';
import '../admin/admin_dashboard_screen.dart';

import '../../../services/menu_service.dart';
import '../../../services/room_service.dart';
import '../../../services/table_service.dart';
import '../../../data/models/menu_item_model.dart';
import '../../../data/models/room_model.dart';

import '../../../data/models/table_model.dart';
import '../../../services/api_service.dart';

import '../../../widgets/home/featured_rooms_section.dart';
import '../../../widgets/home/featured_tables_section.dart';
import '../../../widgets/home/most_popular_items_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const RoomBookingPage(),
    const TableReservationPage(),
    const MenuOrderingPage(),
  ];

  // Method to update selected index from other widgets
  void updateSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'HRMS',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          // Debug button (only in development)

          // Cart Icon with Badge
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shopping_cart,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.brightness_6,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              final themeProvider =
                  Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.account_circle,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
        ),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hotel_outlined),
            activeIcon: Icon(Icons.hotel),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_bar_outlined),
            activeIcon: Icon(Icons.table_bar),
            label: 'Tables',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // Services
  final _menuService = MenuService();
  final _roomService = RoomService();
  final _tableService = TableService();

  // Data futures
  Future<List<MenuItemModel>> _menuItemsFuture = Future.value([]);
  Future<List<RoomModel>> _roomsFuture = Future.value([]);
  Future<List<TableModel>> _tablesFuture = Future.value([]);

  // API Status
  bool _isApiAvailable = false;
  bool _isLoadingData = true;
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
    _initialLoadData();
  }

  Future<void> _initialLoadData() async {
    setState(() {
      _isLoadingData = true;
    });

    await _checkApiAvailability();
    await _loadData();

    setState(() {
      _isLoadingData = false;
      _hasLoadedData = true;
    });
  }

  Future<void> _checkApiAvailability() async {
    try {
      final isAvailable = await APIService.instance.checkApiAvailability();
      setState(() {
        _isApiAvailable = isAvailable;
      });
    } catch (e) {
      setState(() {
        _isApiAvailable = false;
      });
      print('Error checking API availability: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Perform all API calls in parallel for efficiency
      final menuItemsFuture = _menuService.getMenuItems();
      final roomsFuture = _roomService.getRooms();
      final tablesFuture = _tableService.getTables();

      // Wait for all futures to complete
      final results =
          await Future.wait([menuItemsFuture, roomsFuture, tablesFuture]);

      // Update the state with results
      setState(() {
        _menuItemsFuture = Future.value(results[0] as List<MenuItemModel>);
        _roomsFuture = Future.value(results[1] as List<RoomModel>);
        _tablesFuture = Future.value(results[2] as List<TableModel>);
        _isLoadingData = false;
        _hasLoadedData = true;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoadingData = false;
        _hasLoadedData = true; // Still mark as loaded to show empty states
      });
    }
  }

  Future<void> _refreshData() async {
    await _checkApiAvailability();
    await _loadData();
  }

  // Safer image widget that handles errors
  Widget _buildNetworkImage(String? imageUrl,
      {double height = 100, double width = 220}) {
    final fallbackUrl =
        'https://via.placeholder.com/${width.toInt()}x${height.toInt()}?text=No+Image';

    return Image.network(
      imageUrl ?? fallbackUrl,
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // If there's an error loading the image, show a placeholder
        return Container(
          height: height,
          width: width,
          color: Colors.grey.shade300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 24,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              Text(
                'Image not available',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Status Banner - shown when API is unavailable
            if (!_isApiAvailable)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: theme.colorScheme.errorContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          color: theme.colorScheme.onErrorContainer,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Backend server unavailable',
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _refreshData,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'RETRY',
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 24, top: 4, bottom: 4),
                      child: Text(
                        'Using sample data while trying to connect to ${APIService.baseUrl}',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer
                              .withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.onErrorContainer,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              kIsWeb
                                  ? 'If running locally, check for CORS issues or start your backend server.'
                                  : 'Check if your backend server is running and accessible.',
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer
                                    .withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Hero Section with Welcome Banner
            Stack(
              alignment: Alignment.center,
              children: [
                // Background Image with Overlay
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const NetworkImage(
                        'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?ixlib=rb-4.0.3&auto=format&fit=crop&w=1170&q=80',
                      ),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.7),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                ),
                // Welcome Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome to HRMS',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your complete hotel & restaurant solution',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        context,
                        'Book Room',
                        Icons.hotel,
                        theme.colorScheme.secondary,
                        () {
                          final homeScreenState = context
                              .findAncestorStateOfType<_HomeScreenState>();
                          homeScreenState?.updateSelectedIndex(1);
                        },
                      ),
                      _buildQuickAction(
                        context,
                        'Reserve Table',
                        Icons.table_bar,
                        theme.colorScheme.primary,
                        () {
                          final homeScreenState = context
                              .findAncestorStateOfType<_HomeScreenState>();
                          homeScreenState?.updateSelectedIndex(2);
                        },
                      ),
                      _buildQuickAction(
                        context,
                        'Order Food',
                        Icons.restaurant_menu,
                        theme.colorScheme.tertiary,
                        () {
                          final homeScreenState = context
                              .findAncestorStateOfType<_HomeScreenState>();
                          homeScreenState?.updateSelectedIndex(3);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        context,
                        'My Bookings',
                        Icons.bookmark,
                        Colors.green,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const MyBookingsScreen()),
                          );
                        },
                      ),
                      _buildQuickAction(
                        context,
                        'My Orders',
                        Icons.receipt_long,
                        Colors.orange,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const MyOrdersScreen()),
                          );
                        },
                      ),
                      _buildQuickAction(
                        context,
                        'My Reservations',
                        Icons.table_restaurant,
                        Colors.purple,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const MyReservationsScreen()),
                          );
                        },
                      ),
                      // Admin Dashboard - only show for admin users
                      if (Provider.of<AuthProvider>(context, listen: false)
                              .currentUser
                              ?.role ==
                          'admin')
                        _buildQuickAction(
                          context,
                          'Admin Dashboard',
                          Icons.admin_panel_settings,
                          Colors.red,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const AdminDashboardScreen()),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Divider
            Divider(color: theme.dividerTheme.color, height: 1),

            // Featured Rooms Section - AI-Powered Recommendations
            const FeaturedRoomsSection(),

            // Featured Tables Section - AI-Powered Recommendations
            const FeaturedTablesSection(),

            // Most Popular Items Section
            const MostPopularItemsSection(),

            // Our Services Section
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surface.withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Our Services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _buildServiceCard(
                        context,
                        'Online Booking & Payments',
                        'Simplify booking processes with secure online payments.',
                        Icons.payment,
                      ),
                      const SizedBox(height: 12),
                      _buildServiceCard(
                        context,
                        'Staff Management',
                        'Efficiently manage staff schedules and roles.',
                        Icons.people,
                      ),
                      const SizedBox(height: 12),
                      _buildServiceCard(
                        context,
                        'Real-Time Availability',
                        'Track room and table availability in real-time.',
                        Icons.access_time,
                      ),
                      const SizedBox(height: 12),
                      _buildServiceCard(
                        context,
                        'Table Reservations',
                        'Easily reserve tables for guests with our system.',
                        Icons.table_bar,
                      ),
                      const SizedBox(height: 12),
                      _buildServiceCard(
                        context,
                        'Analytics Dashboard',
                        'Gain insights with detailed reports and analytics.',
                        Icons.analytics,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Contact Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: theme.colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact details in a more compact format
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '123 Ocean Avenue, Tropical Beach, FL',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+1 (305) 555-1234',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'info@hrmsapp.com',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Copyright text
                  Center(
                    child: Text(
                      '© 2024 HRMS App. All rights reserved.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loading indicator
            if (_isLoadingData)
              Center(
                child: Container(
                  height: 200,
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connecting to server...',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(
    BuildContext context,
    String title,
    String price,
    String imageUrl,
    List<String> features,
    VoidCallback onBook,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Stack(
              children: [
                _buildNetworkImage(imageUrl, height: 100, width: 220),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Room Details
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                ...features
                    .map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('BOOK NOW'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(
    BuildContext context,
    String tableNumber,
    String capacity,
    String features,
    VoidCallback onReserve, {
    String? imageUrl,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading table image: $imageUrl - $error');
                        return Container(
                          color: Colors.grey.shade300,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.grey.shade600,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Image Error',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: Icon(
                        Icons.table_bar,
                        color: Colors.grey.shade600,
                        size: 32,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(features, theme),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _getStatusText(features),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tableNumber,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      capacity,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onReserve,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('RESERVE'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String location, ThemeData theme) {
    // For now, we're using the location field from our adapter
    // but in a real implementation, we'd use the table's status
    if (location.toLowerCase().contains('window')) {
      return theme.colorScheme.primary.withOpacity(0.9); // Available
    } else if (location.toLowerCase().contains('vip') ||
        location.toLowerCase().contains('private')) {
      return Colors.amber.shade700; // Special/VIP
    } else if (location.toLowerCase().contains('corner')) {
      return Colors.green.shade600; // Available
    } else if (location.toLowerCase().contains('maintenance')) {
      return Colors.grey.shade700; // Under Maintenance
    } else {
      return theme.colorScheme.primary.withOpacity(0.9); // Default
    }
  }

  String _getStatusText(String location) {
    // For now, we're using the location field from our adapter
    // but in a real implementation, we'd use the table's status
    if (location.toLowerCase().contains('window')) {
      return 'Available';
    } else if (location.toLowerCase().contains('vip') ||
        location.toLowerCase().contains('private')) {
      return 'VIP';
    } else if (location.toLowerCase().contains('corner')) {
      return 'Available';
    } else if (location.toLowerCase().contains('maintenance')) {
      return 'Maintenance';
    } else {
      return 'Available'; // Default
    }
  }

  Widget _buildPopularMenuItem(
    BuildContext context,
    String category,
    String name,
    String price,
    VoidCallback onTap, {
    String? imageUrl,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: _buildNetworkImage(imageUrl, height: 140, width: 180),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Food Name
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Row(
                    children: [
                      Text(
                        '\$$price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: theme.colorScheme.tertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
