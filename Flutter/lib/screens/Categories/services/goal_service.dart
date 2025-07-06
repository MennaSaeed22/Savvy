import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/goal_model.dart';

class GoalService {
  final _client = Supabase.instance.client;

  /// Fetch all goals for the current user
  Future<List<Goal>> fetchGoals() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');
    final response = await _client.from('goals').select().eq('user_id', userId);
    return (response as List)
        .map((item) => Goal.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Save a new or updated goal
  Future<void> saveGoal(Goal goal) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

      log('Updating existing goal: ${goal.name}', name: 'GoalService.saveGoal');
      await _client.from('goals').upsert({
        'goal_id': goal.goalId, // optional if updating
        'user_id': userId,
        'goal_name': goal.name,
        'amount_saved': goal.savedAmount,
        'target_amount': goal.targetAmount,
        'created_at': goal.createdDate.toIso8601String(),
      }).eq('goal_id', goal.goalId!);
    // }
    log('Goal saved successfully', name: 'GoalService.saveGoal');
  }

  /// Delete a goal from database
  Future<void> deleteGoal(String goalName) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _client
        .from('goals')
        .delete()
        .match({'user_id': userId, 'goal_name': goalName});
  }
}

