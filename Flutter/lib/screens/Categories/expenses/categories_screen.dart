import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../globals.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../savings/savings_goals_screen.dart';
import 'categoryDetails.dart';
import 'package:savvy/screens/Categories/expenses/constants/categories_list.dart';
import '../../../providers/app_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final List<Category> categories = globalCategories;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    
    return Scaffold(
      backgroundColor: primaryColor,
      body: transactionsAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: Colors.white),
          ),
        ),
        data: (transactionsData) {
          final List<TransactionModel> expensesList = [];
          for (var item in transactionsData) {
            try {
              if (item != null) {
                expensesList.add(TransactionModel.fromMap(item));
              }
            } catch (e) {
              print('Error parsing transaction: $e');
            }
          }
          return Column(
            children: [
              const SizedBox(height: 70),
              const _ScreenTitle(),
              const SizedBox(height: 30),
              Expanded(
                child: _MainContent(
                  categories: categories,
                  expenses: expensesList,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Categories",
        style: TextStyle(
          color: OffWhite,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  final List<Category> categories;
  final List<TransactionModel> expenses;

  const _MainContent({
    required this.categories,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = categories.length + 1; // +1 for Income
    return Container(
      decoration: const BoxDecoration(
        color: OffWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: totalItems,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 20,
          ),
          itemBuilder: (context, index) {
            if (index == totalItems - 1) {
              // Income item
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/income'); 
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: softBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.attach_money, size: 36, color: primaryColor),
                      SizedBox(height: 8),
                      Text(
                        'Income',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Regular category tile
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                if (category.type == CategoryType.savings) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SavingsGoalsScreen()),
                  );
                } else {
                  final totalSpent = filterByCurrentMonth(expenses)
                      .where((e) => e.categoryId == category.id)
                      .fold(0.0, (sum, e) => sum + e.amount);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryDetailScreen(
                        categoryId: category.id,
                        categoryName: category.name,
                        categoryIcon: category.icon,
                        totalSpent: totalSpent,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: softBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(category.icon, size: 36, color: primaryColor),
                    const SizedBox(height: 8),
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

List<TransactionModel> filterByCurrentMonth(List<TransactionModel> records) {
  final now = DateTime.now();
  return records.where((record) {
    final date = record.createdAt;
    return date.month == now.month && date.year == now.year;
  }).toList();
}
