import 'dart:io';

class ApiConstants {
  static String get baseUrl {
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

  // Vehicles (Driver + passenger search)
  static String get vehicles => '$baseUrl/vehicles';
  static String get vehiclesNearby => '$baseUrl/vehicles/nearby';

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

  // Freight
  static String get freight => '$baseUrl/freight';

  // GPS
  static String get gpsLog => '$baseUrl/gps/log';
}
