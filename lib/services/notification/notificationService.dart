import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/apiUrls.dart';

class NotificationService {
  static String get baseUrl => ApiUrls.baseUrl;

  // Get auth token from SharedPreferences
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get current user ID from SharedPreferences
  static Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = prefs.getString('currentUser');
    if (currentUser != null) {
      final userData = jsonDecode(currentUser);
      return userData['_id'];
    }
    return null;
  }

  // Get user notifications
  static Future<Map<String, dynamic>> getUserNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final token = await _getAuthToken();
      final userId = await _getCurrentUserId();

      if (token == null || userId == null) {
        return {
          'statusCode': 401,
          'message': 'Authentication required',
        };
      }

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'unreadOnly': unreadOnly.toString(),
      };

      final uri = Uri.parse(ApiUrls.getUserNotifications)
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      return {
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'No message',
        'data': responseData['data'],
        'pagination': responseData['pagination'],
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'message': 'Error getting notifications: $e',
      };
    }
  }

  // Mark notification as read
  static Future<Map<String, dynamic>> markNotificationAsRead(
      String notificationId) async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        return {
          'statusCode': 401,
          'message': 'Authentication required',
        };
      }

      final response = await http.put(
        Uri.parse('${ApiUrls.markNotificationAsRead}$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'No message',
        'data': responseData['data'],
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'message': 'Error marking notification as read: $e',
      };
    }
  }

  // Mark notification as unread
  static Future<Map<String, dynamic>> markNotificationAsUnread(
      String notificationId) async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        return {
          'statusCode': 401,
          'message': 'Authentication required',
        };
      }

      final response = await http.put(
        Uri.parse('${ApiUrls.markNotificationAsUnread}$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'No message',
        'data': responseData['data'],
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'message': 'Error marking notification as unread: $e',
      };
    }
  }

  // Mark all notifications as read
  static Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final token = await _getAuthToken();
      final userId = await _getCurrentUserId();

      if (token == null || userId == null) {
        return {
          'statusCode': 401,
          'message': 'Authentication required',
        };
      }

      final response = await http.put(
        Uri.parse(ApiUrls.markAllNotificationsAsRead),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'No message',
        'data': responseData['data'],
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'message': 'Error marking all notifications as read: $e',
      };
    }
  }

  // Delete notification
  static Future<Map<String, dynamic>> deleteNotification(
      String notificationId) async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        return {
          'statusCode': 401,
          'message': 'Authentication required',
        };
      }

      final response = await http.delete(
        Uri.parse('${ApiUrls.deleteNotification}$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'No message',
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'message': 'Error deleting notification: $e',
      };
    }
  }

  // Get unread count
  static Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final token = await _getAuthToken();
      final userId = await _getCurrentUserId();

      if (token == null || userId == null) {
        return {
          'statusCode': 401,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse(ApiUrls.getUnreadCount),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'No message',
        'data': responseData['data'],
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'message': 'Error getting unread count: $e',
      };
    }
  }

  // Create meeting reminder notifications
  static Future<Map<String, dynamic>> createMeetingReminders() async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        return {
          'statusCode': 401,
          'message': 'Authentication required',
        };
      }

      final response = await http.post(
        Uri.parse(ApiUrls.createMeetingReminders),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'No message',
        'data': responseData['data'],
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'message': 'Error creating meeting reminders: $e',
      };
    }
  }

  // Create notification (admin only)
  static Future<Map<String, dynamic>> createNotification({
    required dynamic recipientIds, // Can be String or List<String>
    required String type,
    required String title,
    required String message,
    String? relatedId,
    String? relatedModel,
    Map<String, dynamic>? data,
    String priority = 'medium',
  }) async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        return {
          'statusCode': 401,
          'message': 'Authentication required',
        };
      }

      final Map<String, dynamic> requestBody = {
        'recipientIds': recipientIds,
        'type': type,
        'title': title,
        'message': message,
        'priority': priority,
      };

      if (relatedId != null) {
        requestBody['relatedId'] = relatedId;
      }

      if (relatedModel != null) {
        requestBody['relatedModel'] = relatedModel;
      }

      if (data != null) {
        requestBody['data'] = data;
      }

      final response = await http.post(
        Uri.parse(ApiUrls.createNotification),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'No message',
        'data': responseData['data'],
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'message': 'Error creating notification: $e',
      };
    }
  }

  // Get meeting details for notification
  static Future<Map<String, dynamic>> getMeetingDetailsForNotification(String meetingId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'statusCode': 401,
          'message': 'Authentication required',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiUrls.getMeetingById}$meetingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'message': responseData['message'] ?? 'No message',
        'data': responseData['data'],
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'message': 'Error getting meeting details: $e',
      };
    }
  }
}
