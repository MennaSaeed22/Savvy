import 'package:flutter/material.dart';

@immutable
class FinancialData {
  final double balance;
  final double income;
  final double expense;

  final List<double> incomePerPeriod;
  final List<double> expensePerPeriod;
  final List<String> labels;
  final List<SpendingCategory> categories;

  const FinancialData({
    required this.balance,
    required this.income,
    required this.expense,
    required this.incomePerPeriod,
    required this.expensePerPeriod,
    required this.labels,
    required this.categories,
  });

  factory FinancialData.fromJson(Map<String, dynamic> json) {
    return FinancialData(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      incomePerPeriod: (json['income'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      expensePerPeriod: (json['expense'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => SpendingCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
class SpendingCategory {
  final String name;
  final double amount;
  final Color color;

  const SpendingCategory({
    required this.name,
    required this.amount,
    required this.color,
  });

  factory SpendingCategory.fromJson(Map<String, dynamic> json) {
    return SpendingCategory(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      color: _parseColor(json['color'] as String?),
    );
  }

  static Color _parseColor(String? hexColor) {
    if (hexColor == null) return Colors.grey;
    return Color(int.parse(hexColor.replaceFirst('#', ''), radix: 16) + 0xFF000000);
  }
}
