import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../widget/Constants.dart';

class NotificationService {
  // static const String baseUrl = 'https://ccbfsolution.pmmsapp.com/api';

  // Get unread notification count
  static Future<int> getUnreadNotificationCount() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        print('Authentication token not found');
        return 0;
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}/notification'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> notifications = data['notifications'];

        // Count unread notifications
        int unreadCount = 0;
        for (var notification in notifications) {
          final int id = notification['id'];
          final bool isRead = prefs.getBool('notification_$id') ?? false;
          if (!isRead) {
            unreadCount++;
          }
        }

        return unreadCount;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error getting notification count: $e');
      return 0;
    }
  }

  // Update notification status
  static Future<bool> updateNotificationStatus({
    required int notificationId,
    required String status,
    required String remark,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        print('Authentication token not found');
        return false;
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}update-notification-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'notification_id': notificationId,
          'status': status,
          'remark': remark,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'] == true;
      } else {
        print('Failed to update notification status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating notification status: $e');
      return false;
    }
  }

  // Check if there are new notifications
  static Future<bool> hasNewNotifications() async {
    final count = await getUnreadNotificationCount();
    return count > 0;
  }
}




/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String baseUrl = 'https://ccbfsolution.pmmsapp.com/api';

  // Get unread notification count
  static Future<int> getUnreadNotificationCount() async {
    try {
      // Get token from SharedPreferences - same as your main code
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        print('Authentication token not found');
        return 0;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/notification'),
        headers: {
          'Authorization': 'Bearer $token',  // Token added here
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> notifications = data['notifications'];

        // Get read notifications from SharedPreferences
        int unreadCount = 0;

        for (var notification in notifications) {
          final int id = notification['id'];
          final bool isRead = prefs.getBool('notification_$id') ?? false;
          if (!isRead) {
            unreadCount++;
          }
        }

        return unreadCount;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error getting notification count: $e');
      return 0;
    }
  }

  // Check if there are new notifications
  static Future<bool> hasNewNotifications() async {
    final count = await getUnreadNotificationCount();
    return count > 0;
  }
}*/
