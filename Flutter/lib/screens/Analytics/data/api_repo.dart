import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

abstract class FinancialDataRepository {
  Future<Map<String, dynamic>> fetchPeriodData(String period);
}

class SupabaseFinancialDataRepository implements FinancialDataRepository {
  @override
  Future<Map<String, dynamic>> fetchPeriodData(String period) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) throw Exception("User not logged in");

  final now = DateTime.now();
  late DateTime start;
  List<String> labels = [];
  Map<String, double> incomeMap = {};
  Map<String, double> expenseMap = {};

  if (period == 'Daily') {
    start = now.subtract(Duration(days: 6));
    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final label = DateFormat.E().format(date); // Mon, Tue
      labels.add(label);
      incomeMap[label] = 0.0;
      expenseMap[label] = 0.0;
    }
  } else if (period == 'Weekly') {
    start = now.subtract(Duration(days: 28));
    for (int i = 0; i < 4; i++) {
      final weekStart = start.add(Duration(days: i * 7));
      final label = 'Wk ${DateFormat.Md().format(weekStart)}';
      labels.add(label);
      incomeMap[label] = 0.0;
      expenseMap[label] = 0.0;
    }
  } else if (period == 'Monthly') {
    start = DateTime(now.year, now.month - 5, 1);
    for (int i = 0; i < 6; i++) {
      final month = DateTime(start.year, start.month + i, 1);
      final label = DateFormat.MMM().format(month); // Jan, Feb
      labels.add(label);
      incomeMap[label] = 0.0;
      expenseMap[label] = 0.0;
    }
  } else {
    throw Exception("Invalid period");
  }

  final response = await supabase
      .from('transactions')
      .select('amount, transaction_type, created_at')
      .eq('user_id', userId)
      .gte('created_at', start.toIso8601String());

  for (final tx in response) {
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final type = tx['transaction_type'] ?? '';
    final date = DateTime.parse(tx['created_at']);
    String label = '';

    if (period == 'Daily') {
      label = DateFormat.E().format(date);
    } else if (period == 'Weekly') {
      final weekIndex = date.difference(start).inDays ~/ 7;
      if (weekIndex >= 0 && weekIndex < 4) label = labels[weekIndex];
    } else if (period == 'Monthly') {
      final monthIndex =
          (date.year - start.year) * 12 + (date.month - start.month);
      if (monthIndex >= 0 && monthIndex < 6) label = labels[monthIndex];
    }

    if (incomeMap.containsKey(label)) {
      if (type == 'Income') {
        incomeMap[label] = incomeMap[label]! + amount;
      } else if (type == 'Expense') {
        expenseMap[label] = expenseMap[label]! + amount;
      }
    }
  }

  // 🔹 Category Spending Only for Daily
  List<Map<String, dynamic>> categoryData = [];
  if (period == 'Daily') {
    final categoryResponse = await supabase
        .from('transactions')
        .select('amount, transaction_type, created_at, categories(category_name)')
        .eq('user_id', userId)
        .gte('created_at', start.toIso8601String());

    final Map<String, double> categoryMap = {};

    for (final tx in categoryResponse) {
      final category = tx['categories']?['category_name'] ?? 'Uncategorized';
      final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final type = tx['transaction_type'] ?? '';

      if (type == 'Expense') {
        categoryMap[category] = (categoryMap[category] ?? 0.0) + amount;
      }
    }

    categoryData = categoryMap.entries.map((e) => {
      'name': e.key,
      'amount': e.value,
      'color': _assignColorForCategory(e.key),
    }).toList();
  }

  return {
    'income': labels.map((label) => incomeMap[label] ?? 0.0).toList(),
    'expense': labels.map((label) => expenseMap[label] ?? 0.0).toList(),
    'labels': labels,
    'categories': categoryData,
  };
}

//   Future<Map<String, dynamic>> fetchPeriodData(String period) async {
//     final supabase = Supabase.instance.client;
//     final userId = supabase.auth.currentUser?.id;

//     if (userId == null) throw Exception("User not logged in");

//     final now = DateTime.now();
//     late DateTime start;
//     late int days;
//     List<String> labels = [];

//     // Set time range based on period
//     if (period == 'Daily') {
//       start = now.subtract(const Duration(days: 6));
//       days = 7;
//     } else if (period == 'Weekly') {
//       start = now.subtract(const Duration(days: 27));
//       days = 28;
//     } else if (period == 'Monthly') {
//       start = DateTime(now.year, now.month - 5, 1); // last 6 months
//       days = DateTime(now.year, now.month + 1, 0).difference(start).inDays;
//     } else {
//       throw Exception("Invalid period: $period");
//     }

//     final response = await supabase
//         .from('transactions')
//         .select('amount, transaction_type, created_at')
//         .eq('user_id', userId)
//         .gte('created_at', start.toIso8601String());

//     // Prepare buckets
//     Map<String, double> incomeMap = {};
//     Map<String, double> expenseMap = {};

//     for (var i = 0; i <= days; i++) {
//       final date = start.add(Duration(days: i));
//       final label = _formatLabel(period, date);
//       labels.add(label);
//       incomeMap[label] = 0.0;
//       expenseMap[label] = 0.0;
//     }

//     for (final tx in response) {
//       final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
//       final type = tx['transaction_type'] ?? '';
//       final createdAt = DateTime.parse(tx['created_at']);
//       final label = _formatLabel(period, createdAt);

//       if (incomeMap.containsKey(label)) {
//         if (type == 'Income') {
//           incomeMap[label] = incomeMap[label]! + amount;
//         } else if (type == 'Expense') {
//           expenseMap[label] = expenseMap[label]! + amount;
//         }
//       }
//     }

//     // 🔹 Category Spending Only for Daily Period
//     List<Map<String, dynamic>> categoryData = [];

//     if (period == 'Daily') {
//       final categoryResponse = await supabase
//           .from('transactions')
//           .select('amount, transaction_type, created_at, categories(category_name)')
//           .eq('user_id', userId)
//           .gte('created_at', start.toIso8601String());

//       final Map<String, double> categoryMap = {};

//       for (final tx in categoryResponse) {
//         final category = tx['categories']?['category_name'] ?? 'Uncategorized';
//         final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
//         final type = tx['transaction_type'] ?? '';

//         if (type == 'Expense') {
//           categoryMap[category] = (categoryMap[category] ?? 0.0) + amount;
//         }
//       }

//       categoryData = categoryMap.entries.map((e) => {
//         'name': e.key,
//         'amount': e.value,
//         'color': _assignColorForCategory(e.key),
//       }).toList();
//     }

//     return {
//       'income': labels.map((label) => incomeMap[label] ?? 0.0).toList(),
//       'expense': labels.map((label) => expenseMap[label] ?? 0.0).toList(),
//       'labels': labels,
//       'categories': categoryData,
//     };
//   }

//   String _formatLabel(String period, DateTime date) {
//     if (period == 'Daily') {
//       return DateFormat.E().format(date); // Mon, Tue
//     } else if (period == 'Weekly') {
//       final weekStart = date.subtract(Duration(days: date.weekday - 1));
//       return 'Wk ${DateFormat.Md().format(weekStart)}';
//     } else if (period == 'Monthly') {
//       return DateFormat.MMM().format(date); // Jan, Feb, etc.
//     }
//     return '';
//   }

  String _assignColorForCategory(String name) {
    const colors = {
      'Food': '#FF7043',
      'Education': '#42A5F5',
      'Entertainment': '#AB47BC',
      'Health': '#26A69A',
      'Transportation': '#FFA726',
      'Fashion': '#EC407A',
      'Lifestyle': '#66BB6A',
    };
    return colors[name] ?? '#9E9E9E'; // gray fallback
  }
}

