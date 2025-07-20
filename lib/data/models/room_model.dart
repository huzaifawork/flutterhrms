class RoomModel {
  final String id;
  final String roomNumber;
  final String roomType;
  final double pricePerNight;
  final int capacity;
  final List<String> amenities;
  final List<String> imageUrls;
  final String status;
  final String? description;
  final int floor;
  final bool isAvailable;
  final String size;

  const RoomModel({
    required this.id,
    required this.roomNumber,
    required this.roomType,
    required this.pricePerNight,
    required this.capacity,
    required this.amenities,
    required this.imageUrls,
    required this.status,
    this.description,
    required this.floor,
    this.isAvailable = true,
    this.size = 'Standard',
  });

  // Create a room from JSON data
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      roomNumber: json['roomNumber'] as String,
      roomType: json['roomType'] as String,
      pricePerNight: (json['pricePerNight'] as num).toDouble(),
      capacity: json['capacity'] as int,
      amenities: List<String>.from(json['amenities'] as List),
      imageUrls: List<String>.from(json['imageUrls'] as List),
      status: json['status'] as String,
      description: json['description'] as String?,
      floor: json['floor'] as int,
      isAvailable: json['isAvailable'] as bool? ?? true,
      size: json['size'] as String? ?? 'Standard',
    );
  }

  // Convert room to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'roomType': roomType,
      'pricePerNight': pricePerNight,
      'capacity': capacity,
      'amenities': amenities,
      'imageUrls': imageUrls,
      'status': status,
      'description': description,
      'floor': floor,
      'isAvailable': isAvailable,
      'size': size,
    };
  }

  // Create a copy of the room with updated fields
  RoomModel copyWith({
    String? id,
    String? roomNumber,
    String? roomType,
    double? pricePerNight,
    int? capacity,
    List<String>? amenities,
    List<String>? imageUrls,
    String? status,
    String? description,
    int? floor,
    bool? isAvailable,
    String? size,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      capacity: capacity ?? this.capacity,
      amenities: amenities ?? this.amenities,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      description: description ?? this.description,
      floor: floor ?? this.floor,
      isAvailable: isAvailable ?? this.isAvailable,
      size: size ?? this.size,
    );
  }

  // Create a list of dummy rooms for testing
  static List<RoomModel> dummyRooms() {
    return [
      const RoomModel(
        id: '1',
        roomNumber: '101',
        roomType: 'standard',
        pricePerNight: 99.99,
        capacity: 2,
        amenities: ['Wi-Fi', 'TV', 'Air Conditioning', 'Mini Bar'],
        imageUrls: [
          'https://images.unsplash.com/photo-1566665797739-1674de7a421a?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1074&q=80',
          'https://images.unsplash.com/photo-1566665797739-1674de7a421a?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1074&q=80',
        ],
        status: 'available',
        description: 'Comfortable standard room with all basic amenities.',
        floor: 1,
        isAvailable: true,
        size: '25 m²',
      ),
      const RoomModel(
        id: '2',
        roomNumber: '102',
        roomType: 'standard',
        pricePerNight: 99.99,
        capacity: 2,
        amenities: ['Wi-Fi', 'TV', 'Air Conditioning', 'Mini Bar'],
        imageUrls: [
          'https://images.unsplash.com/photo-1566665797739-1674de7a421a?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1074&q=80',
        ],
        status: 'occupied',
        description: 'Comfortable standard room with all basic amenities.',
        floor: 1,
        isAvailable: false,
        size: '25 m²',
      ),
      const RoomModel(
        id: '3',
        roomNumber: '201',
        roomType: 'deluxe',
        pricePerNight: 149.99,
        capacity: 2,
        amenities: ['Wi-Fi', 'TV', 'Air Conditioning', 'Mini Bar', 'Balcony', 'Coffee Machine'],
        imageUrls: [
          'https://images.unsplash.com/photo-1590490360182-c33d57733427?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1074&q=80',
        ],
        status: 'available',
        description: 'Spacious deluxe room with additional amenities and a balcony.',
        floor: 2,
        isAvailable: true,
        size: '35 m²',
      ),
      const RoomModel(
        id: '4',
        roomNumber: '301',
        roomType: 'suite',
        pricePerNight: 249.99,
        capacity: 4,
        amenities: ['Wi-Fi', 'TV', 'Air Conditioning', 'Mini Bar', 'Balcony', 'Coffee Machine', 'Jacuzzi', 'Kitchenette'],
        imageUrls: [
          'https://images.unsplash.com/photo-1591088398332-8a7791972843?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1074&q=80',
        ],
        status: 'available',
        description: 'Luxurious suite with separate living area and premium amenities.',
        floor: 3,
        isAvailable: true,
        size: '50 m²',
      ),
      const RoomModel(
        id: '5',
        roomNumber: '401',
        roomType: 'executive',
        pricePerNight: 349.99,
        capacity: 2,
        amenities: ['Wi-Fi', 'TV', 'Air Conditioning', 'Mini Bar', 'Balcony', 'Coffee Machine', 'Jacuzzi', 'Kitchenette', 'Private Lounge Access'],
        imageUrls: [
          'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
        ],
        status: 'maintenance',
        description: 'Premium executive room with exclusive amenities and services.',
        floor: 4,
        isAvailable: false,
        size: '60 m²',
      ),
    ];
  }
} 