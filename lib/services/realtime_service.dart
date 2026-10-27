import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/constants.dart';
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

  final _passengerPositions = StreamController<LivePosition>.broadcast();
  final _driverPositions = StreamController<LivePosition>.broadcast();

  RealtimeService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  /// Position du passager (côté chauffeur)
  Stream<LivePosition> get passengerPositions => _passengerPositions.stream;

  /// Position du chauffeur (côté passager)
  Stream<LivePosition> get driverPositions => _driverPositions.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// L'URL WebSocket est celle de l'API, sans le préfixe /api/v1.
  static String get _socketUrl => ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '');

  Future<void> connect() async {
    if (_socket != null) return;

    // Un appel API déclenche le rafraîchissement du token s'il a expiré
    try {
      await _apiService.get(ApiConstants.authMe);
    } catch (_) {}
    final token = await _apiService.getToken();
    if (token == null) return;

    final socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    socket.onConnect((_) {
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
    _socket?.dispose();
    _socket = null;
    _bookingRooms.clear();
    _driverRooms.clear();
    _passengerPositions.close();
    _driverPositions.close();
  }
}
