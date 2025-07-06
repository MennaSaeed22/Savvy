import 'package:savvy/screens/Categories/models/budget_model.dart';

class FinanceSummary {
  static Map<String, double> calculateMonthlySummary(
      List<Map<String, dynamic>> transactions) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    double monthlyIncome = 0.0;
    double monthlyExpenses = 0.0;

    for (final transaction in transactions) {
      final createdAt = DateTime.parse(transaction['created_at']);

      if (createdAt.month == currentMonth && createdAt.year == currentYear) {
        final amount = (transaction['amount'] ?? 0).toDouble();
        final type = transaction['transaction_type'] ?? '';
        if (type == 'Income') {
          monthlyIncome += amount;
        } else if (type == 'Expense') {
          monthlyExpenses += amount;
        }
      }
    }
    return {
      'income': double.parse(monthlyIncome.toStringAsFixed(1)),
      'expenses': double.parse(monthlyExpenses.toStringAsFixed(1)),
      'balance':
          double.parse((monthlyIncome - monthlyExpenses).toStringAsFixed(1)),
    };
  }

  static Map<String, Map<String, dynamic>> calculateCategoryMonthlySummary(
    List<Map<String, dynamic>> transactions,
    List<Budget> budgets,
  ) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    Map<String, double> categoryExpenses = {};

    for (final transaction in transactions) {
      final createdAt = DateTime.parse(transaction['created_at']);
      if (createdAt.month == currentMonth &&
          createdAt.year == currentYear &&
          transaction['transaction_type'] == 'Expense') {
        final amount = (transaction['amount'] ?? 0).toDouble();
        final categoryName =
            transaction['categories']?['category_name'] ?? 'Unknown';

        categoryExpenses[categoryName] =
            (categoryExpenses[categoryName] ?? 0) + amount;
      }
    }

    Map<String, double> categoryBudgets = {
      for (var b in budgets) b.categoryName: b.allocatedAmount
    };

    Set<String> allCategories = {
      ...categoryExpenses.keys,
      ...categoryBudgets.keys
    };

    Map<String, Map<String, dynamic>> result = {};

    for (final categoryName in allCategories) {
      final spent = categoryExpenses[categoryName] ?? 0.0;
      final hasBudget = categoryBudgets.containsKey(categoryName);
      final budgeted = hasBudget ? categoryBudgets[categoryName]! : 0.0;
      final remaining = budgeted - spent;
      final percentageUsed = budgeted > 0 ? (spent / budgeted) * 100 : 0.0;

      result[categoryName] = {
        'spent': double.parse(spent.toStringAsFixed(1)),
        'budgeted': double.parse(budgeted.toStringAsFixed(1)),
        'remaining': double.parse(remaining.toStringAsFixed(1)),
        'percentage_used': double.parse(percentageUsed.toStringAsFixed(1)),
        'is_over_budget': spent > budgeted ? 1.0 : 0.0,
        'has_budget': hasBudget ? 1.0 : 0.0, // NEW: track if user set a budget
      };
    }
    return result;
  }

  static List<Map<String, dynamic>> getOverBudgetCategories(
    List<Map<String, dynamic>> transactions,
    List<Budget> budgets,
  ) {
    final categorySummary =
        calculateCategoryMonthlySummary(transactions, budgets);

    return categorySummary.entries
        .where((entry) => entry.value['is_over_budget'] == 1.0)
        .map((entry) => {
              'category_name': entry.key,
              'spent': entry.value['spent'],
              'budgeted': entry.value['budgeted'],
              'over_amount': double.parse(
                  (entry.value['spent']! - entry.value['budgeted']!)
                      .toStringAsFixed(1)),
            })
        .toList();
  }

  static Map<String, double> getBudgetUtilizationSummary(
    List<Map<String, dynamic>> transactions,
    List<Budget> budgets,
  ) {
    final categorySummary =
        calculateCategoryMonthlySummary(transactions, budgets);

    double totalBudgeted = 0.0;
    double totalSpent = 0.0;
    int overBudgetCount = 0;
    int totalCategories = categorySummary.length;

    for (final category in categorySummary.values) {
      totalBudgeted += category['budgeted']!;
      totalSpent += category['spent']!;
      if (category['is_over_budget'] == 1.0) {
        overBudgetCount++;
      }
    }
    return {
      'total_budgeted': double.parse(totalBudgeted.toStringAsFixed(1)),
      'total_spent': double.parse(totalSpent.toStringAsFixed(1)),
      'total_remaining':
          double.parse((totalBudgeted - totalSpent).toStringAsFixed(1)),
      'overall_percentage_used': totalBudgeted > 0
          ? double.parse(
              ((totalSpent / totalBudgeted) * 100).toStringAsFixed(1))
          : 0.0,
      'over_budget_categories': overBudgetCount.toDouble(),
      'total_categories': totalCategories.toDouble(),
    };
  }

  static int getDistinctMonthCount(List<Map<String, dynamic>> transactions) {
    final Set<String> uniqueMonths = {};

    for (final transaction in transactions) {
      final createdAt = DateTime.parse(transaction['created_at']);
      final monthKey =
          '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
      uniqueMonths.add(monthKey);
    }

    return uniqueMonths.length;
  }

  static double getCurrentMonthExpensesForCategory(
    List<Map<String, dynamic>> transactions,
    String categoryName,
  ) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    double total = 0.0;
    for (final transaction in transactions) {
      final createdAt = DateTime.parse(transaction['created_at']);
      if (createdAt.month == currentMonth &&
          createdAt.year == currentYear &&
          transaction['transaction_type'] == 'Expense' &&
          (transaction['categories']?['category_name'] ?? 'Unknown') ==
              categoryName) {
        total += (transaction['amount'] ?? 0).toDouble();
      }
    }
    return double.parse(total.toStringAsFixed(1));
  }
}
