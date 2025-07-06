import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:savvy/screens/globals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomBarChart extends StatelessWidget {
  final List<double> incomeData;
  final List<double> expenseData;
  final List<String> labels;
  const CustomBarChart({
    super.key,
    required this.incomeData,
    required this.expenseData,
    required this.labels,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OffWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _calculateMaxY(),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final value = rod.toY;
                  final label = rodIndex == 0 ? 'Income' : 'Expense';
                  return BarTooltipItem(
                    '$label\n EGP${value.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[value.toInt()],
                        style: const TextStyle(
                          fontSize: 10,
                          color: secondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      /*EGP*/ '${value.toInt()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: _buildBarGroups(),
            gridData: const FlGridData(show: false),
          ),
        ),
      ),
    );
  }

  double _calculateMaxY() {
    final maxIncome = incomeData.reduce((a, b) => a > b ? a : b);
    final maxExpense = expenseData.reduce((a, b) => a > b ? a : b);
    return (maxIncome > maxExpense ? maxIncome : maxExpense) * 1.2;
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(incomeData.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: incomeData[index],
            color: primaryColor,
            width: 8,
            borderRadius: BorderRadius.circular(6),
          ),
          BarChartRodData(
            toY: expenseData[index],
            color: secondaryColor,
            width: 8,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });
  }

//verified //extra
  Future<Map<String, double>> getIncomeExpense(String period) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not logged in");

    final now = DateTime.now();
    DateTime start;

    switch (period) {
      case 'Daily':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'Weekly':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'Monthly':
        start = DateTime(now.year, now.month, 1);
        break;
      default:
        start = DateTime(1970);
    }

    final response = await supabase
        .from('transactions')
        .select('amount, transaction_type, created_at')
        .eq('user_id', userId)
        .gte('created_at', start.toIso8601String());

    double income = 0.0;
    double expense = 0.0;

    for (final tx in response) {
      final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final type = tx['transaction_type'] ?? '';
      if (type == 'Income') {
        income += amount;
      } else if (type == 'Expense') {
        expense += amount;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }
}
