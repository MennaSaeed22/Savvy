import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../globals.dart';
import '../../widgets/app_header.dart';
import '../../utils/transaction_utils.dart';
import '../../providers/app_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    // Fetch transactions with categories when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionProvider.notifier).fetchTransactionsWithCategories();
    });
  }

  BoxDecoration cardDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected ? softBlue : OffWhite,
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
    );
  }

  // Helper function to format large numbers
  String formatAmount(double amount) {
    if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(1)}M";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(1)}K";
    } else {
      return amount.toStringAsFixed(1);
    }
  }

  Widget _buildIncomeExpenseCard(
      IconData icon, String title, String amount, bool isSelected) {
    final textColor = secondaryColor;
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              color: textColor,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Consumer(
      builder: (context, ref, child) {
        final financialSummaryAsync = ref.watch(financialSummaryProvider);
        
        return financialSummaryAsync.when(
          data: (summary) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Total Balance Card
                GestureDetector(
                  onTap: () => setState(() => selectedFilter = 'all'),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 300,
                      maxWidth: 650,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: cardDecoration(selectedFilter == 'all'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Total Balance",
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "${formatAmount(summary.balance)} EGP",
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Income and Expense Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Income Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedFilter = 'income'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            margin: const EdgeInsets.only(right: 5),
                            decoration: cardDecoration(selectedFilter == 'income'),
                            child: _buildIncomeExpenseCard(
                              Icons.arrow_upward,
                              "Income",
                              "${formatAmount(summary.totalIncome)} EGP",
                              selectedFilter == 'income',
                            ),
                          ),
                        ),
                      ),
                      // Expense Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedFilter = 'expense'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            margin: const EdgeInsets.only(left: 5),
                            decoration: cardDecoration(selectedFilter == 'expense'),
                            child: _buildIncomeExpenseCard(
                              Icons.arrow_downward,
                              "Expenses",
                              "${formatAmount(summary.totalExpenses)} EGP",
                              selectedFilter == 'expense',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 110),
                decoration: cardDecoration(false),
                child: const CircularProgressIndicator(),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    margin: const EdgeInsets.only(right: 10),
                    decoration: cardDecoration(false),
                    child: const CircularProgressIndicator(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                    decoration: cardDecoration(false),
                    child: const CircularProgressIndicator(),
                  ),
                ],
              ),
            ],
          ),
          error: (error, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 110),
                decoration: cardDecoration(false),
                child: Column(
                  children: [
                    Text("Total Balance",
                        style: TextStyle(
                            color: secondaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text("Error loading",
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text("Error: $error", style: const TextStyle(color: Colors.red)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 60,right: 10),
        child: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/history'),
          backgroundColor: primaryColor,
          child: const Icon(Icons.history, color: OffWhite),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const AppHeader(title: "Transactions", arrowVisible: false),
            const SizedBox(height: 10),
            // Summary Cards
            _buildSummaryCards(),
            const SizedBox(height: 10),
            // Transactions List
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: OffWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    // Using the correct provider from your notifier
                    final transactionAsyncValue = ref.watch(transactionProvider);
                    return transactionAsyncValue.when(
                      data: (transactions) {
                        if (transactions.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text("No transactions available",
                                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                              ],
                            ),
                          );
                        }
                        
                        // Sort transactions by created_at (most recent first)
                        final sortedTransactions = List<Map<String, dynamic>>.from(transactions);
                        sortedTransactions.sort((a, b) =>
                            DateTime.parse(b["created_at"])
                                .compareTo(DateTime.parse(a["created_at"])));
                        
                        // Apply filtering
                        List<Map<String, dynamic>> filteredTransactions;
                        switch (selectedFilter) {
                          case 'income':
                            filteredTransactions = sortedTransactions
                                .where((transaction) => transaction['transaction_type'] == 'Income')
                                .toList();
                            break;
                          case 'expense':
                            filteredTransactions = sortedTransactions
                                .where((transaction) => transaction['transaction_type'] == 'Expense')
                                .toList();
                            break;
                          default:
                            filteredTransactions = sortedTransactions;
                        }
                        
                        // Limit to the most recent 4 transactions
                        final limitedTransactions = filteredTransactions.take(4).toList();
                        
                        if (limitedTransactions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(Icons.filter_list, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text("No ${selectedFilter == 'all' ? '' : selectedFilter} transactions",
                                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: limitedTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = limitedTransactions[index];
                            final isIncome = transaction['transaction_type'] == 'Income';
                            
                            // Handle category data structure based on your notifier's fetchTransactionsWithCategories method
                            String categoryName = 'Unknown';
                            if (transaction['categories'] != null) {
                              if (transaction['categories'] is Map) {
                                // Single category object with name field
                                categoryName = transaction['categories']['category_name'] ?? 'Unknown';
                              } else if (transaction['categories'] is List && transaction['categories'].isNotEmpty) {
                                // Array of category objects
                                categoryName = transaction['categories'][0]['category_name'] ?? 'Unknown';
                              }
                            }
                            
                            final amount = transaction['amount']?.toString() ?? '0';
                            final description = transaction['description'] ?? '';
                            final date = transaction['created_at'] ?? '';
                            
                            // Format date to show only date part
                            String formattedDate = '';
                            try {
                              final parsedDate = DateTime.parse(date);
                              formattedDate = "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
                            } catch (e) {
                              formattedDate = date.split('T')[0]; // Fallback to simple split
                            }
                            
                            // Format the amount for display in transaction list
                            final double amountValue = double.tryParse(amount) ?? 0.0;
                            final String formattedAmount = formatAmount(amountValue);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Colors.white,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.grey.shade50,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: primaryColor,
                                    child: Icon(
                                      TransactionUtils.getCategoryIcon(
                                        categoryName,
                                        description,
                                        isIncome: isIncome,
                                      ),
                                      color: OffWhite,
                                    ),
                                  ),
                                  title: Text(
                                    description.isNotEmpty ? description : categoryName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    "$formattedDate • $categoryName",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "${isIncome ? '+' : '-'}$formattedAmount EGP",
                                      style: TextStyle(
                                        color: isIncome ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text("Error loading transactions",
                                style: TextStyle(fontSize: 16, color: Colors.red)),
                            const SizedBox(height: 8),
                            Text("$error", 
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(transactionProvider.notifier).fetchTransactionsWithCategories(),
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}