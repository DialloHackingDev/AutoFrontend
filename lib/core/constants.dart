import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  /// URL forcée au lancement, ex. pour un téléphone réel branché en USB :
  /// adb reverse tcp:3000 tcp:3000
  /// flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  // Auth
  static String get authRegister => '$baseUrl/auth/register';
  static String get authLogin => '$baseUrl/auth/login';
  static String get authLogout => '$baseUrl/auth/logout';
  static String get authMe => '$baseUrl/users/profile';

  // Bookings
  static String get bookings => '$baseUrl/bookings';
  static String bookingDetail(String id) => '$bookings/$id';
  static String bookingStatus(String id) => '$bookings/$id/status';
  static String startBooking(String id) => '$bookings/$id/start';
  static String boardBooking(String id) => '$bookings/$id/board';

  // Vehicles & Drivers
  static String get vehicles => '$baseUrl/vehicles';
  static String get vehiclesNearby => '$baseUrl/vehicles/nearby';
  static String get myVehicles => '$baseUrl/vehicles/mine';
  static String get driverAvailability => '$baseUrl/drivers/availability';

  // Stations
  static String get stations => '$baseUrl/stations';

  // Payments & Wallet
  static String get payments => '$baseUrl/payments';
  static String paymentDetail(String id) => '$payments/$id';
  static String get wallet => '$baseUrl/wallet/balance';
  static String get walletHistory => '$baseUrl/wallet/history';
  static String get withdrawals => '$baseUrl/withdrawals';

  // Notifications
  static String get notifications => '$baseUrl/notifications';

  // Litiges (Disputes)
  static String get disputes => '$baseUrl/disputes';
  static String disputeDetail(String id) => '$disputes/$id';

  // Freight
  static String get freight => '$baseUrl/freight';

  // GPS
  static String get gpsLog => '$baseUrl/gps/log';
}
