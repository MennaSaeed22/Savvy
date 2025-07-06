import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:savvy/screens/Categories/models/budget_model.dart';

abstract class BudgetStorage {
  static Future<void> save(String categoryId, double budget) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');
    final existing = await Supabase.instance.client
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .eq('category_id', categoryId)
        .maybeSingle();
    if (existing == null) {
      await Supabase.instance.client.from('budgets').insert({
        'user_id': userId,
        'category_id': categoryId,
        'allocated_amount': budget,
      });
    } else {
      await Supabase.instance.client.from('budgets')
        .update({'allocated_amount': budget})
        .eq('user_id', userId)
        .eq('category_id', categoryId);
    }
  }

  static Future<Budget?> load(String categoryId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');
    final result = await Supabase.instance.client
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .eq('category_id', categoryId)
        .maybeSingle();
    if (result == null) return null;
    return Budget.fromMap(result);
  }
}
