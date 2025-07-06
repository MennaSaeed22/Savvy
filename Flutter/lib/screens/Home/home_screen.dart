import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/app_header.dart';
import '../Analytics/presentation/analyticsScreen.dart';
import '../Categories/expenses/categories_screen.dart';
import '../Profile/profile_screen.dart';
import '../Transactions/transactions_screen.dart';
import '../../widgets/CustomNavBar.dart';
import '../globals.dart';
import 'chatbot_screen.dart';
import '../../providers/app_provider.dart';
import '../../utils/finance_summary.dart';

class HomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if ((index - _pageController.page!).abs() > 1) {
        _pageController.jumpToPage(index);
      } else {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

String _formatAmount(double amount) {
  bool isNegative = amount < 0;
  double absAmount = amount.abs();
  String prefix = isNegative ? '-' : '';
  if (absAmount >= 1000000) {
    int millions = (absAmount / 1000000).floor();
    return '$prefix${millions}M';
  } else if (absAmount >= 1000) {
    int thousands = (absAmount / 1000).floor();
    return '$prefix${thousands}K';
  } else {
    return '$prefix${absAmount.floor()}';
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: [
              _buildHomeScreenContent(context),
              AnalyticsScreen(),
              TransactionsScreen(),
              CategoriesScreen(),
              ProfileScreen(),
            ],
          ),
          CustomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreenContent(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final transactionsAsync = ref.watch(transactionProvider);
    final financialSummaryAsync = ref.watch(financialSummaryProvider);

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 20),
          AppHeader(title: "Home", arrowVisible: false),
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    userAsync.when(
                      data: (userData) {
                        final fullName = userData?['full_name'] ?? 'User';
                        return Text(
                          "Welcome, $fullName",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                          ),
                        );
                      },
                      loading: () => _buildPlaceholderText("Welcome"),
                      error: (error, stack) => _buildPlaceholderText("Welcome"),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Quick summary of this month's finances",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 15),
                    transactionsAsync.when(
                      data: (transactions) {
                        final monthlySummary =
                            FinanceSummary.calculateMonthlySummary(
                                transactions);
                        final userId =
                            Supabase.instance.client.auth.currentUser?.id ?? '';
                        final forecastAsync =
                            ref.watch(forecastProvider(userId));
                        return financialSummaryAsync.when(
                          data: (summary) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSummaryCard(
                                      title: "Balance",
                                      amount:
                                          "${_formatAmount(summary.balance)} EGP",
                                      icon: Icons.account_balance_wallet,
                                      color: summary.balance >= 0
                                          ? Colors.blue
                                          : Colors.red,
                                    ),
                                    _buildSummaryCard(
                                      title: "Income",
                                      amount:
                                          "${_formatAmount(monthlySummary['income'] ?? 0.0)} EGP",
                                      icon: Icons.arrow_upward,
                                      color: Colors.green,
                                    ),
                                    _buildSummaryCard(
                                      title: "Expenses",
                                      amount:
                                          "${_formatAmount(monthlySummary['expenses'] ?? 0.0)} EGP",
                                      icon: Icons.arrow_downward,
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                forecastAsync.when(
                                  data: (forecast) {
                                    if (forecast == null) {
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.yellow.shade100,
                                          border: Border.all(
                                              color: Colors.yellow.shade700),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline,
                                                color: Colors.orange.shade800),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                "Start tracking your expenses to get monthly spending predictions and insights!",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.orange.shade800,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    final predicted =
                                        forecast['predicted_total_expense']
                                                ?.toDouble() ??
                                            0.0;
                                    final real =
                                        monthlySummary['expenses'] ?? 0.0;
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        border: Border.all(
                                            color: Colors.blue.shade200),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "📊 Expense Insight",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue.shade900,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "This month's predicted expenses: ${predicted.toStringAsFixed(1)} EGP",
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                          Text(
                                            "This month's current expenses: ${real.toStringAsFixed(1)} EGP",
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(height: 4),
                                          Center(
                                            child: Text(
                                              predicted < real
                                                  ? "⚠️ Your expenses may increase. Consider adjusting your budget."
                                                  : "✅ You're expected to spend less this month.",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: predicted < real
                                                    ? Colors.red
                                                    : Colors.green,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                  loading: () => const Center(
                                      child: CircularProgressIndicator()),
                                  error: (err, _) {
                                    // Print to debug
                                    debugPrint("Forecast error: $err");
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        border: Border.all(
                                            color: Colors.red.shade200),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline,
                                              color: Colors.red),
                                          const SizedBox(width: 10),
                                          const Expanded(
                                            child: Text(
                                              "Something went wrong while loading your forecast. Please try again later.",
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) =>
                              Text("Error loading summary"),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) =>
                          Text("Error loading transactions"),
                    ),
                    const SizedBox(height: 20),
                    Text("Quick Actions",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildQuickActionButton(
                          title: "Add Income",
                          icon: Icons.add_circle,
                          color: Colors.green,
                          onTap: () => Navigator.pushNamed(context, '/income'),
                        ),
                        _buildQuickActionButton(
                          title: "Add Expense",
                          icon: Icons.remove_circle,
                          color: Colors.red,
                          onTap: () =>
                              Navigator.pushNamed(context, '/expenses'),
                        ),
                        _buildQuickActionButton(
                          title: "View Reports",
                          icon: Icons.bar_chart,
                          color: Colors.blue,
                          onTap: () {
                            setState(() {
                              _selectedIndex = 1;
                              _pageController.jumpToPage(1);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 400,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: softBlue.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: softBlue, width: 1.5),
                      ),
                      child: Text(
                        "💬 Use the chatbot to easily perform actions like adding income or expenses. Get insights and advice to achieve your financial goals!",
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey[800],
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ChatbotScreen())),
                          child: Container(
                            width: 70,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: softBlue,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.withOpacity(0.4),
                                    blurRadius: 10.0,
                                    offset: Offset(0, 4))
                              ],
                            ),
                            child: Icon(Icons.chat_outlined,
                                color: secondaryColor, size: 28),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Image.asset('assets/animation/robot.gif',
                            width: 150, height: 150, fit: BoxFit.fill),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderText(String text) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w600, color: secondaryColor),
    );
  }

  Widget _buildSummaryCard(
      {required String title,
      required String amount,
      required IconData icon,
      required Color color}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(amount,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 28)),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ],
      ),
    );
  }
}