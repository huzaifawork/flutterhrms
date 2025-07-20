import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/config/environment.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String? _activeOrderId;
  final Set<Function(Map<String, dynamic>)> _callbacks = {};
  bool _isConnected = false;

  static String get _socketServer => Environment.currentSocketUrl;

  bool get isConnected => _isConnected;
  String? get activeOrderId => _activeOrderId;

  IO.Socket? initializeSocket(String orderId) {
    if (orderId.isEmpty) {
      print('[Socket] No order ID provided');
      return null;
    }

    // If already tracking this order with an active socket, return it
    if (_socket != null && _socket!.connected && _activeOrderId == orderId) {
      print('[Socket] Already tracking order: $orderId');
      return _socket;
    }

    // Clean up any existing socket
    if (_socket != null) {
      print('[Socket] Cleaning up existing socket');
      _cleanupSocket();
    }

    // Store order ID and create new socket
    _activeOrderId = orderId;
    print('[Socket] Creating new connection for order: $orderId');
    print('[Socket] Connecting to server: $_socketServer');

    _socket = IO.io(_socketServer, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': false,
      'timeout': 10000,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    // Set up event handlers
    _socket!.on('connect', (_) {
      print('[Socket] ✅ Connected to server successfully');
      _isConnected = true;

      // Start tracking once connected
      _socket!.emit('trackOrder', {'orderId': orderId});
      print('[Socket] 📡 Tracking request sent for order: $orderId');
    });

    _socket!.on('disconnect', (reason) {
      print('[Socket] ❌ Disconnected from server. Reason: $reason');
      _isConnected = false;
    });

    _socket!.on('connect_error', (error) {
      print('[Socket] 🚨 Connection error: $error');
      _isConnected = false;
    });

    _socket!.on('error', (error) {
      print('[Socket] ⚠️ Socket error: $error');
      _isConnected = false;
    });

    _socket!.on('reconnect', (attemptNumber) {
      print('[Socket] 🔄 Reconnected after $attemptNumber attempts');
      _isConnected = true;
    });

    _socket!.on('reconnect_error', (error) {
      print('[Socket] 🔄❌ Reconnection error: $error');
    });

    // Handle order updates
    _socket!.on('orderUpdate', (data) {
      print('[Socket] Received update: $data');

      // Only process updates for the order we're tracking
      if (data['orderId'] == _activeOrderId) {
        final updateData = Map<String, dynamic>.from(data);
        _callbacks.forEach((callback) {
          try {
            callback(updateData);
          } catch (error) {
            print('[Socket] Error in callback: $error');
          }
        });
      }
    });

    // Handle global order status updates (for 5-minute auto-progression)
    _socket!.on('orderStatusUpdate', (data) {
      print('[Socket] Received global order status update: $data');

      // Process all global updates regardless of active order
      final updateData = Map<String, dynamic>.from(data);
      _callbacks.forEach((callback) {
        try {
          callback(updateData);
        } catch (error) {
          print('[Socket] Error in global callback: $error');
        }
      });
    });

    // Connect the socket
    _socket!.connect();

    return _socket;
  }

  void _cleanupSocket() {
    if (_socket != null) {
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket = null;
    }
    _isConnected = false;
  }

  void disconnectSocket() {
    print('[Socket] Disconnecting socket');
    _cleanupSocket();
    _callbacks.clear();
    _activeOrderId = null;
  }

  Function subscribeToOrderUpdates(Function(Map<String, dynamic>) callback) {
    _callbacks.add(callback);

    // Return unsubscribe function
    return () {
      _callbacks.remove(callback);
    };
  }

  void emitOrderStatusUpdate(String orderId, String status) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('orderStatusUpdate', {
        'orderId': orderId,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      });
      print('[Socket] Emitted status update: $status for order: $orderId');
    }
  }

  // Utility methods for formatting (matching website)
  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }

  String formatEstimatedDelivery(DateTime estimatedTime) {
    final now = DateTime.now();
    final difference = estimatedTime.difference(now);

    if (difference.isNegative) {
      return 'Delivered';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    }
  }

  // Test connection to server
  Future<bool> testConnection() async {
    try {
      print('[Socket] 🧪 Testing connection to $_socketServer');

      final testSocket = IO.io(_socketServer, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': false,
        'timeout': 5000,
      });

      bool connected = false;

      testSocket.on('connect', (_) {
        print('[Socket] ✅ Test connection successful');
        connected = true;
        testSocket.disconnect();
      });

      testSocket.on('connect_error', (error) {
        print('[Socket] ❌ Test connection failed: $error');
        connected = false;
      });

      testSocket.connect();

      // Wait for connection result
      await Future.delayed(const Duration(seconds: 6));

      if (!connected) {
        testSocket.disconnect();
      }

      return connected;
    } catch (e) {
      print('[Socket] 🚨 Test connection exception: $e');
      return false;
    }
  }

  // Simulate order progression for testing (like website)
  void simulateOrderProgression(String orderId) {
    if (_socket == null || !_socket!.connected) {
      print('[Socket] ❌ Cannot simulate - socket not connected');
      print('[Socket] 🔍 Socket state: ${_socket?.connected ?? 'null'}');
      return;
    }

    print('[Socket] 🎬 Starting order simulation for: $orderId');

    final statuses = [
      'Order Received',
      'Preparing',
      'Ready for Pickup',
      'On the Way',
      'Arriving Soon',
      'Delivered'
    ];

    int currentIndex = 0;
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (currentIndex >= statuses.length) {
        timer.cancel();
        return;
      }

      final status = statuses[currentIndex];
      print('[Socket] 📤 Simulating status: $status');
      emitOrderStatusUpdate(orderId, status);
      currentIndex++;

      // Stop after delivered
      if (status == 'Delivered') {
        timer.cancel();
        print('[Socket] 🏁 Simulation completed');
      }
    });
  }
}
