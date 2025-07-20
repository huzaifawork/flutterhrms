import '../config/environment.dart';

class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();

  // API Configuration - Backend Server
  static String get baseUrl => '${Environment.currentApiUrl}/api';

  // Authentication Endpoints
  static String get loginEndpoint => '${Environment.currentApiUrl}/auth/login';
  static String get registerEndpoint =>
      '${Environment.currentApiUrl}/auth/signup';
  static String get googleAuthEndpoint =>
      '${Environment.currentApiUrl}/auth/google/google';

  // API Endpoints
  static String get roomsEndpoint => '$baseUrl/rooms';
  static String get tablesEndpoint => '$baseUrl/tables';
  static String get menuEndpoint => '$baseUrl/menus';
  static String get ordersEndpoint => '$baseUrl/orders';
  static String get bookingsEndpoint => '$baseUrl/bookings';
  static String get reservationsEndpoint => '$baseUrl/reservations';
  static String get usersEndpoint => '$baseUrl/user';
  static String get adminEndpoint => '$baseUrl/admin';
  static String get feedbackEndpoint => '$baseUrl/feedback';
  static String get paymentEndpoint => '$baseUrl/payment';
  static String get staffEndpoint => '$baseUrl/staff';
  static String get shiftEndpoint => '$baseUrl/shift';

  // Recommendation Endpoints
  static String get foodRecommendationsEndpoint =>
      '$baseUrl/food-recommendations';
  static String get tableRecommendationsEndpoint => '$baseUrl/tables';

  // Shared Preferences Keys
  static const String tokenKey = 'token';
  static const String userIdKey = 'userId';
  static const String userRoleKey = 'userRole';
  static const String isDarkModeKey = 'isDarkMode';
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
  static const String tableStatusAvailable = 'Available';
  static const String tableStatusReserved = 'Reserved';
  static const String tableStatusOccupied = 'Occupied';
  static const String tableStatusMaintenance = 'Maintenance';

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

  // Recommendation Types
  static const String recommendationTypeFood = 'food';
  static const String recommendationTypeTable = 'table';
  static const String recommendationTypeRoom = 'room';

  // Interaction Types
  static const String interactionTypeView = 'view';
  static const String interactionTypeOrder = 'order';
  static const String interactionTypeRating = 'rating';
  static const String interactionTypeFavorite = 'favorite';
  static const String interactionTypeBooking = 'booking';
  static const String interactionTypeInquiry = 'inquiry';
  static const String interactionTypeShare = 'share';

  // Recommendation Confidence Levels
  static const String confidenceHigh = 'high';
  static const String confidenceMedium = 'medium';
  static const String confidenceLow = 'low';

  // Recommendation Reasons
  static const String reasonCollaborativeFiltering = 'collaborative_filtering';
  static const String reasonContentBased = 'content_based';
  static const String reasonPopularity = 'popularity';
  static const String reasonHybrid = 'hybrid';
  static const String reasonPakistaniCuisine = 'pakistani_cuisine';

  // Spice Levels
  static const String spiceLevelMild = 'mild';
  static const String spiceLevelMedium = 'medium';
  static const String spiceLevelHot = 'hot';
  static const String spiceLevelVeryHot = 'very_hot';

  // Dietary Tags
  static const String dietaryTagHalal = 'halal';
  static const String dietaryTagVegetarian = 'vegetarian';
  static const String dietaryTagVegan = 'vegan';
  static const String dietaryTagGlutenFree = 'gluten-free';
  static const String dietaryTagDairyFree = 'dairy-free';

  // Table Occasions
  static const String occasionRomantic = 'Romantic';
  static const String occasionBusiness = 'Business';
  static const String occasionFamily = 'Family';
  static const String occasionFriends = 'Friends';
  static const String occasionCelebration = 'Celebration';
  static const String occasionCasual = 'Casual';

  // Time Slots
  static const String timeSlotLunch = 'Lunch';
  static const String timeSlotEarlyDinner = 'Early Dinner';
  static const String timeSlotPrimeDinner = 'Prime Dinner';
  static const String timeSlotLateDinner = 'Late Dinner';

  // Table Ambiance
  static const String ambianceFormal = 'Formal';
  static const String ambianceIntimate = 'Intimate';
  static const String ambianceSocial = 'Social';
  static const String ambianceLively = 'Lively';

  // Price Tiers
  static const String priceTierBudget = 'Budget';
  static const String priceTierMidRange = 'Mid-range';
  static const String priceTierPremium = 'Premium';
  static const String priceTierLuxury = 'Luxury';
}
// Minor change for contribution
