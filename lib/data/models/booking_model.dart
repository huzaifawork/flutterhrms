class BookingModel {
  final String id;
  final String userId;
  final String roomId;
  final String roomNumber;
  final String roomType;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numberOfGuests;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String? paymentId;
  final bool isPaid;
  final String? specialRequests;
  final DateTime bookingDate;
  final String? cancellationReason;
  final DateTime? cancellationDate;
  final bool isRefunded;
  final double? refundAmount;
  final String guestName;
  final int adults;
  final int children;

  BookingModel({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.roomNumber,
    required this.roomType,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfGuests,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.paymentId,
    required this.isPaid,
    this.specialRequests,
    required this.bookingDate,
    this.cancellationReason,
    this.cancellationDate,
    this.isRefunded = false,
    this.refundAmount,
    required this.guestName,
    required this.adults,
    this.children = 0,
  });

  // Calculate number of nights
  int get numberOfNights {
    return checkOutDate.difference(checkInDate).inDays;
  }

  // Added getter for totalPrice that returns totalAmount
  double get totalPrice => totalAmount;

  // Create a booking from JSON data (compatible with backend API)
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id'] ?? json['id'] as String,
      userId: json['userId'] as String,
      roomId: json['roomId'] as String,
      roomNumber: json['roomNumber'] ?? json['room']?['roomNumber'] ?? 'N/A',
      roomType: json['roomType'] ?? json['room']?['type'] ?? 'standard',
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: DateTime.parse(json['checkOutDate'] as String),
      numberOfGuests: json['guests'] ?? json['numberOfGuests'] as int,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] ?? 'credit_card',
      paymentId: json['paymentId'] as String?,
      isPaid: json['isPaid'] ?? (json['paymentStatus'] == 'paid'),
      specialRequests: json['specialRequests'] as String?,
      bookingDate:
          DateTime.parse(json['createdAt'] ?? json['bookingDate'] as String),
      cancellationReason: json['cancellationReason'] as String?,
      cancellationDate: json['cancellationDate'] != null
          ? DateTime.parse(json['cancellationDate'] as String)
          : null,
      isRefunded: json['isRefunded'] as bool? ?? false,
      refundAmount: json['refundAmount'] != null
          ? (json['refundAmount'] as num).toDouble()
          : null,
      guestName: json['guestName'] ?? json['user']?['name'] ?? 'Guest',
      adults: json['adults'] ?? (json['guests'] ?? 1),
      children: json['children'] as int? ?? 0,
    );
  }

  // Convert booking to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'roomType': roomType,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'numberOfGuests': numberOfGuests,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'isPaid': isPaid,
      'specialRequests': specialRequests,
      'bookingDate': bookingDate.toIso8601String(),
      'cancellationReason': cancellationReason,
      'cancellationDate': cancellationDate?.toIso8601String(),
      'isRefunded': isRefunded,
      'refundAmount': refundAmount,
      'guestName': guestName,
      'adults': adults,
      'children': children,
    };
  }

  // Create a copy of the booking with updated fields
  BookingModel copyWith({
    String? id,
    String? userId,
    String? roomId,
    String? roomNumber,
    String? roomType,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? numberOfGuests,
    double? totalAmount,
    String? status,
    String? paymentMethod,
    String? paymentId,
    bool? isPaid,
    String? specialRequests,
    DateTime? bookingDate,
    String? cancellationReason,
    DateTime? cancellationDate,
    bool? isRefunded,
    double? refundAmount,
    String? guestName,
    int? adults,
    int? children,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      isPaid: isPaid ?? this.isPaid,
      specialRequests: specialRequests ?? this.specialRequests,
      bookingDate: bookingDate ?? this.bookingDate,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancellationDate: cancellationDate ?? this.cancellationDate,
      isRefunded: isRefunded ?? this.isRefunded,
      refundAmount: refundAmount ?? this.refundAmount,
      guestName: guestName ?? this.guestName,
      adults: adults ?? this.adults,
      children: children ?? this.children,
    );
  }

  // Create a list of dummy bookings for testing
  static List<BookingModel> dummyBookings() {
    return [
      BookingModel(
        id: '1',
        userId: '1',
        roomId: '1',
        roomNumber: '101',
        roomType: 'standard',
        checkInDate: DateTime.now().add(const Duration(days: 7)),
        checkOutDate: DateTime.now().add(const Duration(days: 10)),
        numberOfGuests: 2,
        totalAmount: 299.97,
        status: 'confirmed',
        paymentMethod: 'credit_card',
        paymentId: 'pay_123456',
        isPaid: true,
        bookingDate: DateTime.now().subtract(const Duration(days: 3)),
        guestName: 'John Doe',
        adults: 2,
        children: 0,
      ),
      BookingModel(
        id: '2',
        userId: '2',
        roomId: '3',
        roomNumber: '201',
        roomType: 'deluxe',
        checkInDate: DateTime.now().add(const Duration(days: 1)),
        checkOutDate: DateTime.now().add(const Duration(days: 5)),
        numberOfGuests: 2,
        totalAmount: 599.96,
        status: 'confirmed',
        paymentMethod: 'credit_card',
        paymentId: 'pay_234567',
        isPaid: true,
        specialRequests: 'Early check-in if possible, room with a view',
        bookingDate: DateTime.now().subtract(const Duration(days: 10)),
        guestName: 'Jane Smith',
        adults: 2,
        children: 0,
      ),
      BookingModel(
        id: '3',
        userId: '3',
        roomId: '4',
        roomNumber: '301',
        roomType: 'suite',
        checkInDate: DateTime.now().subtract(const Duration(days: 5)),
        checkOutDate: DateTime.now().subtract(const Duration(days: 2)),
        numberOfGuests: 4,
        totalAmount: 749.97,
        status: 'completed',
        paymentMethod: 'credit_card',
        paymentId: 'pay_345678',
        isPaid: true,
        bookingDate: DateTime.now().subtract(const Duration(days: 15)),
        guestName: 'Robert Johnson',
        adults: 2,
        children: 2,
      ),
      BookingModel(
        id: '4',
        userId: '4',
        roomId: '5',
        roomNumber: '401',
        roomType: 'executive',
        checkInDate: DateTime.now().add(const Duration(days: 20)),
        checkOutDate: DateTime.now().add(const Duration(days: 25)),
        numberOfGuests: 2,
        totalAmount: 1749.95,
        status: 'pending',
        paymentMethod: 'credit_card',
        isPaid: false,
        bookingDate: DateTime.now().subtract(const Duration(hours: 5)),
        guestName: 'Michael Brown',
        adults: 2,
        children: 0,
      ),
      BookingModel(
        id: '5',
        userId: '5',
        roomId: '2',
        roomNumber: '102',
        roomType: 'standard',
        checkInDate: DateTime.now().add(const Duration(days: 3)),
        checkOutDate: DateTime.now().add(const Duration(days: 5)),
        numberOfGuests: 2,
        totalAmount: 199.98,
        status: 'cancelled',
        paymentMethod: 'credit_card',
        paymentId: 'pay_456789',
        isPaid: true,
        bookingDate: DateTime.now().subtract(const Duration(days: 7)),
        cancellationReason: 'Change of plans',
        cancellationDate: DateTime.now().subtract(const Duration(days: 1)),
        isRefunded: true,
        refundAmount: 179.98,
        guestName: 'Sarah Wilson',
        adults: 1,
        children: 1,
      ),
    ];
  }
}
