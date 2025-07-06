import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Categories/models/goal_model.dart';

class GoalRepository {
  final supabase = Supabase.instance.client;

  Future<List<Goal>> fetchGoals() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await supabase
        .from('goals')
        .select()
        .eq('user_id', userId)
        .order('created_at');

    return response.map((goal) {
      return Goal(
        name: goal['goal_name'] ?? '',
        savedAmount: (goal['amount_saved'] as num?)?.toDouble() ?? 0.0,
        targetAmount: (goal['target_amount'] as num?)?.toDouble() ?? 0.0,
        goalIcon: _assignGoalIcon(goal['goal_name']),
      );
    }).toList();
  }

  IconData _assignGoalIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('vehicle')) return Icons.directions_car;
    if (n.contains('travel')) return Icons.flight;
    if (n.contains('emergency')) return Icons.medical_services;
    if (n.contains('house')) return Icons.home;
    if (n.contains('wedding')) return Icons.favorite_outline_rounded;
    if (n.contains('mobile') || n.contains('phone')) return Icons.phone_android;
    return Icons.flag;
  }
}

    