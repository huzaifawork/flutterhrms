import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../data/models/order_model.dart';
import 'auth_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

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

  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required Map<String, dynamic> deliveryLocation,
    String? specialInstructions,
    String paymentMethod = 'cash',
    String? paymentMethodId,
    double? deliveryFee,
  }) async {
    try {
      // Calculate totals
      double subtotal = 0;
      for (var item in items) {
        double price = (item['price'] ?? 0).toDouble();
        int quantity = (item['quantity'] ?? 1);
        subtotal += price * quantity;
      }

      double finalDeliveryFee = deliveryFee ?? 5.0; // Default delivery fee
      double totalPrice = subtotal + finalDeliveryFee;

      // Format items to match website API structure
      final formattedItems = items
          .map((item) => {
                'itemId': item['menuItemId'] ?? item['itemId'],
                'name': item['name'],
                'price': (item['price'] ?? 0).toDouble(),
                'quantity': item['quantity'] ?? 1,
              })
          .toList();

      // Format deliveryLocation to match website GeoJSON format
      Map<String, dynamic> formattedDeliveryLocation;
      if (deliveryLocation.containsKey('type') &&
          deliveryLocation.containsKey('coordinates')) {
        // Already in correct format
        formattedDeliveryLocation = deliveryLocation;
      } else {
        // Convert from lat/lng format to GeoJSON format
        double latitude = (deliveryLocation['latitude'] ?? 34.0522).toDouble();
        double longitude =
            (deliveryLocation['longitude'] ?? -118.2437).toDouble();
        formattedDeliveryLocation = {
          'type': 'Point',
          'coordinates': [
            longitude,
            latitude
          ], // Note: GeoJSON uses [lng, lat] order
        };
      }

      final orderData = {
        'items': formattedItems,
        'subtotal': subtotal,
        'totalPrice': totalPrice,
        'deliveryFee': finalDeliveryFee,
        'deliveryAddress': deliveryAddress,
        'deliveryLocation': formattedDeliveryLocation,
        'status': 'pending',
        'deliveryStatus': 'pending',
        'paymentDetails': {
          'method': paymentMethod,
          if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
        },
      };

      print('Creating order with data: $orderData');

      final response = await _dio!.post('/api/orders', data: orderData);

      if (response.statusCode == 201) {
        final data = response.data;
        // Parse the response data into OrderModel
        final orderData = data['order'] ?? data;
        final orderModel = _mapApiToOrderModel(orderData);
        return {
          'success': true,
          'order': orderModel,
          'message': data['message'] ?? 'Order created successfully',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Order creation failed',
      };
    } on DioException catch (e) {
      print('Order creation error: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('Unexpected order creation error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<List<OrderModel>> getUserOrders() async {
    try {
      print('Fetching user orders...');
      final response = await _dio!.get('/api/orders');

      print('Orders response status: ${response.statusCode}');
      print('Orders response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> ordersData;

        if (data is List) {
          ordersData = data;
        } else if (data is Map && data['orders'] != null) {
          ordersData = data['orders'];
        } else {
          ordersData = [];
        }

        print('Found ${ordersData.length} orders');
        return ordersData.map((item) => _mapApiToOrderModel(item)).toList();
      }

      return [];
    } on DioException catch (e) {
      print('Error fetching orders: ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Failed to load orders');
    } catch (e) {
      print('Unexpected error fetching orders: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  Future<List<OrderModel>> getAllOrders() async {
    try {
      final response = await _dio!.get('/api/orders');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['orders'] ?? response.data;
        return data.map((item) => _mapApiToOrderModel(item)).toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load orders');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await _dio!.get('/api/orders/$orderId');

      if (response.statusCode == 200) {
        return _mapApiToOrderModel(response.data['order'] ?? response.data);
      }

      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load order');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      String orderId, String status) async {
    try {
      final response = await _dio!.patch('/api/orders/$orderId/status', data: {
        'status': status,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'order': _mapApiToOrderModel(response.data['order']),
          'message': response.data['message'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Status update failed',
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

  Future<Map<String, dynamic>> updateDeliveryLocation(
      String orderId, Map<String, dynamic> location) async {
    try {
      final response = await _dio!
          .put('/api/orders/$orderId/delivery-location', data: location);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'order': _mapApiToOrderModel(response.data['order']),
          'message': response.data['message'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Location update failed',
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

  OrderModel _mapApiToOrderModel(Map<String, dynamic> apiData) {
    // Map API response to match the data model structure
    print('API Data received: $apiData');
    print('CreatedAt from API: ${apiData['createdAt']}');

    // Parse the actual order creation time from backend and convert to local time
    DateTime orderTime;
    try {
      if (apiData['createdAt'] != null) {
        // Parse the UTC timestamp and convert to local time
        DateTime utcTime = DateTime.parse(apiData['createdAt']);
        orderTime = utcTime.toLocal();
        debugPrint('Backend UTC time: $utcTime');
        debugPrint('Converted to local time: $orderTime');
      } else {
        // Fallback to current time only if no createdAt is provided
        orderTime = DateTime.now();
        debugPrint('No createdAt provided, using current time: $orderTime');
      }
    } catch (e) {
      // If parsing fails, use current time as fallback
      orderTime = DateTime.now();
      debugPrint('Failed to parse createdAt, using current time: $orderTime');
      debugPrint('Parse error: $e');
    }

    return OrderModel(
      id: apiData['_id'] ?? apiData['id'] ?? '',
      userId: apiData['user'] ?? apiData['userId'] ?? '',
      items: (apiData['items'] as List? ?? [])
          .map((item) => OrderItemModel(
                menuItemId:
                    item['itemId'] ?? item['menuItemId'] ?? item['id'] ?? '',
                name: item['name'] ?? '',
                price: (item['price'] ?? 0).toDouble(),
                quantity: item['quantity'] ?? 1,
                specialInstructions: item['specialInstructions'],
              ))
          .toList(),
      status: apiData['status'] ?? 'pending',
      orderTime: orderTime,
      deliveryTime: apiData['estimatedDeliveryTime'] != null
          ? DateTime.parse(apiData['estimatedDeliveryTime']).toLocal()
          : null,
      orderType: 'delivery', // Default for mobile orders
      subtotal: (apiData['subtotal'] ?? 0).toDouble(),
      tax: (apiData['tax'] ?? 0).toDouble(),
      tip: (apiData['tip'] ?? 0).toDouble(),
      deliveryFee: (apiData['deliveryFee'] ?? 0).toDouble(),
      total: (apiData['totalPrice'] ?? 0).toDouble(),
      paymentMethod: apiData['paymentDetails']?['method'] ?? 'cash',
      paymentId: apiData['paymentIntentId'],
      isPaid: apiData['paymentStatus'] == 'succeeded' ||
          apiData['paymentStatus'] == 'paid',
      deliveryAddress: apiData['deliveryAddress'],
      notes: apiData['specialInstructions'],
    );
  }
}
// Minor change for contribution
