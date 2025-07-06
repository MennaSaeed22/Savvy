import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_provider.dart';
import '../globals.dart';
import '../../widgets/app_header.dart';
import '../../utils/transaction_utils.dart';
import 'package:intl/intl.dart';
import 'edit_transaction_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final String? categoryFilter;

  const HistoryScreen({Key? key, this.categoryFilter}) : super(key: key);

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredTransactions = [];
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTransactions(
      String query, List<Map<String, dynamic>> allTransactions) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTransactions = _applyFilters(allTransactions);
      } else {
        final searchFiltered = allTransactions.where((transaction) {
          final categoryName =
              transaction['categories']?['category_name']?.toLowerCase() ?? '';
          final transactionType =
              transaction['transaction_type']?.toLowerCase() ?? '';
          final amount = transaction['amount']?.toString() ?? '';

          return categoryName.contains(query.toLowerCase()) ||
              transactionType.contains(query.toLowerCase()) ||
              amount.contains(query.toLowerCase());
        }).toList();

        _filteredTransactions = _applyFilters(searchFiltered);
      }
    });
  }

  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> transactions) {
    // Apply category filter if provided
    if (widget.categoryFilter != null) {
      return transactions
          .where((tx) =>
              tx['categories']?['category_name'] == widget.categoryFilter)
          .toList();
    }
    return transactions;
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByMonth(
      List<Map<String, dynamic>> transactions) {
    final Map<String, List<Map<String, dynamic>>> groupedTransactions = {};

    for (var transaction in transactions) {
      try {
        final dateString = transaction["created_at"] ?? '';
        final date = DateTime.parse(dateString);
        final monthYear = DateFormat('MMMM yyyy').format(date);

        if (!groupedTransactions.containsKey(monthYear)) {
          groupedTransactions[monthYear] = [];
        }
        groupedTransactions[monthYear]!.add(transaction);
      } catch (e) {
        // Skip transactions with invalid dates
        continue;
      }
    }
    return groupedTransactions;
  }

  void _showDeleteConfirmation(
      BuildContext context, Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: OffWhite,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Delete Transaction",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: secondaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Are you sure you want to delete this transaction?",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: softBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildTransactionDetail(
                          "Category",
                          transaction['categories']?['category_name'] ??
                              'Unknown'),
                      const SizedBox(height: 8),
                      _buildTransactionDetail("Amount",
                          "${transaction['amount']?.toString() ?? '0'} EGP"),
                      const SizedBox(height: 8),
                      _buildTransactionDetail(
                          "Type", transaction['transaction_type'] ?? 'Unknown'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: secondaryColor,
                        backgroundColor: softBlue,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteTransaction(transaction);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: OffWhite,
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteTransaction(Map<String, dynamic> transaction) {
    // Use the correct provider name
    final transactionId = transaction['transaction_id'];
    if (transactionId != null) {
      ref
          .read(transactionProvider.notifier)
          .deleteTransaction(transactionId, ref);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _navigateToTransactionDetails(Map<String, dynamic> transaction) {
    // Navigate to transaction details/edit page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TransactionDetailsScreen(transaction: transaction),
      ),
    );
  }

  Widget _buildTransactionDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: secondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: secondaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionAsyncValue = ref.watch(transactionProvider);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: primaryColor,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              AppHeader(
                  title: widget.categoryFilter != null
                      ? '${widget.categoryFilter} History'
                      : 'Transactions History',
                  arrowVisible: true),
              const SizedBox(height: 10),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (query) {
                    transactionAsyncValue.whenData((transactions) {
                      _filterTransactions(query, transactions);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search transactions...",
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                  child: transactionAsyncValue.when(
                    data: (transactions) {
                      // Initialize filtered transactions if needed
                      if (_filteredTransactions.isEmpty &&
                          _searchQuery.isEmpty) {
                        _filteredTransactions = _applyFilters(transactions);
                      }

                      final transactionsToShow = _searchQuery.isEmpty
                          ? _applyFilters(transactions)
                          : _filteredTransactions;

                      if (transactionsToShow.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? "No transactions found for '$_searchQuery'"
                                    : widget.categoryFilter != null
                                        ? "No transactions found for ${widget.categoryFilter}"
                                        : "No transactions available",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      // Sort transactions by date (most recent first)
                      final sortedTransactions =
                          List<Map<String, dynamic>>.from(transactionsToShow);
                      sortedTransactions.sort((a, b) {
                        try {
                          return DateTime.parse(b["created_at"])
                              .compareTo(DateTime.parse(a["created_at"]));
                        } catch (e) {
                          return 0;
                        }
                      });

                      // Group transactions by month
                      final groupedTransactions =
                          _groupTransactionsByMonth(sortedTransactions);

                      // Sort months in descending order
                      final sortedMonths = groupedTransactions.keys.toList()
                        ..sort((a, b) {
                          try {
                            return DateFormat('MMMM yyyy')
                                .parse(b)
                                .compareTo(DateFormat('MMMM yyyy').parse(a));
                          } catch (e) {
                            return 0;
                          }
                        });

                      return SingleChildScrollView(
                        child: Column(
                          children: sortedMonths.map((monthYear) {
                            final monthTransactions =
                                groupedTransactions[monthYear]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Month Header
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Text(
                                    monthYear,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ),
                                // Transactions for the Month
                                ...monthTransactions.map((transaction) {
                                  final isIncome =
                                      transaction["transaction_type"] ==
                                          "Income";
                                  final categoryName = transaction['categories']
                                          ?['category_name'] ??
                                      'Unknown';
                                  final amount =
                                      transaction['amount']?.toString() ?? '0';
                                  final createdAt =
                                      transaction['created_at'] ?? '';
                                  // Format date
                                  String formattedDate = '';
                                  try {
                                    final parsedDate =
                                        DateTime.parse(createdAt);
                                    formattedDate = DateFormat('MMM dd, yyyy')
                                        .format(parsedDate);
                                  } catch (e) {
                                    formattedDate = createdAt.split('T')[0];
                                  }
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    child: InkWell(
                                      onTap: () =>
                                          _navigateToTransactionDetails(
                                              transaction),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 4.0),
                                        child: Row(
                                          children: [
                                            // Delete Button
                                            GestureDetector(
                                              onTap: () =>
                                                  _showDeleteConfirmation(
                                                      context, transaction),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.red
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Transaction Icon
                                            CircleAvatar(
                                              backgroundColor: primaryColor,
                                              child: Icon(
                                                TransactionUtils
                                                    .getCategoryIcon(
                                                  categoryName,
                                                  categoryName,
                                                  isIncome: isIncome,
                                                ),
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Transaction Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    categoryName,
                                                    softWrap: true,
                                                    overflow:
                                                        TextOverflow.visible,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    "$formattedDate · ${transaction["transaction_type"]}",
                                                    softWrap: true,
                                                    overflow:
                                                        TextOverflow.visible,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Amount
                                            Text(
                                              "${isIncome ? '+' : '-'}$amount EGP",
                                              style: TextStyle(
                                                color: isIncome
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Edit Arrow
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color: Colors.grey[400],
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 10),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Error loading transactions",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
