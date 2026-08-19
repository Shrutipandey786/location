import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  StompClient? _stompClient;
  bool _isConnected = false;
  final Map<String, List<Function(Map<String, dynamic>)>> _listeners = {};

  bool get isConnected => _isConnected;

  void connect(String userId) {
    if (_stompClient != null && _stompClient!.connected) return;

    String wsUrl = 'ws://172.16.2.18:8080/ws/websocket';
    if (kIsWeb) {
      wsUrl = 'ws://localhost:8080/ws/websocket';
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        reconnectDelay: const Duration(seconds: 15),
        onConnect: (StompFrame frame) {
          _isConnected = true;
          debugPrint("WebSocket STOMP connected");

          _stompClient!.subscribe(
            destination: '/topic/messages/$userId',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                try {
                  final data = jsonDecode(frame.body!) as Map<String, dynamic>;
                  _notifyListeners(userId, data);
                } catch (e) {
                  debugPrint("Error parsing WS message: $e");
                }
              }
            },
          );
        },
        onWebSocketError: (dynamic error) {
          _isConnected = false;
        },
        onDisconnect: (StompFrame frame) {
          _isConnected = false;
          debugPrint("WebSocket Disconnected");
        },
      ),
    );

    _stompClient!.activate();
  }

  void addMessageListener(String userId, Function(Map<String, dynamic>) callback) {
    if (!_listeners.containsKey(userId)) {
      _listeners[userId] = [];
    }
    _listeners[userId]!.add(callback);
  }

  void removeMessageListener(String userId, Function(Map<String, dynamic>) callback) {
    if (_listeners.containsKey(userId)) {
      _listeners[userId]!.remove(callback);
    }
  }

  void _notifyListeners(String userId, Map<String, dynamic> data) {
    if (_listeners.containsKey(userId)) {
      for (final listener in List.from(_listeners[userId]!)) {
        listener(data);
      }
    }
  }

  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    _isConnected = false;
  }
}