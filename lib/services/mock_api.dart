// This file provides mock API responses when the real backend server is not available
// It mimics the real API responses format for testing and development

import 'dart:convert';

class MockApi {
  // Health check endpoint
  static Map<String, dynamic> getHealth() {
    return {'status': 'ok'};
  }

  // Sample menu items data
  static List<Map<String, dynamic>> getMenuItems() {
    return [
      {
        'id': '1',
        'name': 'Garden Fresh Salad',
        'description':
            'Crisp mixed greens, cherry tomatoes, cucumber, red onion, and carrot with our house vinaigrette.',
        'price': 8.99,
        'imageUrl': '/uploads/menu/garden-fresh-salad.jpg',
        'category': 'Starters',
        'ingredients': [
          'Mixed greens',
          'Cherry tomatoes',
          'Cucumber',
          'Red onion',
          'Carrot',
          'House vinaigrette'
        ],
        'isVegetarian': true,
        'isVegan': true,
        'isGlutenFree': true,
        'rating': 4.2
      },
      {
        'id': '2',
        'name': 'Grilled Salmon',
        'description':
            'Grilled Atlantic salmon served with seasonal vegetables and lemon butter sauce.',
        'price': 22.99,
        'imageUrl': '/uploads/menu/grilled-salmon.jpg',
        'category': 'Main Course',
        'ingredients': [
          'Atlantic salmon',
          'Seasonal vegetables',
          'Lemon',
          'Butter',
          'Garlic',
          'Herbs'
        ],
        'isGlutenFree': true,
        'rating': 4.8
      },
      {
        'id': '3',
        'name': 'Chocolate Lava Cake',
        'description':
            'Warm chocolate cake with a molten center, served with vanilla ice cream.',
        'price': 9.99,
        'imageUrl': '/uploads/menu/chocolate-lava-cake.jpg',
        'category': 'Desserts',
        'ingredients': [
          'Dark chocolate',
          'Butter',
          'Eggs',
          'Flour',
          'Sugar',
          'Vanilla ice cream'
        ],
        'isVegetarian': true,
        'rating': 4.9
      }
    ];
  }

  // Sample rooms data
  static List<Map<String, dynamic>> getRooms() {
    return [
      {
        'id': '1',
        'roomNumber': '101',
        'roomType': 'Deluxe',
        'price': 199.99,
        'capacity': 2,
        'amenities': ['Wi-Fi', 'TV', 'Mini Bar', 'AC', 'Room Service'],
        'imageUrl': '/uploads/rooms/deluxe-room-101.jpg',
        'status': 'Available',
        'description':
            'Spacious deluxe room with city view and all modern amenities.',
        'floor': 1,
        'isAvailable': true,
        'size': '30 m²'
      },
      {
        'id': '2',
        'roomNumber': '201',
        'roomType': 'Suite',
        'price': 299.99,
        'capacity': 4,
        'amenities': [
          'Wi-Fi',
          'TV',
          'Mini Bar',
          'AC',
          'Room Service',
          'Jacuzzi'
        ],
        'imageUrl': '/uploads/rooms/suite-201.jpg',
        'status': 'Available',
        'description':
            'Luxurious suite with separate living area and panoramic views.',
        'floor': 2,
        'isAvailable': true,
        'size': '45 m²'
      },
      {
        'id': '3',
        'roomNumber': '301',
        'roomType': 'Standard',
        'price': 149.99,
        'capacity': 2,
        'amenities': ['Wi-Fi', 'TV', 'AC'],
        'imageUrl': '/uploads/rooms/standard-room-301.jpg',
        'status': 'Available',
        'description': 'Comfortable standard room with all basic amenities.',
        'floor': 3,
        'isAvailable': true,
        'size': '25 m²'
      }
    ];
  }

  // Sample tables data
  static List<Map<String, dynamic>> getTables() {
    return [
      {
        'id': '1',
        'tableNumber': 'T1',
        'capacity': 2,
        'location': 'Window',
        'status': 'Available',
        'imageUrl': '/uploads/tables/table-t1.jpg'
      },
      {
        'id': '2',
        'tableNumber': 'T2',
        'capacity': 4,
        'location': 'Center',
        'status': 'Available',
        'imageUrl': '/uploads/tables/table-t2.jpg'
      },
      {
        'id': '3',
        'tableNumber': 'T3',
        'capacity': 6,
        'location': 'Outdoor',
        'status': 'Available',
        'imageUrl': '/uploads/tables/table-t3.jpg'
      },
      {
        'id': '4',
        'tableNumber': 'T4',
        'capacity': 8,
        'location': 'Private Room',
        'status': 'Available',
        'imageUrl': '/uploads/tables/table-t4.jpg'
      }
    ];
  }

  // Generate a mock HTTP response
  static Map<String, dynamic> mockResponse(dynamic data) {
    return {'statusCode': 200, 'body': jsonEncode(data)};
  }
}
// Minor change for contribution
