import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../data/models/booking_model.dart';
import '../data/models/room_model.dart';
import 'auth_service.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

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

  Future<Map<String, dynamic>> createBooking({
    required String roomId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int guests,
    String? specialRequests,
    String? roomType,
    String? roomNumber,
    String? fullName,
    String? email,
    String? phone,
    String paymentMethod = 'card',
    String? paymentMethodId,
    double? basePrice,
  }) async {
    try {
      // Calculate number of nights
      final nights = checkOutDate.difference(checkInDate).inDays;
      final calculatedBasePrice = basePrice ?? 199.99; // Default room price
      final totalPrice = calculatedBasePrice * nights;
      final taxAmount = totalPrice * 0.1; // 10% tax
      final finalTotal = totalPrice + taxAmount;

      final bookingData = {
        'roomId': roomId,
        'roomType': roomType ?? 'Standard',
        'roomNumber': roomNumber ?? '101',
        'checkInDate': checkInDate.toIso8601String().split('T')[0], // Date only
        'checkOutDate':
            checkOutDate.toIso8601String().split('T')[0], // Date only
        'guests': guests,
        'fullName': fullName ?? '',
        'email': email ?? '',
        'phone': phone ?? '',
        'specialRequests': specialRequests ?? '',
        'payment': paymentMethod,
        'totalPrice': finalTotal,
        'basePrice': calculatedBasePrice,
        'taxAmount': taxAmount,
        'numberOfNights': nights,
        if (paymentMethodId != null)
          'paymentIntentId':
              paymentMethodId, // Use as payment intent ID instead
      };

      print('Creating booking with data: $bookingData');

      final response = await _dio!.post('/api/bookings', data: bookingData);

      if (response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'booking': data['booking'] ?? data,
          'message': data['message'] ?? 'Booking created successfully',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Booking failed',
      };
    } on DioException catch (e) {
      print('Booking creation error: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('Unexpected booking creation error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<List<BookingModel>> getUserBookings() async {
    try {
      print('Fetching user bookings...');
      final response = await _dio!.get('/api/bookings/user');

      print('Bookings response status: ${response.statusCode}');
      print('Bookings response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> bookingsData;

        if (data is List) {
          bookingsData = data;
        } else if (data is Map && data['bookings'] != null) {
          bookingsData = data['bookings'];
        } else {
          bookingsData = [];
        }

        print('Found ${bookingsData.length} bookings');
        return bookingsData.map((item) => _mapApiToBookingModel(item)).toList();
      }

      return [];
    } on DioException catch (e) {
      print('Error fetching bookings: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Failed to load bookings');
    } catch (e) {
      print('Unexpected error fetching bookings: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  Future<List<BookingModel>> getAllBookings() async {
    try {
      final response = await _dio!.get('/api/bookings');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['bookings'];
        return data.map((item) => _mapApiToBookingModel(item)).toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load bookings');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final response = await _dio!.get('/api/bookings/$bookingId');

      if (response.statusCode == 200) {
        return _mapApiToBookingModel(response.data['booking']);
      }

      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load booking');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<Map<String, dynamic>> updateBooking(
      String bookingId, Map<String, dynamic> updates) async {
    try {
      final response =
          await _dio!.put('/api/bookings/$bookingId', data: updates);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'booking': _mapApiToBookingModel(response.data['booking']),
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

  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final response = await _dio!.delete('/api/bookings/$bookingId');

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

  Future<Map<String, dynamic>> checkRoomAvailability({
    required String roomId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) async {
    try {
      print('Checking room availability for room: $roomId');
      print('Check-in: ${checkInDate.toIso8601String().split('T')[0]}');
      print('Check-out: ${checkOutDate.toIso8601String().split('T')[0]}');

      final response =
          await _dio!.get('/api/rooms/availability', queryParameters: {
        'checkInDate': checkInDate.toIso8601String().split('T')[0], // Date only
        'checkOutDate':
            checkOutDate.toIso8601String().split('T')[0], // Date only
      });

      print('Availability response status: ${response.statusCode}');
      print('Availability response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> availabilityResults = response.data;

        // Find the specific room in the results
        final roomAvailability = availabilityResults.firstWhere(
          (result) => result['room']['_id'] == roomId,
          orElse: () => null,
        );

        if (roomAvailability != null) {
          final isAvailable = roomAvailability['isAvailable'] ?? false;
          return {
            'available': isAvailable,
            'message': isAvailable
                ? 'Room is available for the selected dates!'
                : 'This room is already booked for the selected dates. Please choose different dates.',
          };
        } else {
          return {
            'available': false,
            'message': 'Room not found',
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
        'available': false,
        'message': e.response?.data['error'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('Unexpected availability check error: $e');
      return {
        'available': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  BookingModel _mapApiToBookingModel(Map<String, dynamic> apiData) {
    try {
      print('Mapping booking data: $apiData');

      // Safe string extraction
      String safeString(dynamic value, String defaultValue) {
        if (value == null) return defaultValue;
        if (value is String) return value;
        if (value is Map) return defaultValue; // Handle nested objects
        return value.toString();
      }

      // Safe number extraction
      double safeDouble(dynamic value, double defaultValue) {
        if (value == null) return defaultValue;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          return double.tryParse(value) ?? defaultValue;
        }
        return defaultValue;
      }

      // Safe int extraction
      int safeInt(dynamic value, int defaultValue) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) {
          return int.tryParse(value) ?? defaultValue;
        }
        return defaultValue;
      }

      // Safe DateTime parsing
      DateTime safeDateTime(dynamic value, DateTime defaultValue) {
        if (value == null) return defaultValue;
        if (value is String) {
          try {
            return DateTime.parse(value).toLocal();
          } catch (e) {
            debugPrint('Error parsing date: $value, error: $e');
            return defaultValue;
          }
        }
        return defaultValue;
      }

      // Safe nullable DateTime parsing
      DateTime? safeNullableDateTime(dynamic value) {
        if (value == null) return null;
        if (value is String) {
          try {
            return DateTime.parse(value).toLocal();
          } catch (e) {
            debugPrint('Error parsing nullable date: $value, error: $e');
            return null;
          }
        }
        return null;
      }

      // Safe nullable double parsing
      double? safeNullableDouble(dynamic value) {
        if (value == null) return null;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          return double.tryParse(value);
        }
        return null;
      }

      return BookingModel(
        id: safeString(apiData['_id'] ?? apiData['id'], 'unknown'),
        userId: safeString(apiData['userId'], 'unknown'),
        roomId: safeString(apiData['roomId'], 'unknown'),
        roomNumber: _extractRoomNumber(apiData),
        roomType: safeString(
            apiData['roomType'] ?? apiData['room']?['type'], 'standard'),
        checkInDate: safeDateTime(apiData['checkInDate'], DateTime.now()),
        checkOutDate: safeDateTime(apiData['checkOutDate'],
            DateTime.now().add(const Duration(days: 1))),
        numberOfGuests:
            safeInt(apiData['guests'] ?? apiData['numberOfGuests'], 1),
        totalAmount:
            safeDouble(apiData['totalPrice'] ?? apiData['totalAmount'], 0.0),
        status: _mapBookingStatus(apiData),
        paymentMethod: safeString(
            apiData['payment'] ?? apiData['paymentMethod'], 'credit_card'),
        paymentId: apiData['paymentId'] as String?,
        isPaid: _determinePaymentStatus(apiData),
        specialRequests: apiData['specialRequests'] as String?,
        bookingDate: safeDateTime(
            apiData['createdAt'] ?? apiData['bookingDate'], DateTime.now()),
        cancellationReason: apiData['cancellationReason'] as String?,
        cancellationDate: safeNullableDateTime(apiData['cancellationDate']),
        isRefunded: apiData['isRefunded'] ?? false,
        refundAmount: safeNullableDouble(apiData['refundAmount']),
        guestName: safeString(
            apiData['fullName'] ??
                apiData['guestName'] ??
                apiData['user']?['name'],
            'Guest'),
        adults: safeInt(apiData['adults'] ?? apiData['guests'], 1),
        children: safeInt(apiData['children'], 0),
      );
    } catch (e) {
      print('Error mapping booking data: $e');
      print('API Data: $apiData');
      rethrow;
    }
  }

  // Helper method to map booking status from API response
  String _mapBookingStatus(Map<String, dynamic> apiData) {
    final status = apiData['status']?.toString().toLowerCase() ?? 'pending';
    final paymentStatus = apiData['paymentStatus']?.toString().toLowerCase();
    final isPaid = apiData['isPaid'] ?? false;

    // If payment is successful, booking should be confirmed
    if (paymentStatus == 'succeeded' || paymentStatus == 'paid' || isPaid) {
      return 'confirmed';
    }

    // Map various status values
    switch (status) {
      case 'confirmed':
      case 'active':
      case 'booked':
        return 'confirmed';
      case 'cancelled':
      case 'canceled':
        return 'cancelled';
      case 'completed':
      case 'finished':
      case 'checked-out':
        return 'completed';
      case 'checked-in':
        return 'checked-in';
      case 'pending':
      default:
        return 'pending';
    }
  }

  // Helper method to determine payment status
  bool _determinePaymentStatus(Map<String, dynamic> apiData) {
    final paymentStatus = apiData['paymentStatus']?.toString().toLowerCase();
    final isPaid = apiData['isPaid'];

    // Check explicit isPaid field first
    if (isPaid != null) {
      return isPaid == true;
    }

    // Check payment status
    if (paymentStatus != null) {
      return paymentStatus == 'succeeded' ||
          paymentStatus == 'paid' ||
          paymentStatus == 'completed';
    }

    // Default to false if no clear payment status
    return false;
  }

  // Helper method to extract room number from API response
  String _extractRoomNumber(Map<String, dynamic> apiData) {
    // Try different possible locations for room number
    if (apiData['roomNumber'] != null && apiData['roomNumber'] != '000') {
      return apiData['roomNumber'].toString();
    }

    // Check nested room object
    if (apiData['room'] != null && apiData['room']['roomNumber'] != null) {
      return apiData['room']['roomNumber'].toString();
    }

    // Check roomId object (if populated)
    if (apiData['roomId'] is Map && apiData['roomId']['roomNumber'] != null) {
      return apiData['roomId']['roomNumber'].toString();
    }

    return 'N/A';
  }

  RoomModel _mapApiToRoomModel(Map<String, dynamic> apiData) {
    return RoomModel(
      id: apiData['_id'] ?? apiData['id'],
      roomNumber: apiData['roomNumber'] ?? 'N/A',
      roomType: apiData['type'] ?? apiData['roomType'] ?? 'standard',
      pricePerNight:
          (apiData['price'] ?? apiData['pricePerNight'] ?? 0).toDouble(),
      capacity: apiData['capacity'] ?? 1,
      amenities: List<String>.from(apiData['amenities'] ?? []),
      imageUrls: apiData['images'] != null
          ? List<String>.from(apiData['images'])
          : [apiData['image'] ?? ''],
      status: apiData['status'] ?? 'available',
      description: apiData['description'],
      floor: apiData['floor'] ?? 1,
      isAvailable: apiData['isAvailable'] ?? true,
      size: apiData['size'] ?? 'Standard',
    );
  }
}
// Minor change for contribution
