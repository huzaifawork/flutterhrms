class OrderItemModel {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? specialInstructions;

  OrderItemModel({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.specialInstructions,
  });

  // Calculate total price for this item
  double get totalPrice => price * quantity;

  // Create an order item from JSON data
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      menuItemId: json['menuItemId'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      specialInstructions: json['specialInstructions'] as String?,
    );
  }

  // Convert order item to JSON
  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'specialInstructions': specialInstructions,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String? tableId;
  final List<OrderItemModel> items;
  final String status;
  final DateTime orderTime;
  final DateTime? deliveryTime;
  final String orderType; // dine-in, takeaway, delivery
  final double subtotal;
  final double tax;
  final double tip;
  final double deliveryFee;
  final double total;
  final String paymentMethod;
  final String? paymentId;
  final bool isPaid;
  final String? deliveryAddress;
  final String? notes;

  OrderModel({
    required this.id,
    required this.userId,
    this.tableId,
    required this.items,
    required this.status,
    required this.orderTime,
    this.deliveryTime,
    required this.orderType,
    required this.subtotal,
    required this.tax,
    required this.tip,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    this.paymentId,
    required this.isPaid,
    this.deliveryAddress,
    this.notes,
  });

  // Create an order from JSON data
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tableId: json['tableId'] as String?,
      items: (json['items'] as List)
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String,
      orderTime: DateTime.parse(json['orderTime'] as String).toLocal(),
      deliveryTime: json['deliveryTime'] != null
          ? DateTime.parse(json['deliveryTime'] as String).toLocal()
          : null,
      orderType: json['orderType'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      tip: (json['tip'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      paymentId: json['paymentId'] as String?,
      isPaid: json['isPaid'] as bool,
      deliveryAddress: json['deliveryAddress'] as String?,
      notes: json['notes'] as String?,
    );
  }

  // Convert order to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tableId': tableId,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status,
      'orderTime': orderTime.toIso8601String(),
      'deliveryTime': deliveryTime?.toIso8601String(),
      'orderType': orderType,
      'subtotal': subtotal,
      'tax': tax,
      'tip': tip,
      'deliveryFee': deliveryFee,
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'isPaid': isPaid,
      'deliveryAddress': deliveryAddress,
      'notes': notes,
    };
  }

  // Create a copy of the order with updated fields
  OrderModel copyWith({
    String? id,
    String? userId,
    String? tableId,
    List<OrderItemModel>? items,
    String? status,
    DateTime? orderTime,
    DateTime? deliveryTime,
    String? orderType,
    double? subtotal,
    double? tax,
    double? tip,
    double? deliveryFee,
    double? total,
    String? paymentMethod,
    String? paymentId,
    bool? isPaid,
    String? deliveryAddress,
    String? notes,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tableId: tableId ?? this.tableId,
      items: items ?? this.items,
      status: status ?? this.status,
      orderTime: orderTime ?? this.orderTime,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      orderType: orderType ?? this.orderType,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      tip: tip ?? this.tip,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      isPaid: isPaid ?? this.isPaid,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
    );
  }

  // Create a list of dummy orders for testing
  static List<OrderModel> dummyOrders() {
    return [
      OrderModel(
        id: '1',
        userId: '1',
        tableId: '2',
        items: [
          OrderItemModel(
            menuItemId: '1',
            name: 'Classic Burger',
            price: 12.99,
            quantity: 2,
            specialInstructions: 'No onions, extra sauce',
          ),
          OrderItemModel(
            menuItemId: '3',
            name: 'Caesar Salad',
            price: 8.99,
            quantity: 1,
          ),
        ],
        status: 'preparing',
        orderTime: DateTime.now().subtract(const Duration(minutes: 15)),
        orderType: 'dine-in',
        subtotal: 34.97,
        tax: 3.50,
        tip: 5.00,
        deliveryFee: 0.00,
        total: 43.47,
        paymentMethod: 'credit_card',
        paymentId: 'pay_123456',
        isPaid: true,
      ),
      OrderModel(
        id: '2',
        userId: '2',
        items: [
          OrderItemModel(
            menuItemId: '2',
            name: 'Margherita Pizza',
            price: 14.99,
            quantity: 1,
          ),
          OrderItemModel(
            menuItemId: '4',
            name: 'Chocolate Brownie',
            price: 6.99,
            quantity: 2,
          ),
        ],
        status: 'delivered',
        orderTime: DateTime.now().subtract(const Duration(hours: 1)),
        deliveryTime: DateTime.now().subtract(const Duration(minutes: 20)),
        orderType: 'delivery',
        subtotal: 28.97,
        tax: 2.90,
        tip: 4.00,
        deliveryFee: 3.99,
        total: 39.86,
        paymentMethod: 'cash',
        isPaid: true,
        deliveryAddress: '123 Main St, Apt 4B, New York, NY 10001',
      ),
      OrderModel(
        id: '3',
        userId: '3',
        items: [
          OrderItemModel(
            menuItemId: '5',
            name: 'Vegan Buddha Bowl',
            price: 13.99,
            quantity: 1,
          ),
        ],
        status: 'pending',
        orderTime: DateTime.now().subtract(const Duration(minutes: 5)),
        orderType: 'takeaway',
        subtotal: 13.99,
        tax: 1.40,
        tip: 0.00,
        deliveryFee: 0.00,
        total: 15.39,
        paymentMethod: 'credit_card',
        paymentId: 'pay_789012',
        isPaid: false,
        notes: 'Will pick up in 15 minutes',
      ),
    ];
  }
}
