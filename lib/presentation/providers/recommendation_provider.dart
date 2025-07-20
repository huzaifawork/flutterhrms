import 'package:flutter/foundation.dart';
import '../../models/recommendation_model.dart';
import '../../services/recommendation_service.dart';

class RecommendationProvider with ChangeNotifier {
  // Food Recommendations
  List<FoodRecommendation> _foodRecommendations = [];
  List<FoodRecommendation> _pakistaniFoodRecommendations = [];
  List<FoodRecommendation> _popularFoodItems = [];
  
  // Table Recommendations
  List<TableRecommendation> _tableRecommendations = [];
  List<dynamic> _popularTables = [];
  
  // User Preferences
  UserPreferences? _userPreferences;
  
  // Loading States
  bool _isLoadingFoodRecommendations = false;
  bool _isLoadingTableRecommendations = false;
  bool _isLoadingPopularItems = false;
  
  // Error States
  String? _foodRecommendationsError;
  String? _tableRecommendationsError;
  
  // Filters
  String _selectedCuisine = 'All';
  String _selectedOccasion = 'Casual';
  int _partySize = 2;
  String _timeSlot = 'Prime Dinner';

  // Getters
  List<FoodRecommendation> get foodRecommendations => _foodRecommendations;
  List<FoodRecommendation> get pakistaniFoodRecommendations => _pakistaniFoodRecommendations;
  List<FoodRecommendation> get popularFoodItems => _popularFoodItems;
  List<TableRecommendation> get tableRecommendations => _tableRecommendations;
  List<dynamic> get popularTables => _popularTables;
  UserPreferences? get userPreferences => _userPreferences;
  
  bool get isLoadingFoodRecommendations => _isLoadingFoodRecommendations;
  bool get isLoadingTableRecommendations => _isLoadingTableRecommendations;
  bool get isLoadingPopularItems => _isLoadingPopularItems;
  
  String? get foodRecommendationsError => _foodRecommendationsError;
  String? get tableRecommendationsError => _tableRecommendationsError;
  
  String get selectedCuisine => _selectedCuisine;
  String get selectedOccasion => _selectedOccasion;
  int get partySize => _partySize;
  String get timeSlot => _timeSlot;

  // Food Recommendations Methods
  Future<void> loadFoodRecommendations({String? userId, int count = 10}) async {
    _isLoadingFoodRecommendations = true;
    _foodRecommendationsError = null;
    notifyListeners();

    try {
      final response = await RecommendationService.getFoodRecommendations(
        userId: userId,
        count: count,
      );

      if (response['success'] == true) {
        final recommendations = response['recommendations'] ?? [];
        _foodRecommendations = recommendations
            .map<FoodRecommendation>((item) => FoodRecommendation.fromJson(item))
            .toList();
        
        if (response['preferences'] != null) {
          _userPreferences = UserPreferences.fromJson(response['preferences']);
        }
      } else {
        _foodRecommendationsError = response['message'] ?? 'Failed to load recommendations';
      }
    } catch (e) {
      _foodRecommendationsError = e.toString();
      debugPrint('Error loading food recommendations: $e');
    } finally {
      _isLoadingFoodRecommendations = false;
      notifyListeners();
    }
  }

  Future<void> loadPakistaniFoodRecommendations({String? userId, int count = 10}) async {
    _isLoadingFoodRecommendations = true;
    _foodRecommendationsError = null;
    notifyListeners();

    try {
      final response = await RecommendationService.getPakistaniFoodRecommendations(
        userId: userId,
        count: count,
      );

      if (response['success'] == true) {
        final recommendations = response['recommendations'] ?? [];
        _pakistaniFoodRecommendations = recommendations
            .map<FoodRecommendation>((item) => FoodRecommendation.fromJson(item))
            .toList();
      } else {
        _foodRecommendationsError = response['message'] ?? 'Failed to load Pakistani recommendations';
      }
    } catch (e) {
      _foodRecommendationsError = e.toString();
      debugPrint('Error loading Pakistani food recommendations: $e');
    } finally {
      _isLoadingFoodRecommendations = false;
      notifyListeners();
    }
  }

  Future<void> loadPopularFoodItems({int count = 10}) async {
    _isLoadingPopularItems = true;
    notifyListeners();

    try {
      final response = await RecommendationService.getPopularFoodItems(count: count);

      if (response['success'] == true) {
        final items = response['popularItems'] ?? response['recommendations'] ?? [];
        _popularFoodItems = items
            .map<FoodRecommendation>((item) => FoodRecommendation.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading popular food items: $e');
    } finally {
      _isLoadingPopularItems = false;
      notifyListeners();
    }
  }

  // Table Recommendations Methods
  Future<void> loadTableRecommendations({
    String? userId,
    String? occasion,
    int? partySize,
    String? timeSlot,
    int numRecommendations = 10,
  }) async {
    _isLoadingTableRecommendations = true;
    _tableRecommendationsError = null;
    notifyListeners();

    try {
      final response = await RecommendationService.getTableRecommendations(
        userId: userId,
        occasion: occasion ?? _selectedOccasion,
        partySize: partySize ?? _partySize,
        timeSlot: timeSlot ?? _timeSlot,
        numRecommendations: numRecommendations,
      );

      if (response['success'] == true) {
        final recommendations = response['recommendations'] ?? [];
        _tableRecommendations = recommendations
            .map<TableRecommendation>((item) => TableRecommendation.fromJson(item))
            .toList();
      } else {
        _tableRecommendationsError = response['message'] ?? 'Failed to load table recommendations';
      }
    } catch (e) {
      _tableRecommendationsError = e.toString();
      debugPrint('Error loading table recommendations: $e');
    } finally {
      _isLoadingTableRecommendations = false;
      notifyListeners();
    }
  }

  Future<void> loadPopularTables({int limit = 10}) async {
    try {
      final response = await RecommendationService.getPopularTables(limit: limit);

      if (response['success'] == true) {
        _popularTables = response['popularTables'] ?? [];
      }
    } catch (e) {
      debugPrint('Error loading popular tables: $e');
    }
    notifyListeners();
  }

  // Interaction Recording Methods
  Future<bool> recordFoodInteraction({
    required String menuItemId,
    required String interactionType,
    int? rating,
    int orderQuantity = 1,
  }) async {
    try {
      final success = await RecommendationService.recordFoodInteraction(
        menuItemId: menuItemId,
        interactionType: interactionType,
        rating: rating,
        orderQuantity: orderQuantity,
      );

      if (success && interactionType == 'rating') {
        // Refresh recommendations after rating
        await loadFoodRecommendations();
      }

      return success;
    } catch (e) {
      debugPrint('Error recording food interaction: $e');
      return false;
    }
  }

  Future<bool> recordTableInteraction({
    required String tableId,
    required String interactionType,
    int? rating,
    int? sessionDuration,
    Map<String, dynamic>? context,
  }) async {
    try {
      final success = await RecommendationService.recordTableInteraction(
        tableId: tableId,
        interactionType: interactionType,
        rating: rating,
        sessionDuration: sessionDuration,
        context: context,
      );

      if (success && (interactionType == 'rating' || interactionType == 'booking')) {
        // Refresh recommendations after rating or booking
        await loadTableRecommendations();
      }

      return success;
    } catch (e) {
      debugPrint('Error recording table interaction: $e');
      return false;
    }
  }

  Future<bool> rateMenuItem({
    required String menuItemId,
    required int rating,
  }) async {
    try {
      final success = await RecommendationService.rateMenuItem(
        menuItemId: menuItemId,
        rating: rating,
      );

      if (success) {
        // Refresh recommendations after rating
        await loadFoodRecommendations();
      }

      return success;
    } catch (e) {
      debugPrint('Error rating menu item: $e');
      return false;
    }
  }

  Future<bool> recordOrderInteractions({
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      return await RecommendationService.recordOrderInteractions(items: items);
    } catch (e) {
      debugPrint('Error recording order interactions: $e');
      return false;
    }
  }

  // Filter Methods
  void setSelectedCuisine(String cuisine) {
    _selectedCuisine = cuisine;
    notifyListeners();
  }

  void setSelectedOccasion(String occasion) {
    _selectedOccasion = occasion;
    notifyListeners();
  }

  void setPartySize(int size) {
    _partySize = size;
    notifyListeners();
  }

  void setTimeSlot(String slot) {
    _timeSlot = slot;
    notifyListeners();
  }

  // Utility Methods
  void clearRecommendations() {
    _foodRecommendations.clear();
    _pakistaniFoodRecommendations.clear();
    _popularFoodItems.clear();
    _tableRecommendations.clear();
    _popularTables.clear();
    _userPreferences = null;
    _foodRecommendationsError = null;
    _tableRecommendationsError = null;
    notifyListeners();
  }

  void clearErrors() {
    _foodRecommendationsError = null;
    _tableRecommendationsError = null;
    notifyListeners();
  }
}
