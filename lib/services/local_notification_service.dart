import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/app_theme.dart';
import '../models/notification_model.dart';

/// Affiche les notifications AutoConnect dans la barre de notifications du téléphone.
class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Appelé quand l'utilisateur touche une notification système (payload = id de la notification).
  static void Function(String? payload)? onTap;

  static const _channel = AndroidNotificationDetails(
    'autoconnect_activity',
    'Activité AutoConnect',
    channelDescription: 'Réservations, paiements, trajets et messages de l’administration',
    importance: Importance.high,
    priority: Priority.high,
  );

  static bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> init() async {
    if (_ready || !_supported) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          // Silhouette blanche du logo : Android n'affiche que des icônes monochromes
          android: AndroidInitializationSettings('@drawable/ic_notification'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (response) => onTap?.call(response.payload),
      );
      // Android 13+ : l'autorisation doit être demandée explicitement
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Notifications système indisponibles : $e');
    }
  }

  static Future<void> show(NotificationModel notification) async {
    if (!_ready) return;
    await _plugin.show(
      id: notification.id.hashCode & 0x7fffffff,
      title: notification.titre,
      body: notification.message,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.channelId,
          _channel.channelName,
          channelDescription: _channel.channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          color: AppColors.primary,
          // Message complet visible en dépliant la notification
          styleInformation: BigTextStyleInformation(notification.message),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: notification.id,
    );
  }
}
