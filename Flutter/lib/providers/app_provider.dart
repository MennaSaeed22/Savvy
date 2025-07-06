// providers/app_providers.dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/globals.dart';
import '../services/auth_service.dart';
import 'notifiers/financial_summary_notifier.dart';
import 'notifiers/user_notifier.dart';
import 'notifiers/transaction_notifier.dart';
import 'notifiers/budget_notifier.dart';
import '../../screens/Categories/models/budget_model.dart';

// Auth Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

// User Profile Provider
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return UserNotifier(authService);
});

// Transaction Provider
final transactionProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final notifier = TransactionNotifier();
  notifier.fetchTransactions();
  notifier.subscribeToUpdates();
  return notifier;
});

// Update the provider to pass ref
final financialSummaryProvider = StateNotifierProvider<FinancialSummaryNotifier, AsyncValue<FinancialSummary>>((ref) {
  final notifier = FinancialSummaryNotifier(ref);
  notifier.fetchFinancialSummary();
  notifier.subscribeToUpdates();
  return notifier;
});

// Budget Provider
final budgetProvider = StateNotifierProvider<BudgetNotifier, AsyncValue<List<Budget>>>((ref) {
  final user = ref.watch(currentUserProvider);
  final notifier = BudgetNotifier();
  if (user != null) {
    notifier.fetchBudgets(user.id);
  }
  return notifier;
});

final forecastProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, userId) async {
  ref.keepAlive(); // Keep provider alive — no warning now
  final response = await http.get(Uri.parse('$baseURL/forecast/predict/$userId'));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else if (response.statusCode == 404 || response.statusCode == 400) {
    return null;
  } else {
    throw Exception('Failed to load forecast');
  }
});
