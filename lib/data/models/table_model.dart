class TableModel {
  final String id;
  final String tableNumber;
  final int capacity;
  final String location;
  final String status;
  final bool isReserved;
  final String? reservedBy;
  final DateTime? reservationTime;
  final String? imageUrl;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.location,
    required this.status,
    this.isReserved = false,
    this.reservedBy,
    this.reservationTime,
    this.imageUrl,
  });

  // Create a table from JSON data
  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] as String,
      tableNumber: json['tableNumber'] as String,
      capacity: json['capacity'] as int,
      location: json['location'] as String,
      status: json['status'] as String,
      isReserved: json['isReserved'] as bool? ?? false,
      reservedBy: json['reservedBy'] as String?,
      reservationTime: json['reservationTime'] != null
          ? DateTime.parse(json['reservationTime'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  // Convert table to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'capacity': capacity,
      'location': location,
      'status': status,
      'isReserved': isReserved,
      'reservedBy': reservedBy,
      'reservationTime': reservationTime?.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  // Create a copy of the table with updated fields
  TableModel copyWith({
    String? id,
    String? tableNumber,
    int? capacity,
    String? location,
    String? status,
    bool? isReserved,
    String? reservedBy,
    DateTime? reservationTime,
    String? imageUrl,
  }) {
    return TableModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      location: location ?? this.location,
      status: status ?? this.status,
      isReserved: isReserved ?? this.isReserved,
      reservedBy: reservedBy ?? this.reservedBy,
      reservationTime: reservationTime ?? this.reservationTime,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Create a list of dummy tables for testing
  static List<TableModel> dummyTables() {
    return [
      TableModel(
        id: '1',
        tableNumber: 'T1',
        capacity: 2,
        location: 'Window',
        status: 'available',
        isReserved: false,
        imageUrl: 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
      ),
      TableModel(
        id: '2',
        tableNumber: 'T2',
        capacity: 4,
        location: 'Window',
        status: 'reserved',
        isReserved: true,
        reservedBy: 'John Doe',
        reservationTime: DateTime.now().add(const Duration(hours: 2)),
        imageUrl: 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
      ),
      TableModel(
        id: '3',
        tableNumber: 'T3',
        capacity: 6,
        location: 'Center',
        status: 'occupied',
        isReserved: false,
        imageUrl: 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
      ),
      TableModel(
        id: '4',
        tableNumber: 'T4',
        capacity: 8,
        location: 'Private Room',
        status: 'available',
        isReserved: false,
        imageUrl: 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
      ),
      TableModel(
        id: '5',
        tableNumber: 'T5',
        capacity: 2,
        location: 'Balcony',
        status: 'maintenance',
        isReserved: false,
        imageUrl: 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
      ),
    ];
  }
} 