import 'table_model.dart';

class ReservationModel {
  final String id;
  final String userId;
  final String tableId;
  final DateTime reservationDate;
  final String timeSlot;
  final String? endTime;
  final int partySize;
  final String status;
  final String? specialRequests;
  final String? occasion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TableModel? table;

  const ReservationModel({
    required this.id,
    required this.userId,
    required this.tableId,
    required this.reservationDate,
    required this.timeSlot,
    this.endTime,
    required this.partySize,
    required this.status,
    this.specialRequests,
    this.occasion,
    required this.createdAt,
    required this.updatedAt,
    this.table,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tableId: json['tableId'] as String,
      reservationDate: DateTime.parse(json['reservationDate'] as String),
      timeSlot: json['timeSlot'] ?? json['time'] as String,
      endTime: json['endTime'] as String?,
      partySize: json['partySize'] ?? json['guests'] as int,
      status: json['status'] as String,
      specialRequests: json['specialRequests'] as String?,
      occasion: json['occasion'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      table: json['table'] != null ? TableModel.fromJson(json['table']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tableId': tableId,
      'reservationDate': reservationDate.toIso8601String(),
      'timeSlot': timeSlot,
      'endTime': endTime,
      'partySize': partySize,
      'status': status,
      'specialRequests': specialRequests,
      'occasion': occasion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'table': table?.toJson(),
    };
  }

  ReservationModel copyWith({
    String? id,
    String? userId,
    String? tableId,
    DateTime? reservationDate,
    String? timeSlot,
    String? endTime,
    int? partySize,
    String? status,
    String? specialRequests,
    String? occasion,
    DateTime? createdAt,
    DateTime? updatedAt,
    TableModel? table,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tableId: tableId ?? this.tableId,
      reservationDate: reservationDate ?? this.reservationDate,
      timeSlot: timeSlot ?? this.timeSlot,
      endTime: endTime ?? this.endTime,
      partySize: partySize ?? this.partySize,
      status: status ?? this.status,
      specialRequests: specialRequests ?? this.specialRequests,
      occasion: occasion ?? this.occasion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      table: table ?? this.table,
    );
  }

  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'seated':
        return 'Seated';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }

  bool get isActive {
    return ['pending', 'confirmed', 'seated'].contains(status.toLowerCase());
  }

  bool get canBeCancelled {
    return ['pending', 'confirmed'].contains(status.toLowerCase());
  }

  static List<ReservationModel> dummyReservations() {
    final now = DateTime.now();
    return [
      ReservationModel(
        id: '1',
        userId: 'user1',
        tableId: 'table1',
        reservationDate: now.add(const Duration(days: 1)),
        timeSlot: '19:00',
        endTime: '21:00',
        partySize: 2,
        status: 'confirmed',
        specialRequests: 'Window seat preferred',
        occasion: 'Anniversary',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        table: TableModel(
          id: 'table1',
          tableNumber: '5',
          capacity: 4,
          location: 'Window',
          status: 'available',
          isReserved: true,
          reservationTime: null,
          reservedBy: null,
          imageUrl:
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
        ),
      ),
      ReservationModel(
        id: '2',
        userId: 'user1',
        tableId: 'table2',
        reservationDate: now.subtract(const Duration(days: 3)),
        timeSlot: '20:30',
        endTime: '22:30',
        partySize: 4,
        status: 'completed',
        specialRequests: null,
        occasion: 'Birthday',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 3)),
        table: TableModel(
          id: 'table2',
          tableNumber: '12',
          capacity: 6,
          location: 'Center',
          status: 'available',
          isReserved: false,
          reservationTime: null,
          reservedBy: null,
          imageUrl:
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
        ),
      ),
      ReservationModel(
        id: '3',
        userId: 'user1',
        tableId: 'table3',
        reservationDate: now.add(const Duration(days: 7)),
        timeSlot: '18:00',
        endTime: '20:00',
        partySize: 6,
        status: 'pending',
        specialRequests: 'High chair needed',
        occasion: 'Family Gathering',
        createdAt: now.subtract(const Duration(minutes: 30)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
        table: TableModel(
          id: 'table3',
          tableNumber: '8',
          capacity: 8,
          location: 'Private Room',
          status: 'available',
          isReserved: true,
          reservationTime: null,
          reservedBy: null,
          imageUrl:
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
        ),
      ),
    ];
  }
}
