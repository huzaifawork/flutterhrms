class Room {
  final String id;
  final String roomNumber;
  final String roomType;
  final String description;
  final double price;
  final String status;
  final String? image;
  final String? recommendationReason;
  final double? score;
  final int? rank;
  final String? explanation;

  Room({
    required this.id,
    required this.roomNumber,
    required this.roomType,
    required this.description,
    required this.price,
    required this.status,
    this.image,
    this.recommendationReason,
    this.score,
    this.rank,
    this.explanation,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    // Handle both direct room data and recommendation wrapper
    final roomData = json['room'] ?? json;
    
    return Room(
      id: roomData['_id'] ?? roomData['id'] ?? '',
      roomNumber: roomData['roomNumber'] ?? '',
      roomType: roomData['roomType'] ?? '',
      description: roomData['description'] ?? '',
      price: (roomData['price'] ?? 0).toDouble(),
      status: roomData['status'] ?? 'Available',
      image: roomData['image'] != null 
          ? (roomData['image'].startsWith('http') 
              ? roomData['image'] 
              : 'http://localhost:8080${roomData['image']}')
          : null,
      recommendationReason: json['reason'] ?? json['recommendationReason'],
      score: json['score']?.toDouble(),
      rank: json['rank'],
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'roomType': roomType,
      'description': description,
      'price': price,
      'status': status,
      'image': image,
      'recommendationReason': recommendationReason,
      'score': score,
      'rank': rank,
      'explanation': explanation,
    };
  }

  Room copyWith({
    String? id,
    String? roomNumber,
    String? roomType,
    String? description,
    double? price,
    String? status,
    String? image,
    String? recommendationReason,
    double? score,
    int? rank,
    String? explanation,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      description: description ?? this.description,
      price: price ?? this.price,
      status: status ?? this.status,
      image: image ?? this.image,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      explanation: explanation ?? this.explanation,
    );
  }

  @override
  String toString() {
    return 'Room(id: $id, roomNumber: $roomNumber, roomType: $roomType, price: $price, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Room && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
