import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Define notification IDs for different types
  static const int dailyReminderNotificationId = 1;
  static const int budgetNotificationStartId =
      100; // Start ID for budget notifications
  static const int lowBalanceNotificationStartId =
      200; // Start ID for balance notifications

  static ontap(NotificationResponse notificationResponse) async {
    if (notificationResponse.payload == 'daily_reminder') {
      await saveNotification(
        "Daily Expense Reminder",
        "Don't forget to log your daily expenses! (Delivered at ${DateFormat('h:mm a').format(DateTime.now())})",
        "triggered",
      );
    }
  }

  static Future<void> init() async {
    // Android Initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS Initialization
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    // Combined settings
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveBackgroundNotificationResponse: ontap,
      onDidReceiveNotificationResponse: ontap,
    );
    final details =
        await _notificationsPlugin.getNotificationAppLaunchDetails();

    if ((details?.didNotificationLaunchApp ?? false) &&
        details?.notificationResponse?.payload == 'daily_reminder') {
      await saveNotification(
        "Daily Expense Reminder",
        "Launched from background notification (at ${DateFormat('h:mm a').format(DateTime.now())})",
        "triggered",
      );
    }
  }

  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  // saveNotification method to save the notification to SharedPreferences
  static Future<void> saveNotification(
      String title, String body, String status) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList('notifications') ?? [];
    // Decode existing notifications
    List<Map<String, dynamic>> notificationList = notifications
        .map((String notificationString) =>
            jsonDecode(notificationString) as Map<String, dynamic>)
        .toList();
    // Check if a notification with the same title already exists
    int existingIndex = notificationList
        .indexWhere((notification) => notification['title'] == title);
    Map<String, dynamic> notificationData = {
      'title': title,
      'body': body,
      'status': status, // Add status field
      'timestamp': DateTime.now().toIso8601String(),
    };
    if (existingIndex != -1) {
      // Update the existing notification
      notificationList[existingIndex] = notificationData;
    } else {
      // Add the new notification
      notificationList.insert(0, notificationData);
    }
    // Save the updated notifications back to SharedPreferences
    notifications = notificationList
        .map((notification) => jsonEncode(notification))
        .toList();
    await prefs.setStringList('notifications', notifications);
  }

  // getNotifications method to retrieve the notifications from SharedPreferences
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notificationStrings =
        prefs.getStringList('notifications') ?? [];
    // Decode the notifications
    List<Map<String, dynamic>> notifications = notificationStrings
        .map((String notificationString) =>
            jsonDecode(notificationString) as Map<String, dynamic>)
        .toList();
    // Sort notifications by timestamp in descending order (newest first)
    notifications.sort((a, b) {
      DateTime dateA = DateTime.parse(a['timestamp']);
      DateTime dateB = DateTime.parse(b['timestamp']);
      return dateB.compareTo(dateA); // Newest first
    });
    return notifications;
  }

  // clearNotifications method to clear all notifications from SharedPreferences
  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
  }

  // showNotification method to display a general notifications
  static Future<void> showNotification({
    required String title,
    required String body,
    required bool generalNotification,
    String? payload,
    int? customId,
  }) async {
    // Request notification permissions
    await requestNotificationPermission();
    if (!generalNotification) {
      return; // Don't show notification if general toggle is off
    }

    // chanel based on the notification sound
    const String channelId = 'id_1';
    const String channelName = 'General';
    const String channelDescription = 'General Notifications';

    // Configure Android notification details
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      channelShowBadge: true,
      sound: null, // Default sound or muted
    );
    final details = NotificationDetails(
      android: androidDetails,
    );

    // Use custom ID or generate unique ID
    final notificationId =
        customId ?? (DateTime.now().millisecondsSinceEpoch % 10000);

    // Display the notification
    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
    // Save notification to SharedPreferences
    await saveNotification(title, body, "Delivered");
  }

  // Show budget notification with specific ID management
  static Future<void> showBudgetNotification({
    required String title,
    required String body,
    required bool generalNotification,
    required String categoryName,
  }) async {
    if (!generalNotification) return;

    // Generate a consistent ID for each category
    final notificationId =
        budgetNotificationStartId + categoryName.hashCode.abs() % 100;

    const String channelId = 'budget_alerts';
    const String channelName = 'Budget Alerts';
    const String channelDescription = 'Budget and spending notifications';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      channelShowBadge: true,
      sound: null,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      details,
      payload: 'budget_alert_$categoryName',
    );

    // Save the notification ID for later cancellation
    await _saveBudgetNotificationId(categoryName, notificationId);
    await saveNotification(title, body, "Delivered");
  }

  // Save budget notification IDs for later cancellation
  static Future<void> _saveBudgetNotificationId(
      String categoryName, int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> budgetNotificationIds =
        prefs.getStringList('budget_notification_ids') ?? [];

    // Remove existing entry for this category
    budgetNotificationIds
        .removeWhere((entry) => entry.startsWith('$categoryName:'));

    // Add new entry
    budgetNotificationIds.add('$categoryName:$notificationId');

    await prefs.setStringList('budget_notification_ids', budgetNotificationIds);
  }

  // Cancel all budget-related notifications
  static Future<void> cancelBudgetNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> budgetNotificationIds =
        prefs.getStringList('budget_notification_ids') ?? [];

    // Cancel each saved budget notification
    for (String entry in budgetNotificationIds) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        final notificationId = int.tryParse(parts[1]);
        if (notificationId != null) {
          await _notificationsPlugin.cancel(notificationId);
        }
      }
    }

    // Clear the saved notification IDs
    await prefs.remove('budget_notification_ids');

    // Also cancel any notifications in the budget ID range
    for (int i = budgetNotificationStartId;
        i < budgetNotificationStartId + 100;
        i++) {
      await _notificationsPlugin.cancel(i);
    }
  }

  // Show low balance notification with specific ID management
  static Future<void> showLowBalanceNotification({
    required String title,
    required String body,
    required bool generalNotification,
    required double balance,
  }) async {
    if (!generalNotification) return;

    // Use a fixed ID for low balance notifications (only one at a time)
    final notificationId = lowBalanceNotificationStartId;

    const String channelId = 'low_balance_alerts';
    const String channelName = 'Low Balance Alerts';
    const String channelDescription =
        'Notifications when your balance is running low';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      channelShowBadge: true,
      sound: null,
      // Make it persistent for critical low balance
      ongoing: balance <= 0,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      details,
      payload: 'low_balance_alert',
    );

    await saveNotification(title, body, "Delivered");
  }

  // Cancel low balance notifications
  static Future<void> cancelLowBalanceNotifications() async {
    // Cancel notifications in the low balance ID range
    for (int i = lowBalanceNotificationStartId;
        i < lowBalanceNotificationStartId + 100;
        i++) {
      await _notificationsPlugin.cancel(i);
    }
  }

  // scheduleNotification method to schedule a notification
  static Future<void> scheduleRepeatedNotification() async {
    String title = "Daily Reminder";
    String body = "Don't forget to log your daily expenses!";
    // Cancel any existing notification with the same ID
    await cancelScheduledNotification();
    const String channelId = 'id_2';
    const String channelName = 'Reminder';
    const String channelDescription = 'Expenses reminder Notifications';
    // Schedule the notification for 8:30 PM every day
    final now = tz.TZDateTime.now(tz.local);
    final cairo = tz.getLocation('Africa/Cairo');
    final scheduledTime = tz.TZDateTime(
      cairo,
      now.year,
      now.month,
      now.day,
      20, // Set the hour to 20 (8 PM)
      0, // Set the minutes to 0
      0, // Set the seconds to 0
    );
    // If the scheduled time has already passed today, schedule it for tomorrow
    final adjustedScheduledTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(Duration(days: 1))
        : scheduledTime;
    final androidDetails = AndroidNotificationDetails(channelId, channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
        sound: null // Default sound
        );
    final notificationDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.zonedSchedule(
      dailyReminderNotificationId, // Use constant ID
      title,
      body,
      adjustedScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exact,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeat daily at the same time
      payload: 'daily_reminder',
    );
  }

  // Cancel the scheduled notification
  static Future<void> cancelScheduledNotification() async {
    await _notificationsPlugin.cancel(dailyReminderNotificationId);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll(); // Cancel all notifications
  }
}
