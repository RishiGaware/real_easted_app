import 'package:flutter/material.dart';
import '../../models/notification/NotificationModel.dart';
import '../../services/notification/notificationService.dart';
import '../../services/notification/local_notification_service.dart';
import 'dart:async';

class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;

  Timer? _pollingTimer;
  final Set<String> _alertedNotificationIds = {};

  // Constructor to initialize data
  NotificationController() {
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await LocalNotificationService.initialize();
      getNotifications();
      getUnreadCount();
      _startBackgroundPolling();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMorePages => _hasMorePages;

  // Today's notifications count
  int get todayNotificationsCount {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final count = _notifications.where((notification) {
      final createdAt = notification.createdAt;
      return createdAt.isAfter(startOfDay) && createdAt.isBefore(endOfDay);
    }).length;

    return count;
  }

  // Get all notifications
  Future<void> getNotifications({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      if (refresh) {
        _currentPage = 1;
        _notifications.clear();
        _hasMorePages = true;
      }

      final result = await NotificationService.getUserNotifications(
        page: _currentPage,
        limit: 20,
      );

      if (result['statusCode'] == 200) {
        final List<dynamic> notificationsData = result['data'] ?? [];

        final List<NotificationModel> newNotifications = notificationsData
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        // Prevent spam initial popups
        for (var n in newNotifications) {
          _alertedNotificationIds.add(n.id);
        }

        for (int i = 0; i < newNotifications.length; i++) {}

        if (refresh) {
          _notifications = newNotifications;
        } else {
          _notifications.addAll(newNotifications);
        }

        // Update pagination info
        final pagination = result['pagination'];
        if (pagination != null) {
          _currentPage = pagination['currentPage'] ?? 1;
          _hasMorePages = _currentPage < (pagination['totalPages'] ?? 1);
        }

        notifyListeners();
      } else {
        _setError(result['message'] ?? 'Failed to load notifications');
      }
    } catch (e) {
      _setError('Error loading notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get unread notifications only
  Future<void> getUnreadNotifications() async {
    if (_isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      final result = await NotificationService.getUserNotifications(
        page: 1,
        limit: 50,
        unreadOnly: true,
      );

      if (result['statusCode'] == 200) {
        final List<dynamic> notificationsData = result['data'] ?? [];
        _notifications = notificationsData
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        notifyListeners();
      } else {
        _setError(result['message'] ?? 'Failed to load unread notifications');
      }
    } catch (e) {
      _setError('Error loading unread notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Background polling for new notifications
  void _startBackgroundPolling() {
    // Poll every 10 seconds for new notifications
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      _silentFetchNewNotifications();
    });
  }

  Future<void> _silentFetchNewNotifications() async {
    try {
      final result = await NotificationService.getUserNotifications(
        page: 1,
        limit: 10, // Just check the latest ones
        unreadOnly: true,
      );

      if (result['statusCode'] == 200) {
        final List<dynamic> notificationsData = result['data'] ?? [];
        final newSilentNotifications = notificationsData
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        bool hasNewAlerts = false;
        for (var notification in newSilentNotifications) {
          if (!_alertedNotificationIds.contains(notification.id)) {
            _alertedNotificationIds.add(notification.id);
            hasNewAlerts = true;
            
            // Add the new notification to the main list if not there
            if (_notifications.indexWhere((n) => n.id == notification.id) == -1) {
              _notifications.insert(0, notification);
            }
          }
        }

        if (hasNewAlerts) {
          // Update the unread count in UI
          getUnreadCount();
        }
      }
    } catch (e) {
      // Background error ignored to avoid spamming the user
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final result =
          await NotificationService.markNotificationAsRead(notificationId);

      if (result['statusCode'] == 200) {
        // Update the notification in the list
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          _updateUnreadCount();
          notifyListeners();
        }
      } else {
        _setError(result['message'] ?? 'Failed to mark notification as read');
      }
    } catch (e) {
      _setError('Error marking notification as read: $e');
    }
  }

  // Mark notification as unread
  Future<void> markAsUnread(String notificationId) async {
    try {
      final result =
          await NotificationService.markNotificationAsUnread(notificationId);

      if (result['statusCode'] == 200) {
        // Update the notification in the list
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: false);
          _updateUnreadCount();
          notifyListeners();
        }
      } else {
        _setError(result['message'] ?? 'Failed to mark notification as unread');
      }
    } catch (e) {
      _setError('Error marking notification as unread: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final result = await NotificationService.markAllNotificationsAsRead();

      if (result['statusCode'] == 200) {
        // Mark all notifications as read in the list
        _notifications = _notifications.map((notification) {
          return notification.copyWith(isRead: true);
        }).toList();

        _unreadCount = 0;
        notifyListeners();
      } else {
        _setError(
            result['message'] ?? 'Failed to mark all notifications as read');
      }
    } catch (e) {
      _setError('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final result =
          await NotificationService.deleteNotification(notificationId);

      if (result['statusCode'] == 200) {
        // Remove the notification from the list
        _notifications.removeWhere((n) => n.id == notificationId);
        _updateUnreadCount();
        notifyListeners();
      } else {
        _setError(result['message'] ?? 'Failed to delete notification');
      }
    } catch (e) {
      _setError('Error deleting notification: $e');
    }
  }

  // Get unread count
  Future<void> getUnreadCount() async {
    try {
      final result = await NotificationService.getUnreadCount();

      if (result['statusCode'] == 200) {
        final data = result['data'];
        if (data != null && data['unreadCount'] != null) {
          _unreadCount = data['unreadCount'];
          notifyListeners();
        }
      }
    } catch (e) {
      // Silently handle error for unread count
      // Handle error silently
    }
  }

  // Create meeting reminder notifications
  Future<void> createMeetingReminders() async {
    try {
      final result = await NotificationService.createMeetingReminders();

      if (result['statusCode'] == 200) {
        // Optionally refresh notifications after creating reminders
        await getNotifications(refresh: true);
      } else {
        _setError(result['message'] ?? 'Failed to create meeting reminders');
      }
    } catch (e) {
      _setError('Error creating meeting reminders: $e');
    }
  }

  // Load more notifications
  Future<void> loadMoreNotifications() async {
    if (_isLoading || !_hasMorePages) return;

    _currentPage++;
    await getNotifications();
  }

  // Refresh notifications
  Future<void> refreshNotifications() async {
    await getNotifications(refresh: true);
  }

  // Update unread count based on current notifications
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  // Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    _currentPage = 1;
    _hasMorePages = true;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    _error = null;
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  // Get notification by ID
  NotificationModel? getNotificationById(String id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get unread notifications
  List<NotificationModel> get unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }

  // Get read notifications
  List<NotificationModel> get readNotifications {
    return _notifications.where((n) => n.isRead).toList();
  }

  // Handle meeting notification tap
  Future<Map<String, dynamic>?> handleMeetingNotificationTap(
      String meetingId) async {
    try {
      final result =
          await NotificationService.getMeetingDetailsForNotification(meetingId);

      if (result['statusCode'] == 200) {
        return result;
      } else {
        _setError(result['message'] ?? 'Failed to get meeting details');
        return null;
      }
    } catch (e) {
      _setError('Error getting meeting details: $e');
      return null;
    }
  }
}
