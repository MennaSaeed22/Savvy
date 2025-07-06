import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savvy/providers/app_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Updated model to match actual schema
class TransactionData {
  final String transactionId;
  final String transactionType;
  final double amount;
  final String createdAt;
  final String? description;
  final String? categoryId;

  TransactionData({
    required this.transactionId,
    required this.transactionType,
    required this.amount,
    required this.createdAt,
    this.description,
    this.categoryId,
  });

  factory TransactionData.fromMap(Map<String, dynamic> map) {
    return TransactionData(
      transactionId: map['transaction_id'] ?? '',
      transactionType: map['transaction_type'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      createdAt: map['created_at'] ?? '',
      description: map['description'],
      categoryId: map['category_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'transaction_type': transactionType,
      'amount': amount,
      'created_at': createdAt,
      'description': description,
      'category_id': categoryId,
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'transaction_type': transactionType,
      'amount': amount,
      'created_at': createdAt,
      'description': description,
      'category_id': categoryId,
    };
  }
}

class TransactionNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  TransactionNotifier() : super(const AsyncValue.loading());

  Future<void> fetchTransactions() async {
    // Always use fetchTransactionsWithCategories instead of basic fetch
    await fetchTransactionsWithCategories();
  }

  Future<void> fetchTransactionsWithCategories() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("User not logged in");
      }

      // Always fetch with category information
      final response = await supabase
          .from('transactions')
          .select('''
            transaction_id,
            user_id,
            category_id,
            description,
            created_at,
            amount,
            transaction_type,
            categories!category_id(
              category_id,
              category_name
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      state = AsyncValue.data(List<Map<String, dynamic>>.from(response as List<dynamic>? ?? []));
    } catch (e) {
      print('Error fetching transactions with categories: $e');
      // Fallback to basic fetch without categories if join fails
      try {
        final supabase = Supabase.instance.client;
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) {
          throw Exception("User not logged in");
        }

        final response = await supabase
            .from('transactions')
            .select('''
              transaction_id,
              user_id,
              category_id,
              description,
              created_at,
              amount,
              transaction_type
            ''')
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        // Manually fetch category names for transactions that have category_id
        List<Map<String, dynamic>> transactions = List<Map<String, dynamic>>.from(response as List<dynamic>? ?? []);
        
        for (var transaction in transactions) {
          if (transaction['category_id'] != null) {
            try {
              final categoryResponse = await supabase
                  .from('categories')
                  .select('category_id, category_name')
                  .eq('category_id', transaction['category_id'])
                  .single();
              
              transaction['categories'] = categoryResponse;
            } catch (categoryError) {
              // If category fetch fails, set a default
              transaction['categories'] = {
                'category_id': transaction['category_id'],
                'category_name': 'Unknown'
              };
            }
          } else {
            // No category assigned
            transaction['categories'] = null;
          }
        }

        state = AsyncValue.data(transactions);
        
      } catch (fallbackError) {
        state = AsyncValue.error(fallbackError, StackTrace.current);
      }
    }
  }

  void subscribeToUpdates() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId != null) {
      supabase.channel('transactions_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'transactions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              print('Transaction change detected: ${payload.eventType}');
              fetchTransactions();
            },
          )
          .subscribe();
    }
  }

  Future<void> refresh() async {
    await fetchTransactions();
  }

  Future<void> addTransaction(Map<String, dynamic> transactionData, WidgetRef ref) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("User not logged in");
      }

      if (transactionData['transaction_type'] == null) {
        throw Exception("Transaction type is required");
      }
      if (transactionData['amount'] == null) {
        throw Exception("Amount is required");
      }

      final dataWithUserId = {
        'user_id': userId,
        'transaction_type': transactionData['transaction_type'],
        'amount': transactionData['amount'],
        'created_at': transactionData['created_at'] ?? DateTime.now().toIso8601String(),
        'description': transactionData['description'],
        'category_id': transactionData['category_id'],
      };

      await supabase
          .from('transactions')
          .insert(dataWithUserId);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      await Future.wait([
        fetchTransactions(),
        ref.read(financialSummaryProvider.notifier).fetchFinancialSummary(),
      ]);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId, WidgetRef ref) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase
          .from('transactions')
          .delete()
          .eq('transaction_id', transactionId);
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      await Future.wait([
        fetchTransactions(),
        ref.read(financialSummaryProvider.notifier).fetchFinancialSummary(),
      ]);
      
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateTransaction(String transactionId, Map<String, dynamic> updatedData, WidgetRef ref) async {
    try {
      final supabase = Supabase.instance.client;
      
      final allowedFields = {
        'transaction_type',
        'amount', 
        'description',
        'category_id',
        'created_at'
      };
      
      final filteredData = Map<String, dynamic>.fromEntries(
        updatedData.entries.where((entry) => allowedFields.contains(entry.key))
      );
      
      if (filteredData.isEmpty) {
        throw Exception("No valid fields to update");
      }
      
      print('Updating transaction $transactionId with data: $filteredData');
      
      await supabase
          .from('transactions')
          .update(filteredData)
          .eq('transaction_id', transactionId);
      
      await Future.delayed(const Duration(milliseconds: 200)); // Slightly longer delay
      
      // Ensure we refresh with categories
      await Future.wait([
        fetchTransactionsWithCategories(), // Explicitly call with categories
        ref.read(financialSummaryProvider.notifier).fetchFinancialSummary(),
      ]);
      
      print('Transaction updated and providers refreshed');
    } catch (e) {
      print('Error updating transaction: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionsByCategory(String categoryId) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("User not logged in");
      }

      final response = await supabase
          .from('transactions')
          .select('''
            *,
            categories!category_id(
              category_id,
              category_name
            )
          ''')
          .eq('user_id', userId)
          .eq('category_id', categoryId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List<dynamic>? ?? []);
    } catch (e) {
      print('Error fetching transactions by category: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionsByType(String transactionType) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("User not logged in");
      }

      final response = await supabase
          .from('transactions')
          .select('''
            *,
            categories!category_id(
              category_id,
              category_name
            )
          ''')
          .eq('user_id', userId)
          .eq('transaction_type', transactionType)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List<dynamic>? ?? []);
    } catch (e) {
      print('Error fetching transactions by type: $e');
      return [];
    }
  }

  void clearCache() {
    state = const AsyncValue.data([]);
  }
}