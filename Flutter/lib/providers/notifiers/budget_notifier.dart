import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../screens/Categories/models/budget_model.dart';

class BudgetNotifier extends StateNotifier<AsyncValue<List<Budget>>> {
  BudgetNotifier() : super(const AsyncLoading());

  Future<void> fetchBudgets(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('budgets')
          .select('*, categories(*)')
          .eq('user_id', userId);
          
      final budgets = response.map<Budget>((row) {
        return Budget.fromMap({
          ...row,
          'categoryMap': row['categories'] ?? {},
        });
      }).toList();

      state = AsyncValue.data(budgets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh(String userId) async {
    state = const AsyncLoading(); // Show loading indicator
    await fetchBudgets(userId);
  }
}
