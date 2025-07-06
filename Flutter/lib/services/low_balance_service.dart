import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class LowBalanceService {
  // Default threshold - can be customized by user
  static const double defaultLowBalanceThreshold = 100.0;
  
  // Minimum time between low balance notifications (in hours)
  static const int notificationCooldownHours = 24;
  
  /// Check if balance is low and send notification if needed
  static Future<void> checkAndNotifyLowBalance({
    required double currentBalance,
    required bool lowBalanceAlertsEnabled,
    required bool generalNotificationsEnabled,
  }) async {
    if (!generalNotificationsEnabled || !lowBalanceAlertsEnabled) {
      return; // Don't check if notifications are disabled
    }
    
    final threshold = await getLowBalanceThreshold();
    
    // Check if balance is below threshold
    if (currentBalance <= threshold) {
      final shouldNotify = await _shouldSendLowBalanceNotification(currentBalance);
      
      if (shouldNotify) {
        await _sendLowBalanceNotification(currentBalance, threshold);
        await _updateLastNotificationTime();
      }
    } else {
      // Reset the notification cooldown if balance is above threshold
      await _clearLastNotificationTime();
    }
  }
  
  /// Send low balance notification
  static Future<void> _sendLowBalanceNotification(double balance, double threshold) async {
    String title = "Low Balance Alert";
    String body;
    
    if (balance <= 0) {
      body = "Your balance is \$${balance.toStringAsFixed(2)}. Consider adding income or reducing expenses.";
    } else {
      body = "Your balance is \$${balance.toStringAsFixed(2)}, below your threshold of \$${threshold.toStringAsFixed(2)}.";
    }
    
    await NotificationService.showLowBalanceNotification(
      title: title,
      body: body,
      generalNotification: true,
      balance: balance,
    );
  }
  
  /// Check if we should send a notification (respects cooldown period)
  static Future<bool> _shouldSendLowBalanceNotification(double currentBalance) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get last notification time and balance
    final lastNotificationTime = prefs.getInt('last_low_balance_notification');
    final lastNotifiedBalance = prefs.getDouble('last_notified_balance');
    
    if (lastNotificationTime == null) {
      return true; // First time notification
    }
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeDifference = now - lastNotificationTime;
    final hoursSinceLastNotification = timeDifference / (1000 * 60 * 60);
    
    // Send notification if:
    // 1. It's been more than the cooldown period, OR
    // 2. Balance has decreased significantly since last notification (e.g., by 20% or more)
    if (hoursSinceLastNotification >= notificationCooldownHours) {
      return true;
    }
    
    if (lastNotifiedBalance != null && currentBalance < lastNotifiedBalance * 0.8) {
      return true; // Balance dropped by 20% or more
    }
    
    return false;
  }
  
  /// Update the last notification time and balance
  static Future<void> _updateLastNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_low_balance_notification', DateTime.now().millisecondsSinceEpoch);
  }
  
  /// Clear the last notification time (when balance improves)
  static Future<void> _clearLastNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_low_balance_notification');
    await prefs.remove('last_notified_balance');
  }
  
  /// Get user's low balance threshold
  static Future<double> getLowBalanceThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('low_balance_threshold') ?? defaultLowBalanceThreshold;
  }
  
  /// Set user's low balance threshold
  static Future<void> setLowBalanceThreshold(double threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('low_balance_threshold', threshold);
  }
  
  /// Get balance status description
  static String getBalanceStatusDescription(double balance, double threshold) {
    if (balance <= 0) {
      return "Critical: Negative balance";
    } else if (balance <= threshold * 0.5) {
      return "Very Low: Below 50% of threshold";
    } else if (balance <= threshold) {
      return "Low: Below threshold";
    } else {
      return "Good: Above threshold";
    }
  }
  
  /// Check if balance is considered low
  static Future<bool> isBalanceLow(double balance) async {
    final threshold = await getLowBalanceThreshold();
    return balance <= threshold;
  }
}