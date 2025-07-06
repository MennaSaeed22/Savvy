import 'package:flutter/material.dart';
import 'package:savvy/screens/Categories/savings/constants/predefined_goals.dart';
// import 'package:savvy/screens/Categories/savings/savings_goals_screen.dart';

class Goal {
  final String? goalId;
  String name;
  final IconData? goalIcon;
  double savedAmount;
  double targetAmount;
  String? description;
  final DateTime createdDate;
  List<Deposit> deposits;
  String category;

  Goal({
    this.goalId,
    required this.name,
    this.goalIcon,
    this.savedAmount = 0.0,
    required this.targetAmount,
    this.description,
    DateTime? createdDate,
    List<Deposit>? deposits,
    this.category = 'Other', //!!!!!!/
  })  : createdDate = createdDate ?? DateTime.now(),
        deposits = deposits ?? [];
        
// Calculate the percentage of progress in the goal target
// progressPercentage Getter
  double get progressPercentage =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
// Adds a new deposit to the goal
// Updates both the deposits list and the total savedAmount
  void addDeposit(Deposit deposit) {
    deposits.add(deposit);
    savedAmount += deposit.amount;
  }

  Map<String, dynamic> toJson() {
    return {
      'goal_name': name, // UPDATED
      'goal_id': goalId, // optional if updating
      'amount_saved': savedAmount,
      'target_amount': targetAmount,
      'amount_saved': savedAmount,
      'created_at': createdDate.toIso8601String(),
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      name: json['goal_name'],
      goalId: json['goal_id'], // optional if updating
      savedAmount: (json['amount_saved'] as num?)?.toDouble() ?? 0.0,
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0.0,
      createdDate: DateTime.parse(json['created_at']),   
    );
  }

  @override
  String toString() {
    return 'Goal(goalId: $goalId, name: $name, savedAmount: $savedAmount, targetAmount: $targetAmount, createdDate: $createdDate, category: $category)';
  }

  Goal copyWith({IconData? goalIcon}) {
    return Goal(
      goalId: goalId,
      name: name,
      goalIcon: goalIcon ?? this.goalIcon,
      savedAmount: savedAmount,
      targetAmount: targetAmount,
      description: description,
      createdDate: createdDate,
      deposits: List.from(deposits),
      category: category,
    );
  }
}

class Deposit {
  final DateTime dateTime;
  final double amount;
  final String? note;
  Deposit({
    required this.dateTime,
    required this.amount,
    this.note,
  });
// Convert Deposit object to JSON
  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'amount': amount,
      'note': note,
    };
  }

// Create Deposit object from JSON
  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      dateTime: DateTime.parse(json['dateTime']),
      amount: json['amount'],
      note: json['note'],
    );
  }

  ///. Match icon for display (icon not saved in DB)
// Since you're not saving the icon, you can use this helper when displaying a user goal:
  IconData getIconForGoalName(String name) {
    return predefinedGoals
            .firstWhere(
              (g) => g.name == name,
              orElse: () =>
                  Goal(name: name, goalIcon: Icons.flag, targetAmount: 0),
            )
            .goalIcon ??
        Icons.flag;
  }
}
