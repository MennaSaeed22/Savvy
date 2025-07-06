import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savvy/screens/Categories/models/goal_model.dart';
import '../../data/api_repo.dart';
import '../../domain/models.dart';
import '../../data/goal_repo.dart';

final financialRepoProvider = Provider<FinancialDataRepository>((ref) {
  return SupabaseFinancialDataRepository();
});

final financialDataProvider = FutureProvider.family<FinancialData, String>((ref, period) async {
  final repo = ref.read(financialRepoProvider);
  final result = await repo.fetchPeriodData(period);

  final incomeList = (result['income'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      [];
  final expenseList = (result['expense'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      [];
  final labels = (result['labels'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
      [];

  final totalIncome = incomeList.isNotEmpty ? incomeList.reduce((a, b) => a + b) : 0.0;
  final totalExpense = expenseList.isNotEmpty ? expenseList.reduce((a, b) => a + b) : 0.0;

  return FinancialData(
    balance: totalIncome - totalExpense,
    income: totalIncome,
    expense: totalExpense,
    incomePerPeriod: incomeList,
    expensePerPeriod: expenseList,
    labels: labels,
    // categories: [], // You can populate this later
    categories: (result['categories'] as List<dynamic>?)
        ?.map((e) => SpendingCategory.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],

  );
});
final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  final repo = GoalRepository();
  return await repo.fetchGoals();
});
