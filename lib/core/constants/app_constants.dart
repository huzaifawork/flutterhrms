class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // App Info
  static const String appName = 'HRMS';
  static const String appVersion = '1.0.0';

  // API Configuration - Backend Server
  static const String baseUrl = 'http://localhost:8080';

  // Authentication Endpoints
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String registerEndpoint = '$baseUrl/auth/signup';
  static const String googleAuthEndpoint = '$baseUrl/auth/google/google';

  // API Endpoints
  static const String roomsEndpoint = '$baseUrl/api/rooms';
  static const String tablesEndpoint = '$baseUrl/api/tables';
  static const String menuEndpoint = '$baseUrl/api/menus';
  static const String ordersEndpoint = '$baseUrl/api/orders';
  static const String bookingsEndpoint = '$baseUrl/api/bookings';
  static const String reservationsEndpoint = '$baseUrl/api/reservations';
  static const String usersEndpoint = '$baseUrl/api/user';
  static const String adminEndpoint = '$baseUrl/api/admin';
  static const String feedbackEndpoint = '$baseUrl/api/feedback';
  static const String paymentEndpoint = '$baseUrl/api/payment';
  static const String staffEndpoint = '$baseUrl/api/staff';
  static const String shiftEndpoint = '$baseUrl/api/shift';

  // Shared Preferences Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String isDarkModeKey = 'is_dark_mode';
  static const String languageKey = 'language';

  // Default Values
  static const int defaultPageSize = 10;
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleStaff = 'staff';
  static const String roleCustomer = 'customer';

  // Room Types
  static const String roomTypeStandard = 'standard';
  static const String roomTypeDeluxe = 'deluxe';
  static const String roomTypeSuite = 'suite';
  static const String roomTypeExecutive = 'executive';

  // Table Status
  static const String tableStatusAvailable = 'available';
  static const String tableStatusReserved = 'reserved';
  static const String tableStatusOccupied = 'occupied';
  static const String tableStatusMaintenance = 'maintenance';

  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusConfirmed = 'confirmed';
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCompleted = 'completed';
  static const String orderStatusCancelled = 'cancelled';

  // Payment Methods
  static const String paymentMethodCash = 'cash';
  static const String paymentMethodCreditCard = 'credit_card';
  static const String paymentMethodDebitCard = 'debit_card';
  static const String paymentMethodUPI = 'upi';
  static const String paymentMethodWallet = 'wallet';
}
