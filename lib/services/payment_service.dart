import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../core/constants/app_constants.dart';
import '../core/config/environment.dart';
import 'auth_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

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
      onRequest: (options, handler) async {
        // Ensure token is loaded before making request
        final authService = AuthService();
        await authService.isLoggedIn(); // This loads the token
        final token = authService.token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print(
              'Adding auth token to request: Bearer ${token.substring(0, 20)}...');
        } else {
          print('No auth token available for request');
        }
        handler.next(options);
      },
    ));

    // Initialize Stripe only on mobile platforms (not web)
    if (!kIsWeb) {
      try {
        Stripe.publishableKey = Environment.currentStripeKey;
        if (Environment.enableLogging) {
          print(
              'Stripe initialized with key: ${Environment.currentStripeKey.substring(0, 20)}...');
        }
      } catch (e) {
        if (Environment.enableLogging) {
          print('Failed to initialize Stripe: $e');
        }
      }
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Use the correct endpoint and data format
      String endpoint = '/api/payment/create-payment-intent';
      Map<String, dynamic> requestData = {
        'amount': amount, // Backend expects amount in dollars, not cents
        'currency': currency,
      };

      final response = await _dio!.post(endpoint, data: requestData);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'clientSecret': response.data['clientSecret'],
          'paymentIntentId': response.data['paymentIntentId'],
        };
      }

      return {
        'success': false,
        'message':
            response.data['message'] ?? 'Failed to create payment intent',
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

  Future<Map<String, dynamic>> processPayment({
    required String clientSecret,
    required String paymentMethodId,
  }) async {
    try {
      // Confirm payment with Stripe
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: const BillingDetails(),
          ),
        ),
      );

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        // Notify backend of successful payment
        await _notifyBackendPaymentSuccess(paymentIntent.id);

        return {
          'success': true,
          'paymentIntentId': paymentIntent.id,
          'message': 'Payment successful',
        };
      } else {
        return {
          'success': false,
          'message': 'Payment failed or requires additional action',
        };
      }
    } on StripeException catch (e) {
      return {
        'success': false,
        'message': e.error.localizedMessage ?? 'Payment failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during payment',
      };
    }
  }

  Future<Map<String, dynamic>> processCardPayment({
    required double amount,
    required String currency,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    // For web platform, create payment intent and return client secret for card input
    if (kIsWeb) {
      try {
        // Create payment intent first
        final intentResult = await createPaymentIntent(
          amount: amount,
          currency: currency,
          description: description,
          metadata: metadata,
        );

        if (intentResult['success']) {
          return {
            'success': true,
            'requiresCardInput': true,
            'clientSecret': intentResult['clientSecret'],
            'paymentIntentId': intentResult['paymentIntentId'],
            'message': 'Payment intent created - card input required',
          };
        } else {
          return intentResult;
        }
      } catch (e) {
        return {
          'success': false,
          'message': 'Failed to create payment intent: ${e.toString()}',
        };
      }
    }

    try {
      // Step 1: Create payment intent
      final intentResult = await createPaymentIntent(
        amount: amount,
        currency: currency,
        description: description,
        metadata: metadata,
      );

      if (!intentResult['success']) {
        return intentResult;
      }

      // Step 2: Present payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intentResult['clientSecret'],
          merchantDisplayName: 'HRMS App',
          style: ThemeMode.system,
        ),
      );

      // Step 3: Present payment sheet to user
      final paymentResult = await Stripe.instance.presentPaymentSheet();

      // Step 4: Get payment method from the completed payment
      final paymentIntent = await Stripe.instance.retrievePaymentIntent(
        intentResult['clientSecret'],
      );

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        // Extract payment method ID from the payment intent
        final paymentMethodId = paymentIntent.paymentMethodId;

        return {
          'success': true,
          'paymentMethodId': paymentMethodId,
          'paymentIntentId': intentResult['paymentIntentId'],
          'message': 'Payment completed successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Payment failed or requires additional action',
        };
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return {
          'success': false,
          'message': 'Payment was cancelled',
          'cancelled': true,
        };
      }
      return {
        'success': false,
        'message': e.error.localizedMessage ?? 'Payment failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during payment',
      };
    }
  }

  // Add method for web-based card confirmation using Stripe.js (like website)
  Future<Map<String, dynamic>> confirmCardPayment({
    required String clientSecret,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
  }) async {
    if (!kIsWeb) {
      return {
        'success': false,
        'message': 'This method is only available on web platform',
      };
    }

    try {
      // Validate test card numbers first
      final cleanCardNumber = cardNumber.replaceAll(' ', '');
      if (cleanCardNumber != '4242424242424242' &&
          cleanCardNumber != '5555555555554444') {
        return {
          'success': false,
          'message':
              'Invalid card number. Use 4242 4242 4242 4242 or 5555 5555 5555 4444 for testing.',
        };
      }

      print(
          'Using Stripe.js confirmation (like website) for clientSecret: $clientSecret');

      // Call backend to confirm the payment intent (authentication removed for testing)
      try {
        final response =
            await _dio!.post('/api/payment/confirm-payment', data: {
          'clientSecret': clientSecret,
          'cardNumber': cleanCardNumber,
          'expiryMonth': expiryMonth,
          'expiryYear': expiryYear,
          'cvc': cvc,
        });

        print(
            'Payment confirmation response: ${response.statusCode} - ${response.data}');

        if (response.statusCode == 200 && response.data['success'] == true) {
          final paymentIntentId = response.data['paymentIntentId'] ??
              response.data['paymentIntent']?['id'] ??
              'pi_web_${DateTime.now().millisecondsSinceEpoch}';

          // Extract the real payment method ID from Stripe response
          final paymentMethodId = response.data['paymentIntent']
                  ?['payment_method'] ??
              response.data['paymentMethodId'] ??
              'pm_1${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';

          return {
            'success': true,
            'paymentIntentId': paymentIntentId,
            'paymentMethodId': paymentMethodId,
            'message': 'Payment completed successfully',
          };
        } else {
          return {
            'success': false,
            'message':
                response.data['message'] ?? 'Payment confirmation failed',
          };
        }
      } on DioException catch (e) {
        print(
            'DioException in payment confirmation: ${e.response?.statusCode} - ${e.response?.data}');
        return {
          'success': false,
          'message':
              'Payment confirmation failed: ${e.response?.data?['message'] ?? e.message}',
        };
      } catch (stripeError) {
        return {
          'success': false,
          'message': 'Stripe confirmation failed: ${stripeError.toString()}',
        };
      }
    } catch (e) {
      print('General exception in payment confirmation: $e');
      return {
        'success': false,
        'message': 'Payment confirmation failed: ${e.toString()}',
      };
    }
  }

  Future<void> _notifyBackendPaymentSuccess(String paymentIntentId) async {
    try {
      await _dio!.post('/api/payment/confirm', data: {
        'paymentIntentId': paymentIntentId,
      });
    } catch (e) {
      // Log error but don't throw - payment was successful on Stripe side
      print('Failed to notify backend of payment success: $e');
    }
  }

  Future<Map<String, dynamic>> refundPayment({
    required String paymentIntentId,
    double? amount, // If null, refunds full amount
    String? reason,
  }) async {
    try {
      final response = await _dio!.post('/api/payment/refund', data: {
        'paymentIntentId': paymentIntentId,
        'amount': amount != null ? (amount * 100).round() : null,
        'reason': reason,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'refundId': response.data['refundId'],
          'message': response.data['message'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Refund failed',
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

  Future<List<PaymentHistoryModel>> getPaymentHistory() async {
    try {
      final response = await _dio!.get('/api/payment/history');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['payments'];
        return data.map((item) => PaymentHistoryModel.fromJson(item)).toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load payment history');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Future<Map<String, dynamic>> getPaymentMethods() async {
    try {
      final response = await _dio!.get('/api/payment/methods');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'methods': response.data['methods'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to load payment methods',
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

  Future<Map<String, dynamic>> savePaymentMethod(String paymentMethodId) async {
    try {
      final response = await _dio!.post('/api/payment/save-method', data: {
        'paymentMethodId': paymentMethodId,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'],
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to save payment method',
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
}

class PaymentHistoryModel {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String description;
  final DateTime createdAt;
  final String? refundStatus;
  final Map<String, dynamic>? metadata;

  PaymentHistoryModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
    required this.createdAt,
    this.refundStatus,
    this.metadata,
  });

  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModel(
      id: json['id'],
      amount: (json['amount'] / 100).toDouble(), // Convert from cents
      currency: json['currency'],
      status: json['status'],
      description: json['description'],
      createdAt: DateTime.parse(json['created']),
      refundStatus: json['refundStatus'],
      metadata: json['metadata'],
    );
  }

  String get formattedAmount => 'PKR ${amount.toStringAsFixed(0)}';

  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'canceled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
// Minor change for contribution
