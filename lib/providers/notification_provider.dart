import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get(ApiConstants.notifications);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Fetch notifications error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
}
