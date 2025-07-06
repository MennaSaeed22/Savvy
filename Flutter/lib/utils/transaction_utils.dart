import 'package:flutter/material.dart';

// Utility class for transaction-related operations
class TransactionUtils {

  static IconData getCategoryIcon(String categoryName, String fallback, {bool isIncome = false}) {
    // Add your category icon mapping logic here
    switch (categoryName.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'fashion':
        return Icons.checkroom;
      case 'health':
        return Icons.health_and_safety;
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'lifestyle':
        return Icons.emoji_people;
      case 'education':
        return Icons.school;
      case 'salary':
        return Icons.business_center;
      case 'freelance':
        return Icons.computer;
      case 'investments':
        return Icons.trending_up;
      case 'bonus':
        return Icons.star;
      case 'refunds':
        return Icons.request_quote;
      default:
        return isIncome ? Icons.arrow_upward : Icons.arrow_downward;
    }
  }

  // Helper method to format currency
  static String formatCurrency(double amount) {
    return "\$${amount.toStringAsFixed(2)}";
  }

  // Helper method to format date
  static String formatDate(String dateString) {
    try {
      final parsedDate = DateTime.parse(dateString);
      return "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString.split('T')[0]; // Fallback to simple split
    }
  }

  // Helper method to get transaction color
  static Color getTransactionColor(String transactionType) {
    return transactionType == 'Income' ? Colors.green : Colors.red;
  }

  // Helper method to get transaction prefix
  static String getTransactionPrefix(String transactionType) {
    return transactionType == 'Income' ? '+' : '-';
  }
}