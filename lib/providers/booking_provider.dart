import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

class BookingProvider with ChangeNotifier {
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService;

  BookingProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get(ApiConstants.bookings);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _bookings = data.map((json) => Booking.fromJson(json)).toList();
      } else {
        _errorMessage = _parseError(response.body);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Impossible de charger les réservations.';
      debugPrint('Fetch bookings error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createBooking({
    required String vehicleId,
    required String departure,
    required String destination,
    required int places,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.bookings, {
        'vehicleId': vehicleId,
        'departure': departure,
        'destination': destination,
        'places': places,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchBookings();
        return true;
      }

      _errorMessage = _parseError(response.body);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Impossible de créer la réservation.';
      debugPrint('Create booking error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateBookingStatus(String bookingId, String statut, {String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.patch(ApiConstants.bookingStatus(bookingId), {
        'statut': statut,
        if (reason != null && reason.isNotEmpty) 'cancelReason': reason,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchBookings();
        return true;
      }

      _errorMessage = _parseError(response.body);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Impossible de mettre à jour la réservation.';
      debugPrint('Update booking status error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> confirmBooking(String bookingId) async {
    return updateBookingStatus(bookingId, BookingStatus.CONFIRMED.name);
  }

  /// Le passager confirme sa présence au départ avec sa propre position GPS.
  /// Le chauffeur pourra ensuite démarrer le trajet en scannant son QR Code.
  Future<bool> confirmBoarding({
    required String bookingId,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.boardBooking(bookingId), {
        'latitude': latitude,
        'longitude': longitude,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchBookings();
        return true;
      }

      _errorMessage = _parseError(response.body);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Impossible de confirmer l’embarquement.';
      debugPrint('Confirm boarding error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> startTrip({
    required String bookingId,
    required double driverLatitude,
    required double driverLongitude,
    String? otp,
    String? qrData,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // La réservation doit déjà être PAID (confirmée par le callback opérateur) :
      // le backend refuse le démarrage sinon.
      final response = await _apiService.post(ApiConstants.startBooking(bookingId), {
        'driverLatitude': driverLatitude,
        'driverLongitude': driverLongitude,
        if (otp != null && otp.isNotEmpty) 'otp': otp,
        if (qrData != null && qrData.isNotEmpty) 'qrData': qrData,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchBookings();
        return true;
      }

      _errorMessage = _parseError(response.body);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Impossible de démarrer le trajet.';
      debugPrint('Start trip error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>?> initiatePayment({
    required String bookingId,
    required double montant,
    required String methode,
    String? telephone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.payments, {
        'bookingId': bookingId,
        'montant': montant,
        'methode': methode,
        if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchBookings();
        final payload = jsonDecode(response.body);
        return payload is Map<String, dynamic> ? payload : {'message': response.body};
      }

      _errorMessage = _parseError(response.body);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Impossible d’initier le paiement.';
      debugPrint('Initiate payment error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  /// Termine le trajet : le backend libère alors les fonds du séquestre vers le wallet chauffeur.
  Future<bool> completeTrip(String bookingId) async {
    return updateBookingStatus(bookingId, BookingStatus.COMPLETED.name);
  }

  /// Statut d'un paiement, revérifié par le serveur auprès de l'opérateur.
  Future<String?> checkPayment(String paymentId) async {
    try {
      final response = await _apiService.get(ApiConstants.paymentDetail(paymentId));
      final status = (jsonDecode(response.body) as Map<String, dynamic>)['statut']?.toString();
      if (status == 'COMPLETED' || status == 'FAILED' || status == 'REFUNDED') {
        await fetchBookings();
      }
      return status;
    } catch (e) {
      debugPrint('Check payment error: $e');
      return null;
    }
  }

  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    return updateBookingStatus(bookingId, BookingStatus.CANCELLED.name, reason: reason);
  }

  String _parseError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ?? 'La réservation n’a pas pu être enregistrée.';
      }
    } catch (_) {}
    return body.isNotEmpty ? body : 'La réservation n’a pas pu être enregistrée.';
  }
}
