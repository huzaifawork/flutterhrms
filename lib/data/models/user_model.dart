class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profileImageUrl;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final Map<String, dynamic>? preferences;

  // Add a getter for fullName that returns name
  String get fullName => name;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profileImageUrl,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.preferences,
  });

  // Create a user from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  // Convert user to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'preferences': preferences,
    };
  }

  // Create a copy of the user with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
    );
  }

  // Create a dummy user for testing
  static UserModel dummyUser() {
    return UserModel(
      id: '1',
      name: 'John Doe',
      email: 'john.doe@example.com',
      phoneNumber: '+1234567890',
      profileImageUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
      role: 'customer',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
      isActive: true,
      preferences: {
        'theme': 'light',
        'notifications': true,
        'language': 'en',
      },
    );
  }

  // Create a list of dummy users for testing
  static List<UserModel> dummyUsers() {
    return [
      UserModel(
        id: '1',
        name: 'John Doe',
        email: 'john.doe@example.com',
        phoneNumber: '+1234567890',
        profileImageUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
        role: 'customer',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLoginAt: DateTime.now(),
        isActive: true,
        preferences: {
          'theme': 'light',
          'notifications': true,
          'language': 'en',
        },
      ),
      UserModel(
        id: '2',
        name: 'Jane Smith',
        email: 'jane.smith@example.com',
        phoneNumber: '+1987654321',
        profileImageUrl: 'https://randomuser.me/api/portraits/women/1.jpg',
        role: 'customer',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        lastLoginAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
        preferences: {
          'theme': 'dark',
          'notifications': true,
          'language': 'en',
        },
      ),
      UserModel(
        id: '3',
        name: 'Robert Johnson',
        email: 'robert.johnson@example.com',
        phoneNumber: '+1122334455',
        profileImageUrl: 'https://randomuser.me/api/portraits/men/2.jpg',
        role: 'admin',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
        isActive: true,
        preferences: {
          'theme': 'light',
          'notifications': false,
          'language': 'en',
        },
      ),
      UserModel(
        id: '4',
        name: 'Emily Davis',
        email: 'emily.davis@example.com',
        phoneNumber: '+1555666777',
        profileImageUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
        role: 'staff',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 5)),
        isActive: true,
        preferences: {
          'theme': 'dark',
          'notifications': true,
          'language': 'fr',
        },
      ),
      UserModel(
        id: '5',
        name: 'Michael Wilson',
        email: 'michael.wilson@example.com',
        phoneNumber: '+1777888999',
        profileImageUrl: 'https://randomuser.me/api/portraits/men/3.jpg',
        role: 'manager',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        lastLoginAt: DateTime.now().subtract(const Duration(days: 3)),
        isActive: true,
        preferences: {
          'theme': 'light',
          'notifications': true,
          'language': 'en',
        },
      ),
    ];
  }
} 