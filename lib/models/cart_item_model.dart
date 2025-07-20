import 'package:uuid/uuid.dart';
import 'menu_item_model.dart';

class CartItemModel {
  final String id;
  final MenuItemModel menuItem;
  final int quantity;
  final List<String> customizations;
  final String specialInstructions;

  CartItemModel({
    String? id,
    required this.menuItem,
    required this.quantity,
    this.customizations = const [],
    this.specialInstructions = '',
  }) : id = id ?? const Uuid().v4();

  double get totalPrice => menuItem.price * quantity;

  CartItemModel copyWith({
    String? id,
    MenuItemModel? menuItem,
    int? quantity,
    List<String>? customizations,
    String? specialInstructions,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      customizations: customizations ?? this.customizations,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  @override
  String toString() {
    return 'CartItem(id: $id, menuItem: ${menuItem.name}, quantity: $quantity)';
  }
} 