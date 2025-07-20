import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/room_model.dart';
import 'api_service.dart';

class RoomService {
  // Singleton pattern
  static final RoomService _instance = RoomService._internal();
  factory RoomService() => _instance;
  RoomService._internal();

  Future<List<RoomModel>> getRooms() async {
    try {
      print('Fetching rooms...');
      
      final response = await APIService.instance.get('api/rooms');
      
      print('Rooms response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Successfully loaded ${data.length} rooms');
        return data.map((item) => _mapApiItemToModel(item)).toList();
      } else {
        print('Failed to load rooms: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load rooms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching rooms: $e');
      // Fallback to sample data if the API call fails
      return _sampleRooms;
    }
  }

  Future<RoomModel?> getRoom(String id) async {
    try {
      final response = await APIService.instance.get('api/rooms/$id');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // API might return either a single object or an array with one object
        if (data is List && data.isNotEmpty) {
          // Handle array response
          return _mapApiItemToModel(data.first);
        } else if (data is Map<String, dynamic>) {
          // Handle single object response
          return _mapApiItemToModel(data);
        }
      }
      
      print('Failed to load room: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Exception when loading room: $e');
      return null;
    }
  }

  // Maps API response to RoomModel
  RoomModel _mapApiItemToModel(Map<String, dynamic> apiItem) {
    try {
      print('Mapping room: ${apiItem.toString()}');
      
      // Handle image URL - ensure we're using the correct field from the backend
      String imageUrl = APIService.mapImageUrl(apiItem['image']);
      
      return RoomModel(
        id: apiItem['_id'] ?? apiItem['id'] ?? '',
        roomNumber: apiItem['roomName']?.toString() ?? '000',
        roomType: apiItem['roomType'] ?? 'Standard',
        pricePerNight: (apiItem['price'] is num) 
            ? apiItem['price'].toDouble() 
            : double.tryParse(apiItem['price']?.toString() ?? '0') ?? 0.0,
        capacity: 2, // Default capacity since it's not in the backend
        amenities: ['Wi-Fi', 'TV', 'AC'], // Default amenities since they're not in the backend
        imageUrls: [imageUrl],
        status: 'Available',
        description: apiItem['description'] ?? 'No description available.',
        floor: 1, // Default floor since it's not in the backend
        isAvailable: true,
        size: 'Standard',
      );
    } catch (e) {
      print('Error mapping room: $e');
      print('Problematic item: $apiItem');
      
      // Return a minimal valid object rather than crashing
      return RoomModel(
        id: apiItem['_id'] ?? apiItem['id'] ?? 'error-${DateTime.now().millisecondsSinceEpoch}',
        roomNumber: 'Error',
        roomType: 'Standard',
        pricePerNight: 0.0,
        capacity: 2,
        amenities: ['Wi-Fi'],
        imageUrls: [],
        status: 'Error',
        description: 'There was an error loading this room.',
        floor: 1,
        isAvailable: false,
        size: 'Standard',
      );
    }
  }

  // Sample rooms for fallback
  final List<RoomModel> _sampleRooms = [
    const RoomModel(
      id: '1',
      roomNumber: 'Room 101',
      roomType: 'Deluxe',
      pricePerNight: 199.99,
      capacity: 2,
      amenities: ['Wi-Fi', 'TV', 'Mini Bar', 'AC', 'Room Service'],
      imageUrls: ['https://images.unsplash.com/photo-1566665797739-1674de7a421a?ixlib=rb-4.0.3&auto=format&fit=crop&w=600'],
      status: 'Available',
      description: 'Spacious deluxe room with city view and all modern amenities.',
      floor: 1,
    ),
    const RoomModel(
      id: '2',
      roomNumber: 'Room 201',
      roomType: 'Suite',
      pricePerNight: 299.99,
      capacity: 4,
      amenities: ['Wi-Fi', 'TV', 'Mini Bar', 'AC', 'Room Service', 'Jacuzzi'],
      imageUrls: ['https://images.unsplash.com/photo-1578683010236-d716f9a3f461?ixlib=rb-4.0.3&auto=format&fit=crop&w=600'],
      status: 'Available',
      description: 'Luxurious suite with separate living area and panoramic views.',
      floor: 2,
    ),
    const RoomModel(
      id: '3',
      roomNumber: 'Room 301',
      roomType: 'Standard',
      pricePerNight: 149.99,
      capacity: 2,
      amenities: ['Wi-Fi', 'TV', 'AC'],
      imageUrls: ['https://images.unsplash.com/photo-1611892440504-42a792e24d32?ixlib=rb-4.0.3&auto=format&fit=crop&w=600'],
      status: 'Available',
      description: 'Comfortable standard room with all basic amenities.',
      floor: 3,
    ),
  ];
} 