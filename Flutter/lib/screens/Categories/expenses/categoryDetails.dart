import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savvy/screens/Categories/services/budgetStorage.dart';
import '../../globals.dart';
import 'add_expense_screen.dart';
import '../models/transaction_model.dart';
import '../../../providers/app_provider.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;
  final IconData categoryIcon;
  final double totalSpent;

  const CategoryDetailScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.totalSpent,
  }) : super(key: key);

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  double? _budget;
  bool _isLoading = false;
  double _currentTotalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _currentTotalSpent = widget.totalSpent;
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    setState(() => _isLoading = true);
    try {
      final loadedBudget = await BudgetStorage.load(widget.categoryId);
      setState(() => _budget = loadedBudget?.amount);
    } catch (e) {
      // Handle error if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load budget data')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotalSpent(List<TransactionModel> expenses) {
    final total = filterByCurrentMonth(expenses)
        .where((e) => e.categoryId == widget.categoryId)
        .fold(0.0, (sum, e) => sum + e.amount);
    
    if (_currentTotalSpent != total) {
      setState(() {
        _currentTotalSpent = total;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadBudget();
    // Refresh transactions to get updated total spent
    ref.refresh(transactionProvider);
    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _saveBudget(double budget) async {
    await BudgetStorage.save(widget.categoryId, budget);
    setState(() => _budget = budget);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget saved')),
    );
  }

  void _showBudgetDialog() {
    final TextEditingController budgetController = TextEditingController(
      text: _budget?.toStringAsFixed(2) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OffWhite,
        title: Text(
          "Set Budget for ${widget.categoryName}",
          style: const TextStyle(color: primaryColor),
        ),
        content: TextField(
          controller: budgetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: "Enter budget amount"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final enteredBudget = double.tryParse(budgetController.text);
              if (enteredBudget == null || enteredBudget <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enter a valid budget")),
                );
                return;
              }
              _saveBudget(enteredBudget);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OffWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(color: OffWhite, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (transactionsData) {
          // Parse transactions and calculate current total spent
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
          
          // Update total spent based on current data
          _calculateTotalSpent(expensesList);
          
          final double spentRatio = (_budget != null && _budget! > 0) 
              ? _currentTotalSpent / _budget! 
              : 0;

          return Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: OffWhite,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.categoryIcon, size: 60, color: primaryColor),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: OffWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    color: primaryColor,
                    backgroundColor: OffWhite,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                const Text("Total Spent",
                                    style: TextStyle(color: Colors.black54, fontSize: 16)),
                                const SizedBox(height: 5),
                                Text("EGP ${_currentTotalSpent.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        fontSize: 28, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Budget",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: primaryColor,
                                      ),
                                    )
                                  : Text(
                                      _budget != null
                                          ? "EGP ${_budget!.toStringAsFixed(2)}"
                                          : "No budget set",
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ],
                          ),
                          if (_budget != null && !_isLoading) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: spentRatio.clamp(0.0, 1.0),
                              color: _currentTotalSpent > _budget!
                                  ? Colors.red
                                  : (spentRatio >= 0.9
                                      ? const Color.fromARGB(255, 255, 77, 0)
                                      : Colors.green),
                              backgroundColor: Colors.grey.shade300,
                              minHeight: 6,
                            ),
                            const SizedBox(height: 6),
                            Text("${(spentRatio * 100).toStringAsFixed(1)}% of budget",
                                style: TextStyle(
                                  color: _currentTotalSpent > _budget!
                                      ? Colors.red
                                      : (spentRatio >= 0.9
                                          ? const Color.fromARGB(255, 255, 77, 0)
                                          : Colors.black87),
                                )),
                            if (spentRatio >= 0.9 && _currentTotalSpent <= _budget!)
                              const Text("You are close to reaching your budget!",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 255, 77, 0),
                                      fontWeight: FontWeight.bold)),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _showBudgetDialog,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: primaryColor),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text("Set Budget",
                                  style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddExpenseScreen(
                                      initialCategory: widget.categoryId,
                                    ),
                                  ),
                                );
                                
                                // Refresh data when returning from add expense screen
                                if (result == true) {
                                  _refreshData();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text("Add Expense",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: OffWhite)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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