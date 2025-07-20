import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/menu_item_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../orders/cart_screen.dart';

class MenuItemDetailScreen extends StatefulWidget {
  final MenuItemModel menuItem;

  const MenuItemDetailScreen({
    super.key,
    required this.menuItem,
  });

  @override
  State<MenuItemDetailScreen> createState() => _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends State<MenuItemDetailScreen> {
  int _quantity = 1;
  final List<String> _selectedOptions = [];
  String? _specialInstructions;
  final TextEditingController _instructionsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  List<String> get _availableOptions {
    switch (widget.menuItem.category.toLowerCase()) {
      case 'breakfast':
        return [
          'Extra toast',
          'No eggs',
          'Substitute fruit',
          'Add bacon',
          'Add avocado'
        ];
      case 'lunch':
      case 'dinner':
        return [
          'Extra sauce',
          'No onions',
          'Spicy',
          'Well done',
          'Medium rare'
        ];
      case 'desserts':
        return [
          'Extra cream',
          'No sugar',
          'Add chocolate sauce',
          'Add berries'
        ];
      case 'drinks':
        return ['No ice', 'Extra ice', 'Sugar free', 'Add lemon', 'Add mint'];
      default:
        return ['Extra sauce', 'No onions', 'Spicy'];
    }
  }

  double get _totalPrice {
    double optionsPrice = 0;
    for (var option in _selectedOptions) {
      // Add $1 for each selected option
      optionsPrice += 1.0;
    }
    return (widget.menuItem.price + optionsPrice) * _quantity;
  }

  Future<void> _addToCart() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Add the item to the cart
      cartProvider.addItem(
        menuItem: widget.menuItem,
        quantity: _quantity,
        customizations: _selectedOptions,
        specialInstructions: _specialInstructions ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.menuItem.name} added to cart'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'VIEW CART',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to cart screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CartScreen(),
                  ),
                );
              },
            ),
          ),
        );

        // Return to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isLoggedIn = user != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with item image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Item image
                  Image.network(
                    widget.menuItem.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.restaurant,
                          size: 64,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  // Gradient overlay for better visibility
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                        ],
                        stops: [0.7, 1.0],
                      ),
                    ),
                  ),
                  // Item name and price at the bottom
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.menuItem.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 2,
                                color: Colors.black,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'PKR ${widget.menuItem.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                blurRadius: 2,
                                color: Colors.black,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu item details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dietary tags
                  Row(
                    children: [
                      if (widget.menuItem.isVegetarian)
                        _buildTag('Vegetarian', Colors.green),
                      if (widget.menuItem.isVegan)
                        _buildTag('Vegan', Colors.green),
                      if (widget.menuItem.isGlutenFree)
                        _buildTag('Gluten Free', Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.menuItem.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Ingredients
                  Text(
                    'Ingredients',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.menuItem.ingredients.map((ingredient) {
                      return Chip(
                        label: Text(ingredient),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Quantity selector
                  Text(
                    'Quantity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _quantity.toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _quantity++;
                          });
                        },
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Customization options
                  Text(
                    'Customization',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: _availableOptions.map((option) {
                      return CheckboxListTile(
                        title: Text(option),
                        subtitle: const Text('+\$1.00'),
                        value: _selectedOptions.contains(option),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedOptions.add(option);
                            } else {
                              _selectedOptions.remove(option);
                            }
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Special instructions
                  Text(
                    'Special Instructions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _instructionsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add any special requests here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _specialInstructions = value.isEmpty ? null : value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Nutritional information
                  Text(
                    'Nutritional Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildNutritionRow(
                              'Calories', '${widget.menuItem.calories} kcal'),
                          const Divider(),
                          _buildNutritionRow(
                              'Protein', '${widget.menuItem.protein}g'),
                          const Divider(),
                          _buildNutritionRow(
                              'Carbs', '${widget.menuItem.carbs}g'),
                          const Divider(),
                          _buildNutritionRow('Fat', '${widget.menuItem.fat}g'),
                        ],
                      ),
                    ),
                  ),

                  // Space for the bottom button
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Price',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  Text(
                    'PKR ${_totalPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoggedIn && !_isLoading ? _addToCart : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(isLoggedIn ? 'Add to Cart' : 'Login to Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
