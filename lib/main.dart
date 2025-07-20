import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/bookings/room_booking_page.dart';
import 'presentation/screens/reservations/table_reservation_page.dart';
import 'presentation/screens/orders/menu_ordering_page.dart';
import 'presentation/screens/orders/cart_screen.dart';
import 'presentation/screens/orders/my_orders_screen.dart';
import 'presentation/screens/booking/my_bookings_screen.dart';
import 'presentation/screens/reservations/my_reservations_screen.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'services/booking_service.dart';
import 'services/order_service.dart';
import 'services/reservation_service.dart';
import 'services/payment_service.dart';
import 'services/user_service.dart';
import 'services/recommendation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize all services
  BookingService().initialize();
  OrderService().initialize();
  ReservationService().initialize();
  PaymentService().initialize();
  UserService().initialize();

  // Get theme preference - default to dark mode to match website design
  final isDarkMode = prefs.getBool('is_dark_mode') ?? true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ThemeProvider(isDarkMode: isDarkMode)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Set system UI overlay style to match dark theme
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.primaryDarkBlue,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'HRMS App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case '/room-booking':
            return MaterialPageRoute(
              builder: (context) => const RoomBookingPage(),
              settings: settings,
            );
          case '/reserve-table':
            return MaterialPageRoute(
              builder: (context) => const TableReservationPage(),
              settings: settings,
            );
          case '/order-food':
            return MaterialPageRoute(
              builder: (context) => const MenuOrderingPage(),
              settings: settings,
            );
          case '/cart':
            return MaterialPageRoute(builder: (context) => const CartScreen());
          case '/my-orders':
            return MaterialPageRoute(
              builder: (context) => const MyOrdersScreen(),
            );
          case '/my-bookings':
            return MaterialPageRoute(
              builder: (context) => const MyBookingsScreen(),
            );
          case '/my-reservations':
            return MaterialPageRoute(
              builder: (context) => const MyReservationsScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
            );
        }
      },
    );
  }
}
// Minor change for contribution
