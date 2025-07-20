import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/cart_provider.dart';

import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/bookings/room_booking_page.dart';
import 'presentation/screens/reservations/table_reservation_page.dart';
import 'presentation/screens/orders/menu_ordering_page.dart';
import 'presentation/screens/orders/cart_screen.dart';
import 'presentation/screens/orders/my_orders_screen.dart';
import 'presentation/screens/booking/my_bookings_screen.dart';
import 'presentation/screens/reservations/my_reservations_screen.dart';

import 'services/booking_service.dart';
import 'services/order_service.dart';
import 'services/reservation_service.dart';
import 'services/payment_service.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();

  // Initialize services (you may handle error/await if required)
  BookingService().initialize();
  OrderService().initialize();
  ReservationService().initialize();
  PaymentService().initialize();
  UserService().initialize();

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

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.primaryDarkBlue,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

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
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/room-booking':
            return MaterialPageRoute(builder: (_) => const RoomBookingPage());
          case '/reserve-table':
            return MaterialPageRoute(
                builder: (_) => const TableReservationPage());
          case '/order-food':
            return MaterialPageRoute(builder: (_) => const MenuOrderingPage());
          case '/cart':
            return MaterialPageRoute(builder: (_) => const CartScreen());
          case '/my-orders':
            return MaterialPageRoute(builder: (_) => const MyOrdersScreen());
          case '/my-bookings':
            return MaterialPageRoute(builder: (_) => const MyBookingsScreen());
          case '/my-reservations':
            return MaterialPageRoute(
                builder: (_) => const MyReservationsScreen());
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
