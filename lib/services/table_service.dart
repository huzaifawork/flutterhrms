import 'dart:convert';
import '../data/models/table_model.dart';
import 'api_service.dart';

class TableService {
  // Singleton pattern
  static final TableService _instance = TableService._internal();
  factory TableService() => _instance;
  TableService._internal();

  Future<List<TableModel>> getTables() async {
    try {
      print('Fetching tables...');

      final response = await APIService.instance.get('api/tables');

      print('Tables response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Successfully loaded ${data.length} tables');
        return data.map((item) => _mapApiItemToModel(item)).toList();
      } else {
        print(
            'Failed to load tables: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load tables: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tables: $e');
      // Fallback to sample data if the API call fails
      return _sampleTables;
    }
  }

  Future<List<TableModel>> getTablesWithAvailability({
    required DateTime date,
    required String timeSlot,
  }) async {
    try {
      print('Fetching tables with availability for $date at $timeSlot...');

      // Calculate end time (2 hours later)
      final startTime = timeSlot;
      final startHour = int.parse(startTime.split(':')[0]);
      final startMinute = int.parse(startTime.split(':')[1]);
      final endHour = (startHour + 2) % 24;
      final endTime =
          '${endHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

      final response = await APIService.instance.get(
          'api/tables/availability?reservationDate=${date.toIso8601String().split('T')[0]}&time=$timeSlot&endTime=$endTime');

      print('Tables availability response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Successfully loaded ${data.length} tables with availability');
        return data.map((item) => _mapAvailabilityItemToModel(item)).toList();
      } else {
        print(
            'Failed to load tables availability: ${response.statusCode}, Body: ${response.body}');
        // Fallback to regular tables if availability check fails
        return await getTables();
      }
    } catch (e) {
      print('Error fetching tables with availability: $e');
      // Fallback to regular tables if availability check fails
      return await getTables();
    }
  }

  Future<TableModel?> getTable(String id) async {
    try {
      final response = await APIService.instance.get('api/tables/$id');

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

      print('Failed to load table: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Exception when loading table: $e');
      return null;
    }
  }

  // Maps availability API response to TableModel
  TableModel _mapAvailabilityItemToModel(
      Map<String, dynamic> availabilityItem) {
    try {
      final tableData = availabilityItem['table'] as Map<String, dynamic>;
      final isAvailable = availabilityItem['isAvailable'] as bool;

      print('Mapping table availability: ${availabilityItem.toString()}');

      // Use the image field if available
      String? imagePath = tableData['image'];
      String imageUrl = APIService.mapImageUrl(imagePath);

      return TableModel(
        id: tableData['_id'] ?? tableData['id'] ?? '',
        tableNumber: tableData['tableName']?.toString() ?? '0',
        capacity: tableData['capacity'] is int
            ? tableData['capacity']
            : int.tryParse(tableData['capacity']?.toString() ?? '2') ?? 2,
        location: tableData['tableType'] ?? 'Main Area',
        status: isAvailable ? 'Available' : 'Reserved',
        isReserved: !isAvailable,
        reservedBy: null,
        reservationTime: null,
        imageUrl: imageUrl,
      );
    } catch (e) {
      print('Error mapping table availability: $e');
      print('Problematic item: $availabilityItem');

      // Return a minimal valid object rather than crashing
      return TableModel(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        tableNumber: 'Error',
        capacity: 2,
        location: 'Error',
        status: 'Error',
        imageUrl: '',
      );
    }
  }

  // Maps API response to TableModel
  TableModel _mapApiItemToModel(Map<String, dynamic> apiItem) {
    try {
      print('Mapping table: ${apiItem.toString()}');

      // Check both image fields from the backend
      print('Table image field: ${apiItem['image']}');
      print('Table imageUrl field: ${apiItem['imageUrl']}');

      // Use the image field if available, otherwise try imageUrl
      String? imagePath = apiItem['image'];
      if (imagePath == null || imagePath.isEmpty) {
        imagePath = apiItem['imageUrl'];
      }

      // Map the image URL
      String imageUrl = APIService.mapImageUrl(imagePath);
      print('Final table image URL: $imageUrl');

      return TableModel(
        id: apiItem['_id'] ?? apiItem['id'] ?? '',
        tableNumber: apiItem['tableName']?.toString() ?? '0',
        capacity: apiItem['capacity'] is int
            ? apiItem['capacity']
            : int.tryParse(apiItem['capacity']?.toString() ?? '2') ?? 2,
        location: apiItem['tableType'] ?? 'Main Area',
        status: apiItem['status'] ?? 'Available',
        isReserved: false,
        reservedBy: null,
        reservationTime: null,
        imageUrl: imageUrl,
      );
    } catch (e) {
      print('Error mapping table: $e');
      print('Problematic item: $apiItem');

      // Return a minimal valid object rather than crashing
      return TableModel(
        id: apiItem['_id'] ??
            apiItem['id'] ??
            'error-${DateTime.now().millisecondsSinceEpoch}',
        tableNumber: 'Error',
        capacity: 2,
        location: 'Error',
        status: 'Error',
        imageUrl: '',
      );
    }
  }

  // Sample tables for fallback
  final List<TableModel> _sampleTables = [
    TableModel(
      id: '1',
      tableNumber: 'T1',
      capacity: 2,
      location: 'Window',
      status: 'Available',
      imageUrl:
          'https://images.unsplash.com/photo-1559329007-40df8a9345d8?ixlib=rb-4.0.3&auto=format&fit=crop&w=600',
    ),
    TableModel(
      id: '2',
      tableNumber: 'T2',
      capacity: 4,
      location: 'Center',
      status: 'Available',
      imageUrl:
          'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?ixlib=rb-4.0.3&auto=format&fit=crop&w=600',
    ),
    TableModel(
      id: '3',
      tableNumber: 'T3',
      capacity: 6,
      location: 'Outdoor',
      status: 'Available',
      imageUrl:
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?ixlib=rb-4.0.3&auto=format&fit=crop&w=600',
    ),
    TableModel(
      id: '4',
      tableNumber: 'T4',
      capacity: 8,
      location: 'Private Room',
      status: 'Available',
      imageUrl:
          'https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?ixlib=rb-4.0.3&auto=format&fit=crop&w=600',
    ),
  ];
}
