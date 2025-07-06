import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/low_balance_service.dart';
import '../../services/notification_service.dart';
import '../../services/budget_notification_service.dart';
import '../../widgets/app_header.dart';
import '../../providers/app_provider.dart';
import '../../utils/finance_summary.dart';
import '../globals.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  // Toggle states
  bool generalNotification = false;
  bool expenseReminder = false;
  bool budgetNotifications = false;
  bool lowBalanceAlerts = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        generalNotification = prefs.getBool('generalNotification') ?? false;
        expenseReminder = prefs.getBool('expenseReminder') ?? false;
        budgetNotifications = prefs.getBool('budgetNotifications') ?? false;
        lowBalanceAlerts = prefs.getBool('lowBalanceAlerts') ?? false;
        _isLoading = false;
      });
      
      // Check for budget notifications when settings load
      if (budgetNotifications && generalNotification) {
        await _checkAndSendBudgetNotifications();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load settings');
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      _showErrorSnackBar('Failed to save setting');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

// Replace the commented out _checkAndSendBudgetNotifications method with this:
Future<void> _checkAndSendBudgetNotifications() async {
  if (!generalNotification || !budgetNotifications) return;

  try {
    // Use the financial summary notifier's method instead of local logic
    final financialSummaryNotifier = ref.read(financialSummaryProvider.notifier);
    await financialSummaryNotifier.checkBudgetNotificationsManually();
  } catch (e) {
    _showErrorSnackBar('Failed to check budget notifications');
  }
}

  Future<void> _sendToggleNotification(String key, bool value) async {
    try {
      if (key == 'generalNotification') {
        if (value) {
          final permissionGranted =
              await NotificationService.requestNotificationPermission();
          if (!permissionGranted) {
            setState(() {
              generalNotification = false;
            });
            await _saveSetting(key, false);
            _showErrorSnackBar(
                'Notification permissions are required to enable general notifications.');
            return;
          }
        }
      }

      if (!generalNotification && key != 'generalNotification') {
        return; // Don't send notifications if master toggle is off
      }

      final notificationData = _getNotificationData(key, value);
      
      await _handleSpecificNotificationLogic(key, value);

      if (notificationData.isNotEmpty) {
        await NotificationService.showNotification(
          title: notificationData['title']!,
          body: notificationData['body']!,
          generalNotification: generalNotification,
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update notification setting');
    }
  }

  Map<String, String> _getNotificationData(String key, bool value) {
    switch (key) {
      case 'generalNotification':
        return {
          'title': value ? "Notifications Enabled" : "Notifications Disabled",
          'body': value
              ? "You will now receive app notifications"
              : "You have turned off all notifications"
        };
      case 'expenseReminder':
        return {
          'title': "Expense Reminders ${value ? 'Enabled' : 'Disabled'}",
          'body': value
              ? "You will now receive reminders to log your daily expenses"
              : "Expense reminders have been turned off"
        };
      case 'budgetNotifications':
        return {
          'title': "Budget Notifications ${value ? 'Enabled' : 'Disabled'}",
          'body': value
              ? "You will now receive alerts about your budget status"
              : "Budget notifications have been turned off"
        };
      case 'lowBalanceAlerts':
        return {
          'title': "Low Balance Alerts ${value ? 'Enabled' : 'Disabled'}",
          'body': value
              ? "You will now be alerted when your accounts are running low"
              : "Low balance alerts have been turned off"
        };
      default:
        return {};
    }
  }

Future<void> _handleSpecificNotificationLogic(String key, bool value) async {
  switch (key) {
    case 'generalNotification':
      if (!value) {
        await BudgetNotificationService.clearAllBudgetNotificationTracking();
      }
      break;
    case 'expenseReminder':
      if (value) {
        await NotificationService.scheduleRepeatedNotification();
      } else {
        await NotificationService.cancelScheduledNotification();
      }
      break;
    case 'budgetNotifications':
      if (value) {
        // Use the financial provider's method
        final financialSummaryNotifier = ref.read(financialSummaryProvider.notifier);
        await financialSummaryNotifier.checkBudgetNotificationsManually();
      } else {
        await NotificationService.cancelBudgetNotifications();
        await BudgetNotificationService.clearAllBudgetNotificationTracking();
      }
      break;
    case 'lowBalanceAlerts':
      if (value) {
        final financialSummaryAsync = ref.read(financialSummaryProvider);
        financialSummaryAsync.whenData((summary) async {
          await LowBalanceService.checkAndNotifyLowBalance(
            currentBalance: summary.balance,
            lowBalanceAlertsEnabled: true,
            generalNotificationsEnabled: generalNotification,
          );
        });
      } else {
        await NotificationService.cancelLowBalanceNotifications();
      }
      break;
  }
}
  Widget _buildToggle(String title, bool value, String key, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: (val) async {
                setState(() {
                  switch (key) {
                    case 'generalNotification':
                      generalNotification = val;
                      break;
                    case 'expenseReminder':
                      expenseReminder = val;
                      break;
                    case 'budgetNotifications':
                      budgetNotifications = val;
                      break;
                    case 'lowBalanceAlerts':
                      lowBalanceAlerts = val;
                      break;
                  }
                });
                
                await _saveSetting(key, val);
                await _sendToggleNotification(key, val);
              },
              activeColor: primaryColor,
              inactiveTrackColor: Colors.grey.shade300,
              inactiveThumbColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required Widget icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color borderColor,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: borderColor.withOpacity(0.8),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: borderColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildBudgetStatus() {
    if (!budgetNotifications) return const SizedBox.shrink();

    final transactionAsync = ref.watch(transactionProvider);
    final budgetAsync = ref.watch(budgetProvider);

    return transactionAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (transactions) {
        return budgetAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (budgets) {
            final summary = FinanceSummary.calculateCategoryMonthlySummary(
              transactions,
              budgets,
            );
            
            final overBudgetCategories = summary.entries
                .where((entry) =>
                    entry.value['is_over_budget'] == 1.0 &&
                    entry.value['has_budget'] == 1.0)
                .toList();

            final approachingCategories = summary.entries
                .where((entry) =>
                    entry.value['percentage_used']! >= 80.0 &&
                    entry.value['percentage_used']! < 100.0 &&
                    entry.value['has_budget'] == 1.0)
                .toList();

            if (overBudgetCategories.isEmpty && approachingCategories.isEmpty) {
              return _buildStatusCard(
                icon: Icon(Icons.check_circle, color: Colors.green.shade600),
                title: "All categories within budget",
                subtitle: "You're doing great with your spending!",
                backgroundColor: Colors.green.shade50,
                borderColor: Colors.green.shade200,
              );
            }

            final hasOverBudget = overBudgetCategories.isNotEmpty;
            return _buildStatusCard(
              icon: Icon(
                hasOverBudget ? Icons.warning : Icons.info,
                color: hasOverBudget ? Colors.red.shade600 : Colors.orange.shade600,
              ),
              title: hasOverBudget
                  ? "${overBudgetCategories.length} categories over budget"
                  : "${approachingCategories.length} categories approaching limit",
              subtitle: _getBudgetStatusSubtitle(overBudgetCategories, approachingCategories),
              backgroundColor: hasOverBudget ? Colors.red.shade50 : Colors.orange.shade50,
              borderColor: hasOverBudget ? Colors.red.shade200 : Colors.orange.shade200,
            );
          },
        );
      },
    );
  }

  String _getBudgetStatusSubtitle(List overBudget, List approaching) {
    if (overBudget.isNotEmpty && approaching.isNotEmpty) {
      return "Review your spending in these categories";
    } else if (overBudget.isNotEmpty) {
      return "Consider adjusting budgets or reducing spending";
    } else {
      return "Watch your spending to stay within budget";
    }
  }

  Widget _buildLowBalanceStatus() {
    if (!lowBalanceAlerts) return const SizedBox.shrink();

    final financialSummaryAsync = ref.watch(financialSummaryProvider);

    return financialSummaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        return FutureBuilder<double>(
          future: LowBalanceService.getLowBalanceThreshold(),
          builder: (context, thresholdSnapshot) {
            if (!thresholdSnapshot.hasData) return const SizedBox.shrink();

            final threshold = thresholdSnapshot.data!;
            final balance = summary.balance;
            final isLow = balance <= threshold;

            return _buildStatusCard(
              icon: Icon(
                isLow ? Icons.warning : Icons.check_circle,
                color: isLow ? Colors.red.shade600 : Colors.green.shade600,
              ),
              title: "Balance: \$${balance.toStringAsFixed(2)}",
              subtitle: isLow 
                  ? "Your balance is below the alert threshold"
                  : "Your balance is healthy",
              backgroundColor: isLow ? Colors.red.shade50 : Colors.green.shade50,
              borderColor: isLow ? Colors.red.shade200 : Colors.green.shade200,
              trailing: TextButton(
                onPressed: () => _showThresholdDialog(threshold),
                child: Text(
                  "Change\nThreshold",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showThresholdDialog(double currentThreshold) async {
    final TextEditingController controller = TextEditingController(
      text: currentThreshold.toStringAsFixed(2),
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: OffWhite,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set Low Balance Threshold',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: secondaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You will be notified when your balance falls below this amount:',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Threshold Amount',
                    labelStyle: TextStyle(color: secondaryColor),
                    prefixText: 'EGP ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: softBlue),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: softBlue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: secondaryColor,
                          backgroundColor: softBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final newThreshold = double.tryParse(controller.text);
                          if (newThreshold != null && newThreshold >= 0) {
                            await LowBalanceService.setLowBalanceThreshold(newThreshold);
                            Navigator.of(context).pop();
                            setState(() {});
                            _showSuccessSnackBar(
                                'Low balance threshold updated to \$${newThreshold.toStringAsFixed(2)}');
                          } else {
                            _showErrorSnackBar('Please enter a valid amount');
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: OffWhite,
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              title: "Notification Settings",
              arrowVisible: true,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: OffWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          _buildToggle(
                            "General Notifications",
                            generalNotification,
                            'generalNotification',
                            subtitle: "Master switch for all notifications",
                          ),
                          const Divider(height: 32),
                          
                          if (generalNotification) ...[
                            _buildToggle(
                              "Expense Reminders",
                              expenseReminder,
                              'expenseReminder',
                              subtitle: "Daily reminders to log expenses",
                            ),
                            const SizedBox(height: 16),
                            
                            _buildToggle(
                              "Budget Alerts",
                              budgetNotifications,
                              'budgetNotifications',
                              subtitle: "Smart alerts when approaching or exceeding budgets",
                            ),
                            _buildBudgetStatus(),
                            const SizedBox(height: 16),
                            
                            _buildToggle(
                              "Low Balance Alerts",
                              lowBalanceAlerts,
                              'lowBalanceAlerts',
                              subtitle: "Get warned when account balance is low",
                            ),
                            _buildLowBalanceStatus(),
                          ] else
                            Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.notifications_off,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Enable general notifications to access more options",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 20),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}