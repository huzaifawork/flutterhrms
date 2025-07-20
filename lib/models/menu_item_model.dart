class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final List<String> ingredients;
  final Map<String, double> nutritionalInfo;
  final List<String> allergens;
  final List<String> dietaryTags;
  final List<CustomizationOption> customizationOptions;
  final int preparationTimeMinutes;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.ingredients = const [],
    this.nutritionalInfo = const {},
    this.allergens = const [],
    this.dietaryTags = const [],
    this.customizationOptions = const [],
    this.preparationTimeMinutes = 15,
  });

  // Dietary flag getters for the UI
  bool get isVegetarian => dietaryTags.any((tag) => tag.toLowerCase() == 'vegetarian');
  bool get isVegan => dietaryTags.any((tag) => tag.toLowerCase() == 'vegan');
  bool get isGlutenFree => dietaryTags.any((tag) => tag.toLowerCase() == 'gluten-free');

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    List<CustomizationOption> customizationOptions = [];
    if (json['customizationOptions'] != null) {
      customizationOptions = (json['customizationOptions'] as List)
          .map((option) => CustomizationOption.fromJson(option))
          .toList();
    }

    return MenuItemModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price']?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? 'Other',
      isAvailable: json['isAvailable'] ?? true,
      rating: json['rating']?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'])
          : [],
      nutritionalInfo: json['nutritionalInfo'] != null
          ? Map<String, double>.from(json['nutritionalInfo'])
          : {},
      allergens:
          json['allergens'] != null ? List<String>.from(json['allergens']) : [],
      dietaryTags: json['dietaryTags'] != null
          ? List<String>.from(json['dietaryTags'])
          : [],
      customizationOptions: customizationOptions,
      preparationTimeMinutes: json['preparationTimeMinutes'] ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewCount': reviewCount,
      'ingredients': ingredients,
      'nutritionalInfo': nutritionalInfo,
      'allergens': allergens,
      'dietaryTags': dietaryTags,
      'customizationOptions':
          customizationOptions.map((option) => option.toJson()).toList(),
      'preparationTimeMinutes': preparationTimeMinutes,
    };
  }

  MenuItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    bool? isAvailable,
    double? rating,
    int? reviewCount,
    List<String>? ingredients,
    Map<String, double>? nutritionalInfo,
    List<String>? allergens,
    List<String>? dietaryTags,
    List<CustomizationOption>? customizationOptions,
    int? preparationTimeMinutes,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      ingredients: ingredients ?? this.ingredients,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      allergens: allergens ?? this.allergens,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      customizationOptions: customizationOptions ?? this.customizationOptions,
      preparationTimeMinutes: preparationTimeMinutes ?? this.preparationTimeMinutes,
    );
  }
}

class CustomizationOption {
  final String name;
  final List<CustomizationChoice> choices;
  final bool required;
  final int maxChoices;

  CustomizationOption({
    required this.name,
    required this.choices,
    this.required = false,
    this.maxChoices = 1,
  });

  factory CustomizationOption.fromJson(Map<String, dynamic> json) {
    List<CustomizationChoice> choices = [];
    if (json['choices'] != null) {
      choices = (json['choices'] as List)
          .map((choice) => CustomizationChoice.fromJson(choice))
          .toList();
    }

    return CustomizationOption(
      name: json['name'],
      choices: choices,
      required: json['required'] ?? false,
      maxChoices: json['maxChoices'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'choices': choices.map((choice) => choice.toJson()).toList(),
      'required': required,
      'maxChoices': maxChoices,
    };
  }
}

class CustomizationChoice {
  final String name;
  final double additionalPrice;

  CustomizationChoice({
    required this.name,
    this.additionalPrice = 0.0,
  });

  factory CustomizationChoice.fromJson(Map<String, dynamic> json) {
    return CustomizationChoice(
      name: json['name'],
      additionalPrice: json['additionalPrice']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'additionalPrice': additionalPrice,
    };
  }
} 