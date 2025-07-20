class MenuItemModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final List<String> ingredients;
  final String imageUrl;
  final bool isAvailable;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final double? discountPercentage;
  final double? rating;
  final int? prepTimeMinutes;
  final Map<String, dynamic>? nutritionalInfo;
  final double averageRating;
  final int totalRatings;
  final String? image;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.ingredients,
    required this.imageUrl,
    this.isAvailable = true,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    this.discountPercentage,
    this.rating,
    this.prepTimeMinutes,
    this.nutritionalInfo,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.image,
  });

  // Create a menu item from JSON data
  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Item',
      category: json['category'] as String? ?? 'Other',
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      description: json['description'] as String? ?? 'No description available',
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'] as List)
          : [],
      imageUrl: json['imageUrl'] as String? ??
          'https://via.placeholder.com/300x200?text=No+Image',
      isAvailable: json['isAvailable'] as bool? ?? true,
      isVegetarian: json['isVegetarian'] as bool? ?? false,
      isVegan: json['isVegan'] as bool? ?? false,
      isGlutenFree: json['isGlutenFree'] as bool? ?? false,
      discountPercentage: json['discountPercentage'] != null
          ? (json['discountPercentage'] as num).toDouble()
          : null,
      rating:
          json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      prepTimeMinutes: json['prepTimeMinutes'] as int?,
      nutritionalInfo: json['nutritionalInfo'] as Map<String, dynamic>?,
      averageRating: json['averageRating'] != null
          ? (json['averageRating'] as num).toDouble()
          : 0.0,
      totalRatings: json['totalRatings'] as int? ?? 0,
      image: json['image'] as String?,
    );
  }

  // Convert menu item to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'ingredients': ingredients,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'prepTimeMinutes': prepTimeMinutes,
      'nutritionalInfo': nutritionalInfo,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'image': image,
    };
  }

  // Create a copy of the menu item with updated fields
  MenuItemModel copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? description,
    List<String>? ingredients,
    String? imageUrl,
    bool? isAvailable,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    double? discountPercentage,
    double? rating,
    int? prepTimeMinutes,
    Map<String, dynamic>? nutritionalInfo,
    double? averageRating,
    int? totalRatings,
    String? image,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      image: image ?? this.image,
    );
  }

  // Calculate the discounted price
  double get discountedPrice {
    if (discountPercentage == null || discountPercentage == 0) {
      return price;
    }
    return price - (price * discountPercentage! / 100);
  }

  // Nutrition getters
  int get calories => nutritionalInfo != null
      ? (nutritionalInfo!['calories'] as num).toInt()
      : 0;
  int get protein => nutritionalInfo != null
      ? (nutritionalInfo!['protein'] as num).toInt()
      : 0;
  int get carbs =>
      nutritionalInfo != null ? (nutritionalInfo!['carbs'] as num).toInt() : 0;
  int get fat =>
      nutritionalInfo != null ? (nutritionalInfo!['fat'] as num).toInt() : 0;

  // Create a list of dummy menu items for testing
  static List<MenuItemModel> dummyMenuItems() {
    return [
      MenuItemModel(
        id: '1',
        name: 'Classic Burger',
        category: 'Main Course',
        price: 12.99,
        description:
            'Juicy beef patty with lettuce, tomato, and special sauce on a brioche bun.',
        ingredients: [
          'Beef Patty',
          'Lettuce',
          'Tomato',
          'Onion',
          'Special Sauce',
          'Brioche Bun'
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1299&q=80',
        isAvailable: true,
        isVegetarian: false,
        isVegan: false,
        isGlutenFree: false,
        rating: 4.5,
        prepTimeMinutes: 15,
        nutritionalInfo: {
          'calories': 650,
          'protein': 35,
          'carbs': 40,
          'fat': 35,
        },
        averageRating: 4.5,
        totalRatings: 127,
        image:
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1299&q=80',
      ),
      MenuItemModel(
        id: '2',
        name: 'Margherita Pizza',
        category: 'Main Course',
        price: 14.99,
        description:
            'Classic pizza with tomato sauce, mozzarella, and fresh basil.',
        ingredients: [
          'Pizza Dough',
          'Tomato Sauce',
          'Mozzarella Cheese',
          'Fresh Basil',
          'Olive Oil'
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
        isAvailable: true,
        isVegetarian: true,
        isVegan: false,
        isGlutenFree: false,
        discountPercentage: 10,
        rating: 4.7,
        prepTimeMinutes: 20,
        nutritionalInfo: {
          'calories': 850,
          'protein': 30,
          'carbs': 100,
          'fat': 40,
        },
        averageRating: 4.7,
        totalRatings: 89,
        image:
            'https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
      ),
      MenuItemModel(
        id: '3',
        name: 'Caesar Salad',
        category: 'Starter',
        price: 8.99,
        description:
            'Fresh romaine lettuce with Caesar dressing, croutons, and parmesan cheese.',
        ingredients: [
          'Romaine Lettuce',
          'Caesar Dressing',
          'Croutons',
          'Parmesan Cheese'
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
        isAvailable: true,
        isVegetarian: true,
        isVegan: false,
        isGlutenFree: false,
        rating: 4.2,
        prepTimeMinutes: 10,
        nutritionalInfo: {
          'calories': 350,
          'protein': 10,
          'carbs': 15,
          'fat': 25,
        },
        averageRating: 4.2,
        totalRatings: 64,
        image:
            'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
      ),
      MenuItemModel(
        id: '4',
        name: 'Chocolate Brownie',
        category: 'Dessert',
        price: 6.99,
        description:
            'Rich chocolate brownie served with vanilla ice cream and chocolate sauce.',
        ingredients: [
          'Chocolate',
          'Flour',
          'Sugar',
          'Eggs',
          'Butter',
          'Vanilla Ice Cream',
          'Chocolate Sauce'
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1287&q=80',
        isAvailable: true,
        isVegetarian: true,
        isVegan: false,
        isGlutenFree: false,
        rating: 4.8,
        prepTimeMinutes: 5,
        nutritionalInfo: {
          'calories': 450,
          'protein': 5,
          'carbs': 60,
          'fat': 25,
        },
        averageRating: 4.8,
        totalRatings: 156,
        image:
            'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1287&q=80',
      ),
      MenuItemModel(
        id: '5',
        name: 'Vegan Buddha Bowl',
        category: 'Main Course',
        price: 13.99,
        description:
            'Nutritious bowl with quinoa, roasted vegetables, avocado, and tahini dressing.',
        ingredients: [
          'Quinoa',
          'Roasted Vegetables',
          'Avocado',
          'Chickpeas',
          'Tahini Dressing'
        ],
        imageUrl:
            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
        isAvailable: true,
        isVegetarian: true,
        isVegan: true,
        isGlutenFree: true,
        discountPercentage: 5,
        rating: 4.6,
        prepTimeMinutes: 15,
        nutritionalInfo: {
          'calories': 550,
          'protein': 15,
          'carbs': 70,
          'fat': 25,
        },
        averageRating: 4.6,
        totalRatings: 73,
        image:
            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
      ),
    ];
  }
}
