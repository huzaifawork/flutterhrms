import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/config/environment.dart';

class GlobalSocketService {
  static final GlobalSocketService _instance = GlobalSocketService._internal();
  factory GlobalSocketService() => _instance;
  GlobalSocketService._internal();

  IO.Socket? _socket;
  final Set<Function(Map<String, dynamic>)> _globalCallbacks = {};
  bool _isConnected = false;

  static String get _socketServer => Environment.currentSocketUrl;

  bool get isConnected => _isConnected;

  void initialize() {
    if (_socket != null && _socket!.connected) {
      return; // Already connected
    }

    _socket = IO.io(_socketServer, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': false,
    });

    _socket!.on('connect', (_) {
      debugPrint('[GlobalSocket] Connected to server');
      _isConnected = true;
    });

    _socket!.on('disconnect', (_) {
      debugPrint('[GlobalSocket] Disconnected from server');
      _isConnected = false;
    });

    _socket!.on('error', (error) {
      debugPrint('[GlobalSocket] Error: $error');
      _isConnected = false;
    });

    // Listen for global order status updates (5-minute auto-progression)
    _socket!.on('orderStatusUpdate', (data) {
      debugPrint('[GlobalSocket] Received global order status update: $data');

      // Notify all global callbacks
      final updateData = Map<String, dynamic>.from(data);
      for (final callback in _globalCallbacks) {
        try {
          callback(updateData);
        } catch (error) {
          debugPrint('[GlobalSocket] Error in global callback: $error');
        }
      }
    });

    // Connect the socket
    _socket!.connect();
  }

  Function subscribeToGlobalUpdates(Function(Map<String, dynamic>) callback) {
    _globalCallbacks.add(callback);

    // Initialize socket if not already done
    if (_socket == null) {
      initialize();
    }

    // Return unsubscribe function
    return () {
      _globalCallbacks.remove(callback);
    };
  }

  void dispose() {
    if (_socket != null) {
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket = null;
    }
    _globalCallbacks.clear();
    _isConnected = false;
  }
}
// Minor change for contribution
