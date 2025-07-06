import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class BudgetNotificationService {
  // Minimum time between budget notifications for the same category (in hours)
  static const int notificationCooldownHours = 12;
  
  // Threshold for approaching budget limit (percentage)
  static const double approachingLimitThreshold = 80.0;
  
  /// Check budget status for all categories and send notifications if needed
  static Future<void> checkAndNotifyBudgetStatus({
    required Map<String, Map<String, dynamic>> categorySummary,
    required bool budgetNotificationsEnabled,
    required bool generalNotificationsEnabled,
  }) async {
    if (!generalNotificationsEnabled || !budgetNotificationsEnabled) {
      return; // Don't check if notifications are disabled
    }
    
    for (final entry in categorySummary.entries) {
      final categoryName = entry.key;
      final categoryData = entry.value;
      
      // Only process categories that have a budget set
      if (categoryData['has_budget'] != 1.0) {
        continue;
      }
      
      final spent = categoryData['spent'] as double;
      final budgeted = categoryData['budgeted'] as double;
      final percentageUsed = categoryData['percentage_used'] as double;
      final isOverBudget = categoryData['is_over_budget'] == 1.0;
      
      if (isOverBudget) {
        // Handle over-budget notification
        await _handleOverBudgetNotification(
          categoryName: categoryName,
          spent: spent,
          budgeted: budgeted,
        );
      } else if (percentageUsed >= approachingLimitThreshold) {
        // Handle approaching limit notification
        await _handleApproachingLimitNotification(
          categoryName: categoryName,
          spent: spent,
          budgeted: budgeted,
          percentageUsed: percentageUsed,
        );
      } else {
        // Clear notification tracking if spending is back to normal
        await _clearCategoryNotificationTracking(categoryName);
      }
    }
  }
  
  /// Handle over-budget notifications for a specific category
  static Future<void> _handleOverBudgetNotification({
    required String categoryName,
    required double spent,
    required double budgeted,
  }) async {
    final shouldNotify = await _shouldSendOverBudgetNotification(
      categoryName,
      spent,
      budgeted,
    );
    
    if (shouldNotify) {
      final overAmount = spent - budgeted;
      await _sendOverBudgetNotification(
        categoryName: categoryName,
        spent: spent,
        budgeted: budgeted,
        overAmount: overAmount,
      );
      await _updateOverBudgetNotificationTime(categoryName, spent);
    }
  }
  
  /// Handle approaching limit notifications for a specific category
  static Future<void> _handleApproachingLimitNotification({
    required String categoryName,
    required double spent,
    required double budgeted,
    required double percentageUsed,
  }) async {
    final shouldNotify = await _shouldSendApproachingLimitNotification(
      categoryName,
      percentageUsed,
    );
    
    if (shouldNotify) {
      await _sendApproachingLimitNotification(
        categoryName: categoryName,
        spent: spent,
        budgeted: budgeted,
        percentageUsed: percentageUsed,
      );
      await _updateApproachingLimitNotificationTime(categoryName, percentageUsed);
    }
  }
  
  /// Send over-budget notification
  static Future<void> _sendOverBudgetNotification({
    required String categoryName,
    required double spent,
    required double budgeted,
    required double overAmount,
  }) async {
    final title = "Budget Exceeded: $categoryName";
    final body = "You've spent \$${spent.toStringAsFixed(2)} out of "
        "\$${budgeted.toStringAsFixed(2)} budget. Over by \$${overAmount.toStringAsFixed(2)}";
    
    await NotificationService.showBudgetNotification(
      title: title,
      body: body,
      generalNotification: true,
      categoryName: categoryName,
    );
  }
  
  /// Send approaching limit notification
  static Future<void> _sendApproachingLimitNotification({
    required String categoryName,
    required double spent,
    required double budgeted,
    required double percentageUsed,
  }) async {
    final title = "Budget Warning: $categoryName";
    final body = "You've used ${percentageUsed.toStringAsFixed(0)}% of your budget "
        "(\$${spent.toStringAsFixed(2)} of \$${budgeted.toStringAsFixed(2)})";
    
    await NotificationService.showBudgetNotification(
      title: title,
      body: body,
      generalNotification: true,
      categoryName: categoryName,
    );
  }
  
  /// Check if we should send over-budget notification
  static Future<bool> _shouldSendOverBudgetNotification(
    String categoryName,
    double currentSpent,
    double budgeted,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'over_budget_$categoryName';
    
    final lastNotificationTime = prefs.getInt('${key}_time');
    final lastNotifiedSpent = prefs.getDouble('${key}_spent');
    
    if (lastNotificationTime == null) {
      return true; // First time notification
    }
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeDifference = now - lastNotificationTime;
    final hoursSinceLastNotification = timeDifference / (1000 * 60 * 60);
    
    // Send notification if:
    // 1. It's been more than the cooldown period, OR
    // 2. Spending has increased significantly since last notification
    if (hoursSinceLastNotification >= notificationCooldownHours) {
      return true;
    }
    
    // If spending increased by 20% or more of the budget since last notification
    if (lastNotifiedSpent != null) {
      final spendingIncrease = currentSpent - lastNotifiedSpent;
      final significantIncrease = budgeted * 0.2; // 20% of budget
      if (spendingIncrease >= significantIncrease) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Check if we should send approaching limit notification
  static Future<bool> _shouldSendApproachingLimitNotification(
    String categoryName,
    double percentageUsed,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'approaching_limit_$categoryName';
    
    final lastNotificationTime = prefs.getInt('${key}_time');
    final lastNotifiedPercentage = prefs.getDouble('${key}_percentage');
    
    if (lastNotificationTime == null) {
      return true; // First time notification
    }
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeDifference = now - lastNotificationTime;
    final hoursSinceLastNotification = timeDifference / (1000 * 60 * 60);
    
    // Send notification if:
    // 1. It's been more than the cooldown period, OR
    // 2. Percentage has increased significantly (by 10% or more)
    if (hoursSinceLastNotification >= notificationCooldownHours) {
      return true;
    }
    
    if (lastNotifiedPercentage != null) {
      final percentageIncrease = percentageUsed - lastNotifiedPercentage;
      if (percentageIncrease >= 10.0) { // 10% increase
        return true;
      }
    }
    
    return false;
  }
  
  /// Update over-budget notification tracking
  static Future<void> _updateOverBudgetNotificationTime(
    String categoryName,
    double spent,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'over_budget_$categoryName';
    
    await prefs.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
    await prefs.setDouble('${key}_spent', spent);
  }
  
  /// Update approaching limit notification tracking
  static Future<void> _updateApproachingLimitNotificationTime(
    String categoryName,
    double percentageUsed,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'approaching_limit_$categoryName';
    
    await prefs.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
    await prefs.setDouble('${key}_percentage', percentageUsed);
  }
  
  /// Clear notification tracking for a category (when spending is back to normal)
  static Future<void> _clearCategoryNotificationTracking(String categoryName) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear over-budget tracking
    await prefs.remove('over_budget_${categoryName}_time');
    await prefs.remove('over_budget_${categoryName}_spent');
    
    // Clear approaching limit tracking only if spending is below 70%
    // (to avoid re-triggering when fluctuating around 80%)
    final lastPercentage = prefs.getDouble('approaching_limit_${categoryName}_percentage');
    if (lastPercentage == null || lastPercentage < 70.0) {
      await prefs.remove('approaching_limit_${categoryName}_time');
      await prefs.remove('approaching_limit_${categoryName}_percentage');
    }
  }
  
  /// Clear all budget notification tracking (useful for logout or reset)
  static Future<void> clearAllBudgetNotificationTracking() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith('over_budget_') || key.startsWith('approaching_limit_')) {
        await prefs.remove(key);
      }
    }
  }
  
  /// Get notification status for a category
  static Future<Map<String, dynamic>> getCategoryNotificationStatus(String categoryName) async {
    final prefs = await SharedPreferences.getInstance();
    
    final overBudgetTime = prefs.getInt('over_budget_${categoryName}_time');
    final approachingLimitTime = prefs.getInt('approaching_limit_${categoryName}_time');
    
    return {
      'has_over_budget_notification': overBudgetTime != null,
      'has_approaching_limit_notification': approachingLimitTime != null,
      'last_over_budget_notification': overBudgetTime != null 
          ? DateTime.fromMillisecondsSinceEpoch(overBudgetTime)
          : null,
      'last_approaching_limit_notification': approachingLimitTime != null
          ? DateTime.fromMillisecondsSinceEpoch(approachingLimitTime)
          : null,
    };
  }
  
  /// Set custom approaching limit threshold (default is 80%)
  static Future<void> setApproachingLimitThreshold(double threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('approaching_limit_threshold', threshold);
  }
  
  /// Get custom approaching limit threshold
  static Future<double> getApproachingLimitThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('approaching_limit_threshold') ?? approachingLimitThreshold;
  }
}