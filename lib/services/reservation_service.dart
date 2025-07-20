import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/constants/app_constants.dart';
import '../data/models/reservation_model.dart';
import '../data/models/table_model.dart';
import 'auth_service.dart';

class ReservationService {
  static final ReservationService _instance = ReservationService._internal();
  factory ReservationService() => _instance;
  ReservationService._internal();

  Dio? _dio;

  void initialize() {
    if (_dio != null) return; // Prevent re-initialization
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptor for token
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = AuthService().token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<Map<String, dynamic>> createReservation({
    required String tableId,
    required DateTime reservationDate,
    required String timeSlot,
    String? endTime,
    required int partySize,
    String? specialRequests,
    String? occasion,
    String? tableNumber,
    String? fullName,
    String? email,
    String? phone,
    String paymentMethod = 'card',
    String? paymentMethodId,
  }) async {
    try {
      // Use provided endTime or calculate it (2 hours after start time by default)
      final calculatedEndTime = endTime ??
          () {
            final startHour = int.parse(timeSlot.split(':')[0]);
            final startMinute = int.parse(timeSlot.split(':')[1]);
            final endHour = (startHour + 2) % 24;
            return '${endHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
          }();

      // Calculate total price (Rs. 500 per person - matching website)
      final totalPrice = partySize * 500.0;

      final reservationData = {
        'tableId': tableId,
        'tableNumber': tableNumber ?? 'T1',
        'reservationDate':
            reservationDate.toIso8601String().split('T')[0], // Date only
        'time': timeSlot,
        'endTime': calculatedEndTime,
        'guests': partySize,
        'payment': paymentMethod,
        'totalPrice': totalPrice,
        'phone': phone ?? '',
        'fullName': fullName ?? '',
        'email': email ?? '',
        'specialRequests': specialRequests ?? '',
        if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
      };

      print('Creating reservation with data: $reservationData');

      final response =
          await _dio!.post('/api/reservations', data: reservationData);

      if (response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'reservation': data['reservation'] ?? data,
          'message': data['message'] ?? 'Reservation created successfully',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Reservation failed',
      };
    } on DioException catch (e) {
      print('Reservation creation error: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('Unexpected reservation creation error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<List<ReservationModel>> getUserReservations() async {
    try {
      print('Fetching user reservations...');
      final response = await _dio!.get('/api/reservations/user');

      print('Reservations response status: ${response.statusCode}');
      print('Reservations response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> reservationsData;

        if (data is List) {
          reservationsData = data;
        } else if (data is Map && data['reservations'] != null) {
          reservationsData = data['reservations'];
        } else {
          reservationsData = [];
        }

        print('Found ${reservationsData.length} reservations');
        return reservationsData
            .map((item) => mapApiToReservationModel(item))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      print('Error fetching reservations: ${e.response?.data}');
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load reservations');
    } catch (e) {
      print('Unexpected error fetching reservations: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  Future<List<ReservationModel>> getAllReservations() async {
    try {
      final response = await _dio!.get('/api/reservations');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['reservations'];
        return data.map((item) => mapApiToReservationModel(item)).toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load reservations');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<ReservationModel?> getReservationById(String reservationId) async {
    try {
      final response = await _dio!.get('/api/reservations/$reservationId');

      if (response.statusCode == 200) {
        return mapApiToReservationModel(response.data['reservation']);
      }

      return null;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load reservation');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<Map<String, dynamic>> updateReservation(
      String reservationId, Map<String, dynamic> updates) async {
    try {
      final response =
          await _dio!.put('/api/reservations/$reservationId', data: updates);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'reservation': mapApiToReservationModel(response.data['reservation']),
          'message': response.data['message'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Update failed',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> cancelReservation(String reservationId) async {
    try {
      final response = await _dio!.delete('/api/reservations/$reservationId');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Cancellation failed',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> checkTableAvailability({
    required String tableId,
    required DateTime reservationDate,
    required String timeSlot,
    String? endTime,
  }) async {
    try {
      // Calculate end time if not provided (2 hours after start time)
      final calculatedEndTime = endTime ??
          () {
            final startHour = int.parse(timeSlot.split(':')[0]);
            final startMinute = int.parse(timeSlot.split(':')[1]);
            final endHour = (startHour + 2) % 24;
            return '${endHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
          }();

      final response =
          await _dio!.get('/api/tables/availability', queryParameters: {
        'reservationDate':
            reservationDate.toIso8601String().split('T')[0], // Date only
        'time': timeSlot,
        'endTime': calculatedEndTime,
      });

      if (response.statusCode == 200) {
        // Find the specific table in the response array (matching website logic)
        final List<dynamic> availabilityData = response.data;
        final tableAvailability = availabilityData.firstWhere(
          (item) => item['table']['_id'] == tableId,
          orElse: () => null,
        );

        if (tableAvailability != null) {
          final isAvailable = tableAvailability['isAvailable'] == true;
          return {
            'available': isAvailable,
            'message': isAvailable
                ? 'Table is available for reservation!'
                : 'This table is already reserved during the selected time range. Please choose a different time or select another table.',
          };
        } else {
          return {
            'available': true, // Default to available if table not found
            'message': 'Table availability status unknown',
          };
        }
      }

      return {
        'available': false,
        'message': 'Unable to check availability',
      };
    } on DioException catch (e) {
      print('Availability check error: ${e.response?.data}');
      return {
        'available': true, // Default to available on error (like website)
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('Unexpected availability check error: $e');
      return {
        'available': true, // Default to available on error
        'message': 'An unexpected error occurred',
      };
    }
  }

  ReservationModel mapApiToReservationModel(Map<String, dynamic> apiData) {
    // Handle tableId - it could be a string or an object (when populated)
    String tableId;
    TableModel? table;

    if (apiData['tableId'] is String) {
      tableId = apiData['tableId'];
      table = apiData['table'] != null
          ? mapApiToTableModel(apiData['table'])
          : null;
    } else if (apiData['tableId'] is Map<String, dynamic>) {
      // tableId is populated with table data
      final tableData = apiData['tableId'] as Map<String, dynamic>;
      tableId = tableData['_id'] ?? tableData['id'] ?? '';
      table = mapApiToTableModel(tableData);
    } else {
      tableId = apiData['tableId']?.toString() ?? '';
      table = null;
    }

    // Handle userId - it could be a string or an object (when populated)
    String userId;
    if (apiData['userId'] is String) {
      userId = apiData['userId'];
    } else if (apiData['userId'] is Map<String, dynamic>) {
      final userData = apiData['userId'] as Map<String, dynamic>;
      userId = userData['_id'] ?? userData['id'] ?? '';
    } else {
      userId = apiData['userId']?.toString() ?? '';
    }

    return ReservationModel(
      id: apiData['_id'] ?? apiData['id'] ?? '',
      userId: userId,
      tableId: tableId,
      reservationDate: DateTime.parse(apiData['reservationDate']),
      timeSlot:
          apiData['time'] ?? apiData['timeSlot'] ?? '', // Backend uses 'time'
      endTime: apiData['endTime']?.toString(),
      partySize: apiData['guests'] ??
          apiData['partySize'] ??
          1, // Backend uses 'guests'
      status: apiData['paymentStatus'] ??
          apiData['status'] ??
          'pending', // Backend uses 'paymentStatus'
      specialRequests: apiData['specialRequests']?.toString(),
      occasion: apiData['occasion']?.toString(),
      createdAt: apiData['createdAt'] != null
          ? DateTime.parse(apiData['createdAt'])
          : DateTime.now(),
      updatedAt: apiData['updatedAt'] != null
          ? DateTime.parse(apiData['updatedAt'])
          : DateTime.now(),
      table: table,
    );
  }

  TableModel mapApiToTableModel(Map<String, dynamic> apiData) {
    return TableModel(
      id: apiData['_id'] ?? apiData['id'] ?? '',
      tableNumber: apiData['tableName'] ??
          apiData['tableNumber']?.toString() ??
          '', // Backend uses 'tableName'
      capacity: apiData['capacity'] is int
          ? apiData['capacity']
          : int.tryParse(apiData['capacity']?.toString() ?? '0') ?? 0,
      location: apiData['location']?.toString() ?? 'Main Hall',
      status: apiData['status']?.toString() ?? 'Available',
      isReserved: apiData['status']?.toString().toLowerCase() == 'reserved',
      reservedBy: apiData['reservedBy']?.toString(),
      reservationTime: apiData['reservationTime'] != null
          ? DateTime.tryParse(apiData['reservationTime'].toString())
          : null,
      imageUrl: apiData['image']?.toString() ?? apiData['imageUrl']?.toString(),
    );
  }
}

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

  ReservationModel({
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

  bool get isActive => status == 'confirmed' || status == 'seated';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Confirmation';
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

  static List<ReservationModel> dummyReservations() {
    return [
      ReservationModel(
        id: '1',
        userId: 'user1',
        tableId: 'table1',
        reservationDate: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '19:00',
        endTime: '21:00',
        partySize: 4,
        status: 'confirmed',
        specialRequests: 'Window seat preferred',
        occasion: 'Anniversary',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        table: TableModel.dummyTables().first,
      ),
    ];
  }
}
