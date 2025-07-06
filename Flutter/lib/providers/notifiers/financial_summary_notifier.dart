import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/low_balance_service.dart';
import '../../services/budget_notification_service.dart';
import '../../utils/finance_summary.dart';
import '../app_provider.dart';

class FinancialSummary {
  final double totalIncome;
  final double totalExpenses;
  final double balance;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
  });

  @override
  String toString() {
    return 'FinancialSummary(income: $totalIncome, expenses: $totalExpenses, balance: $balance)';
  }
}

class FinancialSummaryNotifier extends StateNotifier<AsyncValue<FinancialSummary>> {
  final Ref ref; // Add ref to access other providers
  
  FinancialSummaryNotifier(this.ref) : super(const AsyncValue.loading());

Future<void> fetchFinancialSummary() async {
  try {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) {
      throw Exception("User not logged in");
    }
    
    // Fetch all transactions
    final response = await supabase
        .from('transactions')
        .select('transaction_type, amount')
        .eq('user_id', userId);
    
    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    double totalSavings = 0.0;
    
    for (final transaction in response) {
      final amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
      final type = transaction['transaction_type'] ?? '';
      if (type == 'Income') {
        totalIncome += amount;
      } else if (type == 'Expense') {
        totalExpenses += amount;
      }
    }
    // Fetch total savings from goals table
    final goalsResponse = await supabase
        .from('goals')
        .select('amount_saved')
        .eq('user_id', userId);
    
    for (final goal in goalsResponse) {
      final saved = double.tryParse(goal['amount_saved'].toString()) ?? 0.0;
      totalSavings += saved;
    }
    
    final balance = totalIncome - (totalExpenses + totalSavings);
    
    final summary = FinancialSummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      balance: balance,
    );
    print('Calculated financial summary: $summary');
    state = AsyncValue.data(summary);
    
    // Check both low balance AND budget notifications
    await _checkLowBalance(balance);
    await _checkBudgetNotifications();
  } catch (e, stackTrace) {
    print('Error fetching financial summary: $e');
    state = AsyncValue.error(e, stackTrace);
  }
}

  /// Check if balance is low and trigger notification
  Future<void> _checkLowBalance(double balance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lowBalanceAlertsEnabled = prefs.getBool('lowBalanceAlerts') ?? false;
      final generalNotificationsEnabled = prefs.getBool('generalNotification') ?? false;
      
      await LowBalanceService.checkAndNotifyLowBalance(
        currentBalance: balance,
        lowBalanceAlertsEnabled: lowBalanceAlertsEnabled,
        generalNotificationsEnabled: generalNotificationsEnabled,
      );
    } catch (e) {
      print('Error checking low balance: $e');
    }
  }

  /// Check budget notifications automatically
  Future<void> _checkBudgetNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetNotificationsEnabled = prefs.getBool('budgetNotifications') ?? false;
      final generalNotificationsEnabled = prefs.getBool('generalNotification') ?? false;
      
      if (!budgetNotificationsEnabled || !generalNotificationsEnabled) {
        return; // Skip if notifications are disabled
      }

      // Get transactions and budgets from providers
      final transactionAsync = ref.read(transactionProvider);
      final budgetAsync = ref.read(budgetProvider);

      transactionAsync.whenData((transactions) {
        budgetAsync.whenData((budgets) {
          final categorySummary = FinanceSummary.calculateCategoryMonthlySummary(
            transactions,
            budgets,
          );
          
          BudgetNotificationService.checkAndNotifyBudgetStatus(
            categorySummary: categorySummary,
            budgetNotificationsEnabled: budgetNotificationsEnabled,
            generalNotificationsEnabled: generalNotificationsEnabled,
          );
        });
      });
    } catch (e) {
      print('Error checking budget notifications: $e');
    }
  }

  void subscribeToUpdates() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId != null) {
      supabase.channel('financial_summary_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'transactions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              print('Financial summary change detected: ${payload.eventType}');
              // Add a small delay before refetching to ensure database consistency
              Future.delayed(const Duration(milliseconds: 200), () {
                fetchFinancialSummary();
              });
            },
          )
          .subscribe();
    }
  }

  Future<void> refresh() async {
    await fetchFinancialSummary();
  }

  // Force refresh method that clears cache
  Future<void> forceRefresh() async {
    state = const AsyncValue.loading();
    await fetchFinancialSummary();
  }

  // Reset state for logout
  void clearCache() {
    state = AsyncValue.data(FinancialSummary(
      totalIncome: 0.0,
      totalExpenses: 0.0,
      balance: 0.0,
    ));
  }
  
  /// Manual method to check low balance (can be called from UI)
  Future<void> checkLowBalanceManually() async {
    final currentState = state;
    if (currentState is AsyncData<FinancialSummary>) {
      final balance = currentState.value.balance;
      await _checkLowBalance(balance);
    }
  }

  /// Manual method to check budget notifications (can be called from UI)
  Future<void> checkBudgetNotificationsManually() async {
    await _checkBudgetNotifications();
  }
}

// Update the provider to pass ref
final financialSummaryNotifier = StateNotifierProvider<FinancialSummaryNotifier, AsyncValue<FinancialSummary>>(
  (ref) => FinancialSummaryNotifier(ref),
);