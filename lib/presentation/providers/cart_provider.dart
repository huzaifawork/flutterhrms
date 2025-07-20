import 'package:flutter/foundation.dart';

import '../models/cart_item_model.dart';
import '../../data/models/menu_item_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + (item.menuItem.price * item.quantity));
  }

  void addItem({
    required MenuItemModel menuItem, 
    required int quantity,
    List<String> customizations = const [],
    String specialInstructions = '',
  }) {
    // Check if the item is already in the cart
    final existingItemIndex = _items.indexWhere(
      (item) => 
        item.menuItem.id == menuItem.id && 
        _listEquals(item.customizations, customizations) &&
        item.specialInstructions == specialInstructions
    );

    if (existingItemIndex >= 0) {
      // Update quantity if item exists with same customizations
      _items[existingItemIndex] = _items[existingItemIndex].copyWith(
        quantity: _items[existingItemIndex].quantity + quantity,
      );
    } else {
      // Add new item
      _items.add(
        CartItemModel(
          menuItem: menuItem,
          quantity: quantity,
          customizations: customizations,
          specialInstructions: specialInstructions,
        ),
      );
    }

    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Helper method to compare lists of customizations
  bool _listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
} 