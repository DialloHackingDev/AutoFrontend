import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/local_notification_service.dart';
import '../services/realtime_service.dart';
import '../core/constants.dart';

/// Notifications de l'utilisateur connecté.
///
/// - Chargées depuis l'API au démarrage et à chaque retour dans l'application.
/// - Reçues en temps réel (WebSocket) tant que l'application est ouverte,
///   puis affichées dans la barre de notifications du téléphone.
class NotificationProvider with ChangeNotifier, WidgetsBindingObserver {
  final ApiService _apiService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _started = false;
  RealtimeService? _realtime;
  StreamSubscription<NotificationModel>? _subscription;
  final _incoming = StreamController<NotificationModel>.broadcast();

  NotificationProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Nouvelles notifications reçues en direct (pour rafraîchir les écrans concernés).
  Stream<NotificationModel> get incoming => _incoming.stream;

  /// À appeler après la connexion de l'utilisateur.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    await LocalNotificationService.init();
    await fetchNotifications();

    _realtime = RealtimeService(apiService: _apiService);
    await _realtime!.connect();
    _subscription = _realtime!.notifications.listen(_onIncoming);
  }

  /// À appeler à la déconnexion : coupe le temps réel et vide la liste.
  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _subscription = null;
    _realtime?.dispose();
    _realtime = null;
    _notifications = [];
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Récupère ce qui est arrivé pendant que l'application était en arrière-plan
    if (state == AppLifecycleState.resumed && _started) {
      fetchNotifications();
    }
  }

  void _onIncoming(NotificationModel notification) {
    if (_notifications.any((n) => n.id == notification.id)) return;
    _notifications = [notification, ..._notifications];
    notifyListeners();
    LocalNotificationService.show(notification);
    _incoming.add(notification);
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get(ApiConstants.notifications);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Fetch notifications error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;

    // Mise à jour immédiate de l'écran, confirmée ensuite par l'API
    _notifications = [..._notifications]..[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
    try {
      await _apiService.patch(ApiConstants.notificationRead(id), {});
    } catch (e) {
      debugPrint('Mark notification read error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    try {
      await _apiService.patch(ApiConstants.notificationsReadAll, {});
    } catch (e) {
      debugPrint('Mark all notifications read error: $e');
    }
  }

  @override
  void dispose() {
    stop();
    _incoming.close();
    super.dispose();
  }
}
