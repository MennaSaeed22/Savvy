import 'package:flutter/material.dart';
import '../../globals.dart';
import '../models/goal_model.dart';
import 'add_savings_screen.dart';

class GoalDetailsScreen extends StatefulWidget {
  final Goal goal;
  const GoalDetailsScreen({required this.goal});
  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
  late List<Deposit> _sortedDeposits;
  @override
  void initState() {
    super.initState();
    _sortedDeposits = List.from(widget.goal.deposits)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  void didUpdateWidget(GoalDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goal.deposits != widget.goal.deposits) {
      _sortedDeposits = List.from(widget.goal.deposits)
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final amountSaved = goal.savedAmount;
    final targetAmount = goal.targetAmount;
//final progress = goal.targetAmount == 0 ? 0 : (goal.savedAmount / goal.targetAmount)
//.toDouble();
    final progress = goal.targetAmount == 0
        ? 0.0
        : double.parse((goal.savedAmount / goal.targetAmount).toString());
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OffWhite),
          onPressed: () => Navigator.pop(context, widget.goal),
        ),
        title: Text(
          goal.name,
          style: const TextStyle(
            color: OffWhite,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: OffWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
// Goal Amounts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Goal",
                          style: TextStyle(color: Colors.black54)),
                      Text("\$${targetAmount.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      const Text("Amount Saved",
                          style: TextStyle(color: Colors.black54)),
                      Text("\$${amountSaved.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    ],
                  ),
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: CircularProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade300,
                            color: primaryColor,
                            strokeWidth: 6,
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: softBlue,
                          radius: 40,
                          child: Icon(goal.goalIcon,
                              color: primaryColor, size: 30),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _sortedDeposits.isNotEmpty
                      ? _getMonthName(_sortedDeposits.first.dateTime.month)
                      : "No Deposits",
                  style: TextStyle(color: secondaryColor, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _sortedDeposits.isEmpty
                    ? const Center(child: Text("No deposits yet"))
                    : ListView.builder(
                        itemCount: _sortedDeposits.length,
                        itemBuilder: (context, index) {
                          return _buildDepositTile(_sortedDeposits[index]);
                        },
                      ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final updatedGoal = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddSavingsScreen(goal: widget.goal),
                    ),
                  );
                  if (updatedGoal != null) {
                    setState(() {
                      widget.goal
                        ..savedAmount = updatedGoal.savedAmount
                        ..deposits = updatedGoal.deposits
                        ..targetAmount = updatedGoal.targetAmount
                        ..category = updatedGoal.category;
                      _sortedDeposits = List.from(widget.goal.deposits)
                        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  child: Text(
                    "Add Savings",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, color: OffWhite),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepositTile(Deposit deposit) {
    final dateTime = deposit.dateTime;
    final formatted =
        "${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year} – ${_formatTime(dateTime)}";
    final note = deposit.note?.isNotEmpty == true ? deposit.note! : "Deposit";
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: softBlue,
        child: Icon(Icons.savings, color: primaryColor),
      ),
      title: Text(note),
      subtitle: Text(formatted, style: const TextStyle(color: Colors.blue)),
      trailing: Text("\$${deposit.amount.toStringAsFixed(2)}"),
    );
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  String _getMonthName(int month) {
    const monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return monthNames[month - 1];
  }
}
// // import 'package:flutter/material.dart';
// // import '../../globals.dart';
// // import '../models/goal_model.dart';
// // import 'add_savings_screen.dart';

// // class GoalDetailsScreen extends StatefulWidget {
// //   final Goal goal;
// //   const GoalDetailsScreen({required this.goal});

// //   @override
// //   State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
// // }

// // class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
// //   @override
// //   Widget build(BuildContext context) {
// //     final goal = widget.goal;
// //     double amountSaved = goal.savedAmount;
// //     double targetAmount = goal.targetAmount;

// //     return Scaffold(
// //       backgroundColor: primaryColor,
// //       appBar: AppBar(
// //         backgroundColor: primaryColor,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back, color: OffWhite),
// //           onPressed: () => Navigator.pop(context, widget.goal),
// //         ),
// //         title: Text(
// //           goal.name,
// //           style: const TextStyle(
// //             color: OffWhite,
// //             fontWeight: FontWeight.bold,
// //             fontSize: 24,
// //           ),
// //         ),
// //         centerTitle: true,
// //       ),
// //       body: Container(
// //         width: double.infinity,
// //         decoration: const BoxDecoration(
// //           color: OffWhite,
// //           borderRadius: BorderRadius.only(
// //             topLeft: Radius.circular(40),
// //             topRight: Radius.circular(40),
// //           ),
// //         ),
// //         child: Padding(
// //           padding: const EdgeInsets.all(20),
// //           child: Column(
// //             children: [
// //               const SizedBox(height: 20),
// //               // Goal Amounts
// //               Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       const Text("Goal", style: TextStyle(color: Colors.black54)),
// //                       Text("\$${targetAmount.toStringAsFixed(2)}",
// //                           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
// //                       const SizedBox(height: 10),
// //                       const Text("Amount Saved", style: TextStyle(color: Colors.black54)),
// //                       Text("\$${amountSaved.toStringAsFixed(2)}",
// //                           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
// //                     ],
// //                   ),
// //                   SizedBox(
// //                     height: 100,
// //                     width: 100,
// //                     child: Stack(
// //                       alignment: Alignment.center,
// //                       children: [
// //                         SizedBox(
// //                           height: 100,
// //                           width: 100,
// //                           child: CircularProgressIndicator(
// //                             value: goal.targetAmount == 0 ? 0 : goal.savedAmount / goal.targetAmount,
// //                             backgroundColor: Colors.grey.shade300,
// //                             color: primaryColor,
// //                             strokeWidth: 6,
// //                           ),
// //                         ),
// //                         CircleAvatar(
// //                           backgroundColor: softBlue,
// //                           radius: 40,
// //                           child: Icon(goal.goalIcon, color: primaryColor, size: 30),
// //                         ),
// //                       ],
// //                     ),
// //                   )
// //                 ],
// //               ),
// //               const SizedBox(height: 30),
              
// //               // Align(
// //               //   alignment: Alignment.centerLeft,
// //               //   child: Text("April", style: TextStyle(color: secondaryColor, fontSize: 16)),
// //               // ),
// //               Align(
// //                 alignment: Alignment.centerLeft,
// //                 child: Text(
// //                   goal.deposits.isNotEmpty
// //                       ? _getMonthName(goal.deposits[0].dateTime.month)
// //                       : "No Deposits",
// //                   style: TextStyle(color: secondaryColor, fontSize: 16),
// //                 ),
// //               ),
// //               const SizedBox(height: 10),
// //               goal.deposits.sort((a, b) => b.dateTime.compareTo(a.dateTime));

// //               Expanded(
// //                 child: ListView.builder(
// //                   itemCount: goal.deposits.length,
// //                   itemBuilder: (context, index) {
// //                     final deposit = goal.deposits[index];
// //                     //final formattedTime =
// //                       //  "${deposit.dateTime.hour.toString().padLeft(2, '0')}:${deposit.dateTime.minute.toString().padLeft(2, '0')}";
// //                     //final formattedDate =
// //                         //"${_getMonthName(deposit.dateTime.month)} ${deposit.dateTime.day}";
// //                     //return _buildDepositTile("$formattedTime - $formattedDate", deposit.amount);
// //                     return _buildDepositTile(deposit); 
// //                   },
// //                 ),
// //               ),
// //               const SizedBox(height: 20),
// //               ElevatedButton(
// //                 onPressed: () async {
// //                   final updatedGoal = await Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (context) => AddSavingsScreen(goal: widget.goal),
// //                     ),
// //                   );
// //                   if (updatedGoal != null) {
// //                   setState(() {
// //                     widget.goal.savedAmount = updatedGoal.savedAmount;
// //                     widget.goal.deposits = updatedGoal.deposits;
// //                     widget.goal.targetAmount = updatedGoal.targetAmount;
// //                     widget.goal.category = updatedGoal.category;
// //                   });
// //                  // Navigator.pop(context, widget.goal);
// //                   }
// //                   //setState(() {}); // Refresh the screen after adding a deposit
// //                 },
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: primaryColor,
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(30),
// //                   ),
// //                 ),
// //                 child: const Padding(
// //                   padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
// //                   child: Text(
// //                     "Add Savings",
// //                     style: TextStyle(fontWeight: FontWeight.bold,  color: OffWhite),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   // Widget _buildDepositTile(String dateTime, double amount) {
// //   //   return ListTile(
// //   //     contentPadding: EdgeInsets.zero,
// //   //     leading: CircleAvatar(
// //   //       backgroundColor: softBlue,
// //   //       child: Icon(Icons.flight, color: primaryColor),
// //   //     ),
// //   //     //title: const Text("Travel Deposit"), //need to be changed
// //   //     title: Text(Deposit.note ?? "Deposit"),
// //   //     subtitle: Text(dateTime, style: const TextStyle(color: Colors.blue)),
// //   //     trailing: Text("\$${amount.toStringAsFixed(2)}"),
// //   //   );
// //   // }
// //   Widget _buildDepositTile(Deposit deposit) {
// //   final dateTime = deposit.dateTime;
// //   final formatted = "${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year} – ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

// //   return ListTile(
// //     contentPadding: EdgeInsets.zero,
// //     leading: CircleAvatar(
// //       backgroundColor: softBlue,
// //       child: Icon(Icons.savings, color: primaryColor),
// //     ),
// //     title: Text(deposit.note?.isNotEmpty == true ? deposit.note! : "Deposit"),
// //     subtitle: Text(formatted, style: const TextStyle(color: Colors.blue)),
// //     trailing: Text("\$${deposit.amount.toStringAsFixed(2)}"),
// //   );
// // }


// //   String _getMonthName(int month) {
// //     const monthNames = [
// //       "January", "February", "March", "April", "May", "June",
// //       "July", "August", "September", "October", "November", "December"
// //     ];
// //     return monthNames[month - 1];
// //   }
// // }

// import 'package:flutter/material.dart';
// import '../../globals.dart';
// import '../models/goal_model.dart';
// import 'add_savings_screen.dart';

// class GoalDetailsScreen extends StatefulWidget {
//   final Goal goal;
//   const GoalDetailsScreen({required this.goal});

//   @override
//   State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
// }

// class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
//   late List<Deposit> _sortedDeposits;

//   @override
//   void initState() {
//     super.initState();
//     _sortedDeposits = List.from(widget.goal.deposits)
//       ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
//   }

//   @override
//   void didUpdateWidget(GoalDetailsScreen oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.goal.deposits != widget.goal.deposits) {
//       _sortedDeposits = List.from(widget.goal.deposits)
//         ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final goal = widget.goal;
//     final amountSaved = goal.savedAmount;
//     final targetAmount = goal.targetAmount;
//     //final progress = goal.targetAmount == 0 ? 0 : (goal.savedAmount / goal.targetAmount)
//     //.toDouble();
//     // final progress = goal.targetAmount == 0 ? 0.0 : double.parse((goal.savedAmount / goal.targetAmount).toString());
//     final progress = goal.progressPercentage;

//     return Scaffold(
//       backgroundColor: primaryColor,
//       appBar: AppBar(
//         backgroundColor: primaryColor,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: OffWhite),
//           onPressed: () => Navigator.pop(context, widget.goal),
//         ),
//         title: Text(
//           goal.name,
//           style: const TextStyle(
//             color: OffWhite,
//             fontWeight: FontWeight.bold,
//             fontSize: 24,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: Container(
//         width: double.infinity,
//         decoration: const BoxDecoration(
//           color: OffWhite,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(40),
//             topRight: Radius.circular(40),
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               // Goal Amounts
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text("Goal", style: TextStyle(color: Colors.black54)),
//                       Text("\EGP${targetAmount.toStringAsFixed(2)}",
//                           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 10),
//                       const Text("Amount Saved", style: TextStyle(color: Colors.black54)),
//                       Text("\EGP${amountSaved.toStringAsFixed(2)}",
//                           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
//                     ],
//                   ),
//                   SizedBox(
//                     height: 100,
//                     width: 100,
//                     child: Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         SizedBox(
//                           height: 100,
//                           width: 100,
//                           child: CircularProgressIndicator(
//                             value: progress,
//                             backgroundColor: Colors.grey.shade300,
//                             color: primaryColor,
//                             strokeWidth: 6,
//                           ),
//                         ),
//                         CircleAvatar(
//                           backgroundColor: softBlue,
//                           radius: 40,
//                           child: Icon(goal.goalIcon, color: primaryColor, size: 30),
//                         ),
//                       ],
//                     ),
//                   )
//                 ],
//               ),
//               const SizedBox(height: 30),
              
//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   _sortedDeposits.isNotEmpty
//                       ? _getMonthName(_sortedDeposits.first.dateTime.month)
//                       : "No Deposits",
//                   style: TextStyle(color: secondaryColor, fontSize: 16),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               Expanded(
//                 child: _sortedDeposits.isEmpty
//                     ? const Center(child: Text("No deposits yet"))
//                     : ListView.builder(
//                         itemCount: _sortedDeposits.length,
//                         itemBuilder: (context, index) {
//                           return _buildDepositTile(_sortedDeposits[index]); 
//                         },
//                       ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () async {
//                   final updatedGoal = await Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => AddSavingsScreen(goal: widget.goal),
//                     ),
//                   );
//                   if (updatedGoal != null) {
//                     setState(() {
//                       widget.goal
//                         ..savedAmount = updatedGoal.savedAmount
//                         ..deposits = updatedGoal.deposits
//                         ..targetAmount = updatedGoal.targetAmount
//                         ..category = updatedGoal.category;
//                       _sortedDeposits = List.from(widget.goal.deposits)
//                         ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
//                     });
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryColor,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//                 child: const Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//                   child: Text(
//                     "Add Savings",
//                     style: TextStyle(fontWeight: FontWeight.bold, color: OffWhite),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDepositTile(Deposit deposit) {
//     final dateTime = deposit.dateTime;
//     final formatted = "${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year} – ${_formatTime(dateTime)}";
//     final note = deposit.note?.isNotEmpty == true ? deposit.note! : "Deposit";

//     return ListTile(
//       contentPadding: EdgeInsets.zero,
//       leading: const CircleAvatar(
//         backgroundColor: softBlue,
//         child: Icon(Icons.savings, color: primaryColor),
//       ),
//       title: Text(note),
//       subtitle: Text(formatted, style: const TextStyle(color: Colors.blue)),
//       trailing: Text("EGP${deposit.amount.toStringAsFixed(2)}"),
//     );
//   }

//   String _formatTime(DateTime dateTime) {
//     return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
//   }

//   String _getMonthName(int month) {
//     const monthNames = [
//       "January", "February", "March", "April", "May", "June",
//       "July", "August", "September", "October", "November", "December"
//     ];
//     return monthNames[month - 1];
//   }
// }

// ///
// ///ListView.builder(
// //   itemCount: widget.goal.deposits.length,
// //   itemBuilder: (context, index) {
// //     final deposit = widget.goal.deposits[index];
// //     return ListTile(
// //       title: Text(
// //         "\$${deposit.amount.toStringAsFixed(2)}",
// //         style: const TextStyle(fontWeight: FontWeight.bold),
// //       ),
// //       subtitle: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(deposit.message),
// //           Text(deposit.date, style: TextStyle(fontSize: 12, color: Colors.grey)),
// //         ],
// //       ),
// //       trailing: IconButton(
// //         icon: const Icon(Icons.delete, color: Colors.red),
// //         onPressed: () {
// //           setState(() {
// //             widget.goal.deposits.removeAt(index);
// //             widget.goal.savedAmount -= deposit.amount;
// //           });
// //         },
// //       ),
// //     );
// //   },
// // )
