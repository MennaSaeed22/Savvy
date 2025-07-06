import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/notifiers/financial_summary_notifier.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // return Card(
    //   elevation: 2,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(12),
    //   ),
    return Container(
      decoration: BoxDecoration(
        // color: Colors.white, // background color
        color: const Color.fromARGB(233, 243, 249, 255), // very light grey-blue
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        //child: Padding(
        // padding: const EdgeInsets.all(12),
        // child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Text(
          //   'EGP${amount.toStringAsFixed(2)}',
          //   style: TextStyle(
          //     fontSize: 16,
          //     fontWeight: FontWeight.bold,
          //     color: color,
          //   ),
          // ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: amount),
            duration: Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Text(
                'EGP ${value.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
          )
        ],
      ),
    );
//     return Container(
//     decoration: BoxDecoration(
//     color: const Color(0xFFF7F8FA), // light off-white
//     borderRadius: BorderRadius.circular(12),
//     border: Border.all(color: Colors.grey.withOpacity(0.12)),
//     boxShadow: [
//       BoxShadow(
//         color: Colors.black.withOpacity(0.08),
//         blurRadius: 12,
//         offset: Offset(0, 6),
//       ),
//     ],
//   ),
//   padding: const EdgeInsets.all(12),
//   child: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(4),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.2),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, size: 16, color: color),
//           ),
//           const SizedBox(width: 8),
//           Text(
//             title,
//             style: TextStyle(
//               color: Theme.of(context).textTheme.bodySmall?.color,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//       const SizedBox(height: 8),
//       TweenAnimationBuilder<double>(
//         tween: Tween(begin: 0, end: amount),
//         duration: const Duration(milliseconds: 800),
//         builder: (context, value, child) {
//           return Text(
//             'EGP ${value.toStringAsFixed(2)}',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           );
//         },
//       ),
//     ],
//   ),
// );

    // );
  }
}

// New widget that consumes the financial data
class FinancialSummaryCards extends ConsumerWidget {
  const FinancialSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financialSummaryAsync = ref.watch(financialSummaryNotifier);
    return financialSummaryAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading financial data',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(financialSummaryNotifier.notifier)
                    .fetchFinancialSummary();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (financialSummary) => Column(
        children: [
          // Income Card
          SummaryCard(
            title: 'Total Income',
            amount: financialSummary.totalIncome,
            color: Colors.green,
            icon: Icons.trending_up,
          ),
          const SizedBox(height: 12),
          // Expenses Card
          SummaryCard(
            title: 'Total Expenses',
            amount: financialSummary.totalExpenses,
            color: Colors.red,
            icon: Icons.trending_down,
          ),
          const SizedBox(height: 12),
          // Balance Card
          SummaryCard(
            title: 'Balance',
            amount: financialSummary.balance,
            color: financialSummary.balance >= 0 ? Colors.blue : Colors.orange,
            icon: financialSummary.balance >= 0
                ? Icons.account_balance_wallet
                : Icons.warning,
          ),
        ],
      ),
    );
  }
}
