class FoodRecommendation {
  final String id;
  final String menuItemId;
  final String name;
  final String description;
  final double price;
  final String? image;
  final String category;
  final String? cuisine;
  final bool availability;
  final double? averageRating;
  final String? spiceLevel;
  final List<String>? dietaryTags;
  final double score;
  final String reason;
  final String confidence;
  final int? preparationTime;

  FoodRecommendation({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    required this.category,
    this.cuisine,
    required this.availability,
    this.averageRating,
    this.spiceLevel,
    this.dietaryTags,
    required this.score,
    required this.reason,
    required this.confidence,
    this.preparationTime,
  });

  factory FoodRecommendation.fromJson(Map<String, dynamic> json) {
    return FoodRecommendation(
      id: json['_id'] ?? json['id'] ?? '',
      menuItemId: json['menuItemId'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'],
      category: json['category'] ?? '',
      cuisine: json['cuisine'],
      availability: json['availability'] ?? true,
      averageRating: json['averageRating']?.toDouble(),
      spiceLevel: json['spiceLevel'],
      dietaryTags: json['dietaryTags']?.cast<String>(),
      score: (json['score'] ?? 0).toDouble(),
      reason: json['reason'] ?? 'unknown',
      confidence: json['confidence'] ?? 'medium',
      preparationTime: json['preparationTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category': category,
      'cuisine': cuisine,
      'availability': availability,
      'averageRating': averageRating,
      'spiceLevel': spiceLevel,
      'dietaryTags': dietaryTags,
      'score': score,
      'reason': reason,
      'confidence': confidence,
      'preparationTime': preparationTime,
    };
  }
}

class TableRecommendation {
  final String tableId;
  final TableInfo table;
  final double score;
  final String reason;
  final String confidence;
  final int rank;
  final String explanation;
  final Map<String, dynamic>? contextFactors;

  TableRecommendation({
    required this.tableId,
    required this.table,
    required this.score,
    required this.reason,
    required this.confidence,
    required this.rank,
    required this.explanation,
    this.contextFactors,
  });

  factory TableRecommendation.fromJson(Map<String, dynamic> json) {
    return TableRecommendation(
      tableId: json['tableId'] ?? '',
      table: TableInfo.fromJson(json['table'] ?? {}),
      score: (json['score'] ?? 0).toDouble(),
      reason: json['reason'] ?? 'unknown',
      confidence: json['confidence'] ?? 'medium',
      rank: json['rank'] ?? 0,
      explanation: json['explanation'] ?? '',
      contextFactors: json['contextFactors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tableId': tableId,
      'table': table.toJson(),
      'score': score,
      'reason': reason,
      'confidence': confidence,
      'rank': rank,
      'explanation': explanation,
      'contextFactors': contextFactors,
    };
  }
}

class TableInfo {
  final String id;
  final String tableName;
  final int capacity;
  final String location;
  final String ambiance;
  final bool hasWindowView;
  final bool isPrivate;
  final String priceTier;
  final List<String>? features;
  final double? avgRating;
  final String? image;
  final String? description;
  final String? tableType;
  final String status;

  TableInfo({
    required this.id,
    required this.tableName,
    required this.capacity,
    required this.location,
    required this.ambiance,
    required this.hasWindowView,
    required this.isPrivate,
    required this.priceTier,
    this.features,
    this.avgRating,
    this.image,
    this.description,
    this.tableType,
    required this.status,
  });

  factory TableInfo.fromJson(Map<String, dynamic> json) {
    return TableInfo(
      id: json['_id'] ?? json['id'] ?? '',
      tableName: json['tableName'] ?? '',
      capacity: json['capacity'] ?? 0,
      location: json['location'] ?? '',
      ambiance: json['ambiance'] ?? '',
      hasWindowView: json['hasWindowView'] ?? false,
      isPrivate: json['isPrivate'] ?? false,
      priceTier: json['priceTier'] ?? '',
      features: json['features']?.cast<String>(),
      avgRating: json['avgRating']?.toDouble(),
      image: json['image'],
      description: json['description'],
      tableType: json['tableType'],
      status: json['status'] ?? 'Available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableName': tableName,
      'capacity': capacity,
      'location': location,
      'ambiance': ambiance,
      'hasWindowView': hasWindowView,
      'isPrivate': isPrivate,
      'priceTier': priceTier,
      'features': features,
      'avgRating': avgRating,
      'image': image,
      'description': description,
      'tableType': tableType,
      'status': status,
    };
  }
}

class UserFoodInteraction {
  final String id;
  final String userId;
  final String menuItemId;
  final String interactionType;
  final int? rating;
  final int orderQuantity;
  final DateTime timestamp;

  UserFoodInteraction({
    required this.id,
    required this.userId,
    required this.menuItemId,
    required this.interactionType,
    this.rating,
    required this.orderQuantity,
    required this.timestamp,
  });

  factory UserFoodInteraction.fromJson(Map<String, dynamic> json) {
    return UserFoodInteraction(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      menuItemId: json['menuItemId'] ?? '',
      interactionType: json['interactionType'] ?? '',
      rating: json['rating'],
      orderQuantity: json['orderQuantity'] ?? 1,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'menuItemId': menuItemId,
      'interactionType': interactionType,
      'rating': rating,
      'orderQuantity': orderQuantity,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class UserPreferences {
  final double avgRating;
  final int totalInteractions;
  final Map<String, int> preferredCuisines;
  final Map<String, int> preferredCategories;
  final Map<String, int> preferredSpiceLevels;
  final Map<String, int> preferredDietaryTags;
  final Map<String, int> ratingDistribution;

  UserPreferences({
    required this.avgRating,
    required this.totalInteractions,
    required this.preferredCuisines,
    required this.preferredCategories,
    required this.preferredSpiceLevels,
    required this.preferredDietaryTags,
    required this.ratingDistribution,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      totalInteractions: json['totalInteractions'] ?? 0,
      preferredCuisines: Map<String, int>.from(json['preferredCuisines'] ?? {}),
      preferredCategories: Map<String, int>.from(json['preferredCategories'] ?? {}),
      preferredSpiceLevels: Map<String, int>.from(json['preferredSpiceLevels'] ?? {}),
      preferredDietaryTags: Map<String, int>.from(json['preferredDietaryTags'] ?? {}),
      ratingDistribution: Map<String, int>.from(json['ratingDistribution'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avgRating': avgRating,
      'totalInteractions': totalInteractions,
      'preferredCuisines': preferredCuisines,
      'preferredCategories': preferredCategories,
      'preferredSpiceLevels': preferredSpiceLevels,
      'preferredDietaryTags': preferredDietaryTags,
      'ratingDistribution': ratingDistribution,
    };
  }
}
