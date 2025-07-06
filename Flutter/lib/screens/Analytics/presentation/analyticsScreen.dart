import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savvy/screens/Analytics/presentation/providers/analytics_provider.dart';
import 'package:savvy/screens/globals.dart';
import 'package:fl_chart/fl_chart.dart';
import '../presentation/widgets/summary_card.dart';
import '../presentation/widgets/charts/custom_bar_chart.dart';
import '../presentation/widgets/goal_progress_ring.dart';
import '../domain/models.dart';

class CategoryModel {
  final String categoryName;

  CategoryModel(this.categoryName);
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  final List<String> tabs = ['Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = tabs[_selectedTabIndex];
    final dataAsync = ref.watch(financialDataProvider(currentTab));

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Financial Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs.map((e) => Tab(text: e)).toList(),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[300],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold, // Selected tab bold
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal, // Unselected tab normal
            fontSize: 16,
          ),
        ),
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (data) => _buildTabContent(currentTab, data),
      ),
    );
  }

  Widget _buildTabContent(String period, FinancialData data) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(financialDataProvider(period));
        await ref.read(financialDataProvider(period).future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.fromLTRB(16, 24, 16, 80),
              child: Column(
                children: [
                  _buildSummaryCards(data),
                  SizedBox(height: 24),
                  _buildTransactionsChart(period, data),
                  if (period == 'Daily') ...[
                    SizedBox(height: 24),
                    _buildCategorySpending(data.categories),
                  ],
                  SizedBox(height: 24),
                  _buildSavingsGoals(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSummaryCards(FinancialData data) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: SummaryCard(
  //           title: 'Net Savings',
  //           amount: data.balance,
  //           color: Colors.blue,
  //           icon: Icons.account_balance_wallet,
  //         ),
  //       ),
  //       SizedBox(width: 10),
  //       Expanded(
  //         child: SummaryCard(
  //           title: 'Income',
  //           amount: data.income,
  //           color: Colors.green,
  //           icon: Icons.arrow_upward,
  //         ),
  //       ),
  //       SizedBox(width: 10),
  //       Expanded(
  //         child: SummaryCard(
  //           title: 'Expense',
  //           amount: data.expense,
  //           color: Colors.red,
  //           icon: Icons.arrow_downward,
  //         ),
  //       ),
  //     ],
  //   );
  // }
  //fix overflow:
  Widget _buildSummaryCards(FinancialData data) {
    return Column(
      children: [
        // Net Savings on its own row
        SummaryCard(
          title: 'Net Savings',
          amount: data.balance,
          color: data.balance >= 0 ? Colors.blue : Colors.orange,
          icon:
              data.balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
        ),
        const SizedBox(height: 12),
        // Row with Income and Expense
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Income',
                amount: data.income,
                color: Colors.green,
                icon: Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Expense',
                amount: data.expense,
                color: Colors.red,
                icon: Icons.arrow_downward,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionsChart(String period, FinancialData data) {
    return CustomBarChart(
      incomeData: data.incomePerPeriod,
      expenseData: data.expensePerPeriod,
      labels: data.labels,
    );
  }

  Widget _buildCategorySpending(List<SpendingCategory> categories) {
    final total = categories.fold(0.0, (sum, cat) => sum + cat.amount);
    if (total == 0) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text('No category data available.'),
      );
    }

    // return Card(
    //   child: Padding(
    //     padding: EdgeInsets.all(16),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         // Text('Spending by Category'),
    //         Text(
    //           'Spending by Category',
    //           style: TextStyle(
    //             fontSize: 16,
    //             fontWeight: FontWeight.bold,
    //           ),
    //         ),
    //         SizedBox(height: 16),
    //         SizedBox(
    //           height: 250,
    //           child: PieChart(
    //             PieChartData(
    //               sections: categories.map((cat) {
    //                 final percent = (cat.amount / total) * 100;
    //                 return PieChartSectionData(
    //                   color: cat.color,
    //                   value: percent,
    //                   title: '${percent.toStringAsFixed(1)}%',
    //                   radius: 80,
    //                   titleStyle: TextStyle(
    //                     fontSize: 12,
    //                     color: Colors.white,
    //                     fontWeight: FontWeight.bold,
    //                   ),
    //                 );
    //               }).toList(),
    //               centerSpaceRadius: 0,
    //               sectionsSpace: 2,
    //             ),
    //           ),
    //         ),
    //         ...categories.map((cat) => _buildCategoryRow(cat)),
    //       ],
    //     ),
    //   ),
    // );
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: categories.map((cat) {
                  final percent = (cat.amount / total) * 100;
                  return PieChartSectionData(
                    color: cat.color,
                    value: percent,
                    title: '${percent.toStringAsFixed(1)}%',
                    radius: 80,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 0,
                sectionsSpace: 2,
              ),
            ),
          ),
          ...categories.map((cat) => _buildCategoryRow(cat)),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(SpendingCategory category) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: category.color),
          SizedBox(width: 8),
          Text(category.name),
          Spacer(),
          Text('EGP ${category.amount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildSavingsGoals() {
    final goalsAsync = ref.watch(goalsProvider);

    return goalsAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error loading goals: $e'),
      data: (goals) {
        if (goals.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No savings goals found.'),
          );
        }

        // return Card(
        //   child: Padding(
        //     padding: EdgeInsets.all(16),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Text('Savings Goals',
        //             style:
        //                 TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        //         SizedBox(height: 16),
        //         SizedBox(
        //           height: 150,
        //           child: ListView.separated(
        //             scrollDirection: Axis.horizontal,
        //             itemCount: goals.length,
        //             separatorBuilder: (_, __) => SizedBox(width: 16),
        //             itemBuilder: (_, index) {
        //               final goal = goals[index];
        //               return SizedBox(
        //                 width: 120,
        //                 child: Column(
        //                   mainAxisAlignment: MainAxisAlignment.center,
        //                   children: [
        //                     GoalProgressRing(goal: goal, size: 80),
        //                     SizedBox(height: 8),
        //                     Text(goal.name, textAlign: TextAlign.center),
        //                     Text(
        //                         '${(goal.progressPercentage * 100).toStringAsFixed(0)}%'),
        //                   ],
        //                 ),
        //               );
        //             },
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // );
        return Container(
          // margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255), 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Savings Goals',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: goals.length,
                  separatorBuilder: (_, __) => SizedBox(width: 16),
                  itemBuilder: (_, index) {
                    final goal = goals[index];
                    return SizedBox(
                      width: 120,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GoalProgressRing(goal: goal, size: 80),
                          SizedBox(height: 8),
                          Text(goal.name, textAlign: TextAlign.center),
                          Text(
                              '${(goal.progressPercentage * 100).toStringAsFixed(0)}%'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
