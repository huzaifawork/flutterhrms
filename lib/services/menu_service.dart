import 'dart:convert';
import '../data/models/menu_item_model.dart';
import 'api_service.dart';

class MenuService {
  // Singleton pattern
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;
  MenuService._internal();

  Future<List<MenuItemModel>> getMenuItems() async {
    try {
      print('Fetching menu items...');

      final response = await APIService.instance.get('api/menus');

      print('Menu items response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Successfully loaded ${data.length} menu items');
        return data.map((item) => _mapApiItemToModel(item)).toList();
      } else {
        print(
            'Failed to load menu items: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load menu items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching menu items: $e');
      // Fallback to sample data if the API call fails
      return _sampleMenuItems;
    }
  }

  Future<List<MenuItemModel>> getMenuItemsByCategory(String category) async {
    try {
      final response =
          await APIService.instance.get('api/menus/category/$category');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => _mapApiItemToModel(item)).toList();
      } else {
        throw Exception(
            'Failed to load menu items by category: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching menu items by category: $e');
      // Fallback to filtered sample data if the API call fails
      return _sampleMenuItems
          .where((item) => item.category == category)
          .toList();
    }
  }

  Future<List<String>> getCategories() async {
    try {
      // Get all menu items first
      final items = await getMenuItems();
      // Extract unique categories
      final categories = items.map((item) => item.category).toSet().toList();
      categories.sort();
      return ['All', ...categories]; // Add 'All' as the first category
    } catch (e) {
      print('Error fetching categories: $e');
      return _categories;
    }
  }

  Future<MenuItemModel?> getMenuItem(String id) async {
    try {
      final response = await APIService.instance.get('api/menus/$id');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // API might return either a single object or an array with one object
        if (data is List && data.isNotEmpty) {
          // Handle array response
          return _mapApiItemToModel(data.first);
        } else if (data is Map<String, dynamic>) {
          // Handle single object response
          return _mapApiItemToModel(data);
        }
      }

      print('Failed to load menu item: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Exception when loading menu item: $e');
      return null;
    }
  }

  // Maps API response to MenuItemModel
  MenuItemModel _mapApiItemToModel(Map<String, dynamic> apiItem) {
    try {
      print('Mapping menu item: ${apiItem['name']}');
      print('API item data: $apiItem');

      // Handle image URL
      String imageUrl =
          APIService.mapImageUrl(apiItem['image'] ?? apiItem['imageUrl'] ?? '');

      // Handle ingredients - ensure it's a list of strings
      List<String> ingredients = [];
      if (apiItem['ingredients'] != null) {
        if (apiItem['ingredients'] is List) {
          ingredients = List<String>.from(apiItem['ingredients']);
        } else if (apiItem['ingredients'] is String) {
          ingredients = [apiItem['ingredients']];
        }
      }

      // Handle price safely
      double price = 0.0;
      if (apiItem['price'] != null) {
        if (apiItem['price'] is num) {
          price = apiItem['price'].toDouble();
        } else if (apiItem['price'] is String) {
          price = double.tryParse(apiItem['price']) ?? 0.0;
        }
      }

      return MenuItemModel(
        id: apiItem['_id'] ?? apiItem['id'] ?? '',
        name: apiItem['name'] ?? 'Unnamed Item',
        category: apiItem['category'] ?? 'Other',
        price: price,
        description: apiItem['description'] ?? '',
        ingredients: ingredients,
        imageUrl: imageUrl,
        isAvailable: apiItem['availability'] ?? apiItem['isAvailable'] ?? true,
        isVegetarian: apiItem['isVegetarian'] ?? false,
        isVegan: apiItem['isVegan'] ?? false,
        isGlutenFree: apiItem['isGlutenFree'] ?? false,
        discountPercentage: apiItem['discountPercentage'] != null
            ? (apiItem['discountPercentage'] as num).toDouble()
            : null,
        rating: apiItem['rating'] != null
            ? (apiItem['rating'] as num).toDouble()
            : null,
        prepTimeMinutes:
            apiItem['prepTimeMinutes'] ?? apiItem['preparationTime'] ?? 15,
        nutritionalInfo: apiItem['nutritionalInfo'] != null
            ? Map<String, dynamic>.from(apiItem['nutritionalInfo'])
            : null,
      );
    } catch (e) {
      print('Error mapping menu item: $e');
      print('Problematic item: $apiItem');

      // Return a minimal valid object rather than crashing
      return MenuItemModel(
        id: apiItem['_id'] ??
            apiItem['id'] ??
            'error-${DateTime.now().millisecondsSinceEpoch}',
        name: apiItem['name'] ?? 'Error Loading Item',
        category: 'Error',
        price: 0.0,
        description: 'There was an error loading this menu item.',
        ingredients: [],
        imageUrl: '',
        isAvailable: true,
        isVegetarian: false,
        isVegan: false,
        isGlutenFree: false,
      );
    }
  }

  // Sample categories
  final List<String> _categories = [
    'All',
    'Starters',
    'Main Course',
    'Desserts',
    'Beverages',
    'Specials'
  ];

  // Sample menu items - adapted for the new model
  final List<MenuItemModel> _sampleMenuItems = [
    MenuItemModel(
      id: '1',
      name: 'Garden Fresh Salad',
      description:
          'Crisp mixed greens, cherry tomatoes, cucumber, red onion, and carrot with our house vinaigrette.',
      price: 8.99,
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?ixlib=rb-4.0.3&auto=format&fit=crop&w=600',
      category: 'Starters',
      ingredients: [
        'Mixed greens',
        'Cherry tomatoes',
        'Cucumber',
        'Red onion',
        'Carrot',
        'House vinaigrette'
      ],
      isVegetarian: true,
      isVegan: true,
      isGlutenFree: true,
      rating: 4.2,
    ),
    MenuItemModel(
      id: '2',
      name: 'Grilled Salmon',
      description:
          'Grilled Atlantic salmon served with seasonal vegetables and lemon butter sauce.',
      price: 22.99,
      imageUrl:
          'https://images.unsplash.com/photo-1580476262798-bddd9f4b7369?ixlib=rb-4.0.3&auto=format&fit=crop&w=600',
      category: 'Main Course',
      ingredients: [
        'Atlantic salmon',
        'Seasonal vegetables',
        'Lemon',
        'Butter',
        'Garlic',
        'Herbs'
      ],
      isGlutenFree: true,
      rating: 4.8,
    ),
    MenuItemModel(
      id: '3',
      name: 'Chocolate Lava Cake',
      description:
          'Warm chocolate cake with a molten center, served with vanilla ice cream.',
      price: 9.99,
      imageUrl:
          'https://images.unsplash.com/photo-1563805042-7684c019e1cb?ixlib=rb-4.0.3&auto=format&fit=crop&w=600',
      category: 'Desserts',
      ingredients: [
        'Dark chocolate',
        'Butter',
        'Eggs',
        'Flour',
        'Sugar',
        'Vanilla ice cream'
      ],
      isVegetarian: true,
      rating: 4.9,
    ),
    MenuItemModel(
      id: '4',
      name: 'Classic Mojito',
      description:
          'Refreshing cocktail with white rum, fresh lime juice, mint leaves, sugar, and soda water.',
      price: 9.99,
      imageUrl:
          'https://images.unsplash.com/photo-1570598912132-0ba1dc952b7d?ixlib=rb-4.0.3&auto=format&fit=crop&w=600',
      category: 'Beverages',
      ingredients: [
        'White rum',
        'Fresh lime juice',
        'Mint leaves',
        'Sugar',
        'Soda water',
        'Ice'
      ],
      isVegetarian: true,
      isVegan: true,
      isGlutenFree: true,
      rating: 4.7,
    ),
    MenuItemModel(
      id: '5',
      name: 'Signature Burger',
      description:
          'Our house specialty with Wagyu beef, truffle aioli, caramelized onions, and aged cheddar on a brioche bun.',
      price: 24.99,
      imageUrl:
          'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?ixlib=rb-4.0.3&auto=format&fit=crop&w=600',
      category: 'Specials',
      ingredients: [
        'Wagyu beef patty',
        'Truffle aioli',
        'Caramelized onions',
        'Aged cheddar',
        'Arugula',
        'Brioche bun'
      ],
      rating: 4.9,
    ),
  ];
}
// Minor change for contribution
