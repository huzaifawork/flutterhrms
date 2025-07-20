import '../models/menu_item_model.dart';

class MenuService {
  // Singleton pattern
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;
  MenuService._internal();

  Future<List<MenuItemModel>> getMenuItems() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _sampleMenuItems;
  }

  Future<List<String>> getCategories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _categories;
  }

  Future<MenuItemModel?> getMenuItem(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _sampleMenuItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // Sample categories
  final List<String> _categories = [
    'All',
    'Starters',
    'Main Course',
    'Desserts', 
    'Beverages',
    'Specials'
  ];

  // Sample menu items
  final List<MenuItemModel> _sampleMenuItems = [
    MenuItemModel(
      id: '1',
      name: 'Garden Fresh Salad',
      description: 'Crisp mixed greens, cherry tomatoes, cucumber, red onion, and carrot with our house vinaigrette.',
      price: 8.99,
      imageUrl: 'https://images.unsplash.com/photo-1546793665-c74683f339c1',
      category: 'Starters',
      ingredients: [
        'Mixed greens',
        'Cherry tomatoes',
        'Cucumber',
        'Red onion',
        'Carrot',
        'House vinaigrette'
      ],
      dietaryTags: ['Vegetarian', 'Vegan', 'Gluten-Free'],
      nutritionalInfo: {
        'calories': 120,
        'protein': 3,
        'carbs': 10,
        'fat': 7,
      },
      rating: 4.2,
      reviewCount: 48,
      customizationOptions: [
        CustomizationOption(
          name: 'Add Protein',
          choices: [
            CustomizationChoice(
              name: 'Grilled Chicken',
              additionalPrice: 3.99,
            ),
            CustomizationChoice(
              name: 'Salmon',
              additionalPrice: 5.99,
            ),
            CustomizationChoice(
              name: 'Tofu',
              additionalPrice: 2.99,
            ),
          ],
          maxChoices: 1,
        ),
        CustomizationOption(
          name: 'Dressing',
          choices: [
            CustomizationChoice(name: 'House Vinaigrette'),
            CustomizationChoice(name: 'Ranch'),
            CustomizationChoice(name: 'Balsamic'),
            CustomizationChoice(name: 'Olive Oil & Lemon'),
          ],
          required: true,
          maxChoices: 1,
        ),
      ],
    ),
    MenuItemModel(
      id: '2',
      name: 'Grilled Salmon',
      description: 'Grilled Atlantic salmon served with seasonal vegetables and lemon butter sauce.',
      price: 22.99,
      imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2',
      category: 'Main Course',
      ingredients: [
        'Atlantic salmon',
        'Seasonal vegetables',
        'Lemon',
        'Butter',
        'Garlic',
        'Herbs'
      ],
      dietaryTags: ['Gluten-Free', 'High Protein'],
      nutritionalInfo: {
        'calories': 420,
        'protein': 38,
        'carbs': 12,
        'fat': 24,
      },
      rating: 4.8,
      reviewCount: 124,
      customizationOptions: [
        CustomizationOption(
          name: 'Cooking Preference',
          choices: [
            CustomizationChoice(name: 'Medium Rare'),
            CustomizationChoice(name: 'Medium'),
            CustomizationChoice(name: 'Well Done'),
          ],
          required: true,
          maxChoices: 1,
        ),
        CustomizationOption(
          name: 'Side Options',
          choices: [
            CustomizationChoice(name: 'Mashed Potatoes'),
            CustomizationChoice(name: 'Roasted Potatoes'),
            CustomizationChoice(name: 'Steamed Rice'),
            CustomizationChoice(
              name: 'Quinoa',
              additionalPrice: 1.99,
            ),
          ],
          required: true,
          maxChoices: 1,
        ),
      ],
    ),
    MenuItemModel(
      id: '3',
      name: 'Chocolate Lava Cake',
      description: 'Warm chocolate cake with a molten center, served with vanilla ice cream.',
      price: 9.99,
      imageUrl: 'https://images.unsplash.com/photo-1616031036718-23c6971345a4',
      category: 'Desserts',
      ingredients: [
        'Dark chocolate',
        'Butter',
        'Eggs',
        'Flour',
        'Sugar',
        'Vanilla ice cream'
      ],
      dietaryTags: ['Vegetarian'],
      nutritionalInfo: {
        'calories': 450,
        'protein': 6,
        'carbs': 55,
        'fat': 22,
      },
      allergens: ['Gluten', 'Dairy', 'Eggs'],
      rating: 4.9,
      reviewCount: 89,
      customizationOptions: [
        CustomizationOption(
          name: 'Ice Cream Flavor',
          choices: [
            CustomizationChoice(name: 'Vanilla'),
            CustomizationChoice(name: 'Chocolate'),
            CustomizationChoice(
              name: 'Salted Caramel',
              additionalPrice: 1.49,
            ),
          ],
          required: true,
          maxChoices: 1,
        ),
        CustomizationOption(
          name: 'Toppings',
          choices: [
            CustomizationChoice(name: 'Chocolate Sauce'),
            CustomizationChoice(name: 'Caramel Sauce'),
            CustomizationChoice(name: 'Berry Compote'),
            CustomizationChoice(
              name: 'Whipped Cream',
              additionalPrice: 0.99,
            ),
          ],
          maxChoices: 2,
        ),
      ],
      preparationTimeMinutes: 20,
    ),
    MenuItemModel(
      id: '4',
      name: 'Classic Cheeseburger',
      description: 'Juicy beef patty with cheddar cheese, lettuce, tomato, and our special sauce on a brioche bun.',
      price: 14.99,
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
      category: 'Main Course',
      ingredients: [
        'Beef patty',
        'Cheddar cheese',
        'Lettuce',
        'Tomato',
        'Special sauce',
        'Brioche bun'
      ],
      nutritionalInfo: {
        'calories': 650,
        'protein': 32,
        'carbs': 40,
        'fat': 38,
      },
      allergens: ['Gluten', 'Dairy'],
      rating: 4.5,
      reviewCount: 210,
      customizationOptions: [
        CustomizationOption(
          name: 'Cooking Preference',
          choices: [
            CustomizationChoice(name: 'Medium Rare'),
            CustomizationChoice(name: 'Medium'),
            CustomizationChoice(name: 'Well Done'),
          ],
          required: true,
          maxChoices: 1,
        ),
        CustomizationOption(
          name: 'Add-ons',
          choices: [
            CustomizationChoice(
              name: 'Bacon',
              additionalPrice: 1.99,
            ),
            CustomizationChoice(
              name: 'Avocado',
              additionalPrice: 1.99,
            ),
            CustomizationChoice(
              name: 'Fried Egg',
              additionalPrice: 1.49,
            ),
            CustomizationChoice(
              name: 'Extra Cheese',
              additionalPrice: 0.99,
            ),
          ],
          maxChoices: 4,
        ),
        CustomizationOption(
          name: 'Side Options',
          choices: [
            CustomizationChoice(name: 'French Fries'),
            CustomizationChoice(name: 'Sweet Potato Fries', additionalPrice: 1.49),
            CustomizationChoice(name: 'Side Salad'),
            CustomizationChoice(name: 'Onion Rings', additionalPrice: 1.99),
          ],
          required: true,
          maxChoices: 1,
        ),
      ],
    ),
    MenuItemModel(
      id: '5',
      name: 'Margherita Pizza',
      description: 'Classic Neapolitan pizza with tomato sauce, fresh mozzarella, basil, and extra virgin olive oil.',
      price: 15.99,
      imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002',
      category: 'Main Course',
      ingredients: [
        'Pizza dough',
        'Tomato sauce',
        'Fresh mozzarella',
        'Fresh basil',
        'Extra virgin olive oil',
        'Salt'
      ],
      dietaryTags: ['Vegetarian'],
      nutritionalInfo: {
        'calories': 800,
        'protein': 24,
        'carbs': 90,
        'fat': 32,
      },
      allergens: ['Gluten', 'Dairy'],
      rating: 4.6,
      reviewCount: 178,
      customizationOptions: [
        CustomizationOption(
          name: 'Crust Type',
          choices: [
            CustomizationChoice(name: 'Traditional'),
            CustomizationChoice(name: 'Thin Crust'),
            CustomizationChoice(name: 'Gluten-Free', additionalPrice: 2.99),
          ],
          required: true,
          maxChoices: 1,
        ),
        CustomizationOption(
          name: 'Additional Toppings',
          choices: [
            CustomizationChoice(name: 'Mushrooms', additionalPrice: 1.49),
            CustomizationChoice(name: 'Bell Peppers', additionalPrice: 1.49),
            CustomizationChoice(name: 'Onions', additionalPrice: 1.49),
            CustomizationChoice(name: 'Olives', additionalPrice: 1.49),
            CustomizationChoice(name: 'Pepperoni', additionalPrice: 1.99),
            CustomizationChoice(name: 'Sausage', additionalPrice: 1.99),
          ],
          maxChoices: 6,
        ),
      ],
      preparationTimeMinutes: 25,
    ),
    MenuItemModel(
      id: '6',
      name: 'Classic Mojito',
      description: 'Refreshing cocktail with white rum, fresh lime juice, mint leaves, sugar, and soda water.',
      price: 9.99,
      imageUrl: 'https://images.unsplash.com/photo-1551538827-9c037cb4f32a',
      category: 'Beverages',
      ingredients: [
        'White rum',
        'Fresh lime juice',
        'Mint leaves',
        'Sugar',
        'Soda water',
        'Ice'
      ],
      dietaryTags: ['Vegan', 'Gluten-Free'],
      nutritionalInfo: {
        'calories': 180,
        'protein': 0,
        'carbs': 15,
        'fat': 0,
      },
      rating: 4.7,
      reviewCount: 92,
      customizationOptions: [
        CustomizationOption(
          name: 'Sweetness Level',
          choices: [
            CustomizationChoice(name: 'Less Sweet'),
            CustomizationChoice(name: 'Standard'),
            CustomizationChoice(name: 'Extra Sweet'),
          ],
          maxChoices: 1,
        ),
        CustomizationOption(
          name: 'Alcohol Content',
          choices: [
            CustomizationChoice(name: 'Virgin (No Alcohol)', additionalPrice: -2.00),
            CustomizationChoice(name: 'Standard'),
            CustomizationChoice(name: 'Extra Shot', additionalPrice: 3.00),
          ],
          required: true,
          maxChoices: 1,
        ),
      ],
      preparationTimeMinutes: 5,
    ),
    MenuItemModel(
      id: '7',
      name: 'Chicken Tikka Masala',
      description: 'Grilled chicken in a creamy tomato curry sauce, served with basmati rice and naan bread.',
      price: 18.99,
      imageUrl: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641',
      category: 'Main Course',
      ingredients: [
        'Chicken breast',
        'Yogurt',
        'Tomatoes',
        'Cream',
        'Spices',
        'Basmati rice',
        'Naan bread'
      ],
      nutritionalInfo: {
        'calories': 720,
        'protein': 42,
        'carbs': 65,
        'fat': 32,
      },
      allergens: ['Dairy', 'Gluten'],
      rating: 4.8,
      reviewCount: 156,
      customizationOptions: [
        CustomizationOption(
          name: 'Spice Level',
          choices: [
            CustomizationChoice(name: 'Mild'),
            CustomizationChoice(name: 'Medium'),
            CustomizationChoice(name: 'Spicy'),
            CustomizationChoice(name: 'Extra Spicy'),
          ],
          required: true,
          maxChoices: 1,
        ),
        CustomizationOption(
          name: 'Bread Options',
          choices: [
            CustomizationChoice(name: 'Plain Naan'),
            CustomizationChoice(name: 'Garlic Naan', additionalPrice: 1.49),
            CustomizationChoice(name: 'Butter Naan', additionalPrice: 1.49),
            CustomizationChoice(name: 'No Bread', additionalPrice: -2.00),
          ],
          required: true,
          maxChoices: 1,
        ),
      ],
      preparationTimeMinutes: 25,
    ),
    MenuItemModel(
      id: '8',
      name: 'Vegetable Pad Thai',
      description: 'Rice noodles stir-fried with tofu, eggs, bean sprouts, and peanuts in a tamarind sauce.',
      price: 15.99,
      imageUrl: 'https://images.unsplash.com/photo-1559314809-0d155014e29e',
      category: 'Main Course',
      ingredients: [
        'Rice noodles',
        'Tofu',
        'Eggs',
        'Bean sprouts',
        'Green onions',
        'Peanuts',
        'Tamarind sauce'
      ],
      dietaryTags: ['Vegetarian'],
      nutritionalInfo: {
        'calories': 580,
        'protein': 22,
        'carbs': 78,
        'fat': 18,
      },
      allergens: ['Eggs', 'Peanuts', 'Soy'],
      rating: 4.5,
      reviewCount: 112,
      customizationOptions: [
        CustomizationOption(
          name: 'Protein Option',
          choices: [
            CustomizationChoice(name: 'Tofu'),
            CustomizationChoice(name: 'Chicken', additionalPrice: 2.99),
            CustomizationChoice(name: 'Shrimp', additionalPrice: 4.99),
            CustomizationChoice(name: 'No Protein', additionalPrice: -2.00),
          ],
          required: true,
          maxChoices: 1,
        ),
        CustomizationOption(
          name: 'Spice Level',
          choices: [
            CustomizationChoice(name: 'Mild'),
            CustomizationChoice(name: 'Medium'),
            CustomizationChoice(name: 'Spicy'),
          ],
          required: true,
          maxChoices: 1,
        ),
        CustomizationOption(
          name: 'Extras',
          choices: [
            CustomizationChoice(name: 'Extra Peanuts', additionalPrice: 0.99),
            CustomizationChoice(name: 'Extra Bean Sprouts', additionalPrice: 0.99),
            CustomizationChoice(name: 'Extra Lime', additionalPrice: 0.49),
          ],
          maxChoices: 3,
        ),
      ],
    ),
    MenuItemModel(
      id: '9',
      name: 'Seasonal Fruit Tart',
      description: 'Buttery pastry shell filled with vanilla custard and topped with seasonal fresh fruits.',
      price: 8.99,
      imageUrl: 'https://images.unsplash.com/photo-1464305795204-6f5bbfc7fb81',
      category: 'Desserts',
      ingredients: [
        'Butter pastry',
        'Vanilla custard',
        'Seasonal fruits',
        'Apricot glaze'
      ],
      dietaryTags: ['Vegetarian'],
      nutritionalInfo: {
        'calories': 380,
        'protein': 5,
        'carbs': 48,
        'fat': 19,
      },
      allergens: ['Gluten', 'Dairy', 'Eggs'],
      rating: 4.7,
      reviewCount: 76,
      customizationOptions: [
        CustomizationOption(
          name: 'Add-ons',
          choices: [
            CustomizationChoice(name: 'Whipped Cream', additionalPrice: 0.99),
            CustomizationChoice(name: 'Vanilla Ice Cream', additionalPrice: 1.99),
            CustomizationChoice(name: 'Chocolate Sauce', additionalPrice: 0.99),
          ],
          maxChoices: 3,
        ),
      ],
      preparationTimeMinutes: 10,
    ),
    MenuItemModel(
      id: '10',
      name: 'Signature Burger',
      description: 'Our house specialty with Wagyu beef, truffle aioli, caramelized onions, and aged cheddar on a brioche bun.',
      price: 24.99,
      imageUrl: 'https://images.unsplash.com/photo-1553979459-d2229ba7433b',
      category: 'Specials',
      ingredients: [
        'Wagyu beef patty',
        'Truffle aioli',
        'Caramelized onions',
        'Aged cheddar',
        'Arugula',
        'Brioche bun'
      ],
      nutritionalInfo: {
        'calories': 850,
        'protein': 48,
        'carbs': 42,
        'fat': 52,
      },
      allergens: ['Gluten', 'Dairy', 'Eggs'],
      rating: 4.9,
      reviewCount: 245,
      customizationOptions: [
        CustomizationOption(
          name: 'Cooking Preference',
          choices: [
            CustomizationChoice(name: 'Medium Rare'),
            CustomizationChoice(name: 'Medium'),
            CustomizationChoice(name: 'Medium Well'),
            CustomizationChoice(name: 'Well Done'),
          ],
          required: true,
          maxChoices: 1,
        ),
        CustomizationOption(
          name: 'Premium Add-ons',
          choices: [
            CustomizationChoice(name: 'Foie Gras', additionalPrice: 9.99),
            CustomizationChoice(name: 'Truffle Shavings', additionalPrice: 7.99),
            CustomizationChoice(name: 'Bacon Jam', additionalPrice: 2.99),
          ],
          maxChoices: 3,
        ),
        CustomizationOption(
          name: 'Side Options',
          choices: [
            CustomizationChoice(name: 'Truffle Fries'),
            CustomizationChoice(name: 'Sweet Potato Fries'),
            CustomizationChoice(name: 'Mixed Greens Salad'),
          ],
          required: true,
          maxChoices: 1,
        ),
      ],
      preparationTimeMinutes: 30,
    ),
  ];
} 