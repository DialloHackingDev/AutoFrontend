import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

/// Position reçue en temps réel (passager ou chauffeur).
class LivePosition {
  final double latitude;
  final double longitude;
  final DateTime receivedAt;

  LivePosition(this.latitude, this.longitude) : receivedAt = DateTime.now();
}

/// Connexion WebSocket (Socket.IO) authentifiée au backend.
///
/// - Le passager publie sa position pour que le chauffeur vienne le chercher.
/// - Le chauffeur publie la sienne pour que le passager le voie arriver.
/// Les abonnements sont rejoués à chaque reconnexion (réseau instable).
class RealtimeService {
  final ApiService _apiService;
  io.Socket? _socket;
  final Set<String> _bookingRooms = {};
  final Set<String> _driverRooms = {};
  bool _disposed = false;
  Duration _retryDelay = const Duration(seconds: 5);

  final _passengerPositions = StreamController<LivePosition>.broadcast();
  final _driverPositions = StreamController<LivePosition>.broadcast();
  final _notifications = StreamController<NotificationModel>.broadcast();

  RealtimeService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  /// Position du passager (côté chauffeur)
  Stream<LivePosition> get passengerPositions => _passengerPositions.stream;

  /// Position du chauffeur (côté passager)
  Stream<LivePosition> get driverPositions => _driverPositions.stream;

  /// Notifications poussées par le backend sur le canal privé de l'utilisateur
  Stream<NotificationModel> get notifications => _notifications.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// L'URL WebSocket est celle de l'API, sans le préfixe /api/v1.
  static String get _socketUrl => ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '');

  /// Jeton d'accès valide : un appel API déclenche son rafraîchissement s'il a expiré.
  Future<String?> _freshToken() async {
    try {
      await _apiService.get(ApiConstants.authMe);
    } catch (_) {}
    return _apiService.getToken();
  }

  Future<void> connect() async {
    if (_socket != null) return;
    if (await _freshToken() == null) return;

    final socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    // Le jeton expire au bout de 15 min : il est relu à CHAQUE connexion et reconnexion,
    // sinon une reconnexion (réseau coupé, serveur redémarré) serait refusée définitivement.
    socket.auth = (dynamic send) {
      _freshToken().then((token) => send({'token': token ?? ''}));
    };

    socket.onDisconnect((reason) {
      // Coupure décidée par le serveur (jeton refusé, redémarrage) : socket.io ne retente pas
      // de lui-même, on relance donc la connexion avec un délai croissant.
      if (_disposed || reason != 'io server disconnect') return;
      final delay = _retryDelay;
      _retryDelay = Duration(seconds: (_retryDelay.inSeconds * 2).clamp(5, 60));
      Future.delayed(delay, () {
        if (!_disposed && !(_socket?.connected ?? false)) socket.connect();
      });
    });

    socket.onConnect((_) {
      _retryDelay = const Duration(seconds: 5);
      for (final bookingId in _bookingRooms) {
        socket.emit('subscribe_booking', bookingId);
      }
      for (final driverId in _driverRooms) {
        socket.emit('subscribe_driver', driverId);
      }
    });
    socket.on('passenger_location_update', (data) {
      final position = _parse(data);
      if (position != null) _passengerPositions.add(position);
    });
    socket.on('driver_location_update', (data) {
      final position = _parse(data);
      if (position != null) _driverPositions.add(position);
    });
    socket.on('notification', (data) {
      if (data is Map) {
        _notifications.add(NotificationModel.fromJson(Map<String, dynamic>.from(data)));
      }
    });
    socket.on('exception', (error) => debugPrint('Temps réel : $error'));

    _socket = socket..connect();
  }

  void followBooking(String bookingId) {
    if (_bookingRooms.add(bookingId) && isConnected) {
      _socket!.emit('subscribe_booking', bookingId);
    }
  }

  void followDriver(String driverId) {
    if (_driverRooms.add(driverId) && isConnected) {
      _socket!.emit('subscribe_driver', driverId);
    }
  }

  void sendPassengerLocation(String bookingId, double latitude, double longitude) {
    _socket?.emit('passenger_location', {
      'bookingId': bookingId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  void sendDriverLocation(double latitude, double longitude) {
    _socket?.emit('driver_location', {'latitude': latitude, 'longitude': longitude});
  }

  LivePosition? _parse(dynamic data) {
    if (data is! Map) return null;
    final lat = data['latitude'];
    final lng = data['longitude'];
    if (lat is! num || lng is! num) return null;
    return LivePosition(lat.toDouble(), lng.toDouble());
  }

  void dispose() {
    _disposed = true;
    _socket?.dispose();
    _socket = null;
    _bookingRooms.clear();
    _driverRooms.clear();
    _passengerPositions.close();
    _driverPositions.close();
    _notifications.close();
  }
}
