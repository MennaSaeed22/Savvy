import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savvy/screens/Analytics/presentation/providers/analytics_provider.dart';
import 'package:savvy/screens/Categories/services/goal_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/app_provider.dart';
import '../../globals.dart';
import '../models/goal_model.dart';
import 'goal_details_screen.dart';
import 'constants/predefined_goals.dart';

class SavingsGoalsScreen extends StatefulWidget {
  @override
  _SavingsGoalsScreenState createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  List<Goal> _userGoals = [];

  @override
  void initState() {
    super.initState();
    _loadUserGoals();
  }

  Future<void> _loadUserGoals() async {
    try {
      final goals = await GoalService().fetchGoals();
      setState(() {
        _userGoals = goals.map((goal) {
          return goal.copyWith(
            goalIcon: predefinedGoals
                .firstWhere(
                  (g) => g.name == goal.name,
                )
                .goalIcon,
          );
        }).toList();
      });
    } catch (e) {
      print("Error loading goals: $e");
    }
  }

  double _totalSavings = 0.0;
// For the dropdown
// Goal? _selectedGoal;
  Goal? selectedGoal;
// Add this method to handle adding funds to goals
  void _updateTotalSavings() {
    _totalSavings = _userGoals.fold(0.0, (sum, goal) => sum + goal.savedAmount);
  }

  @override
  Widget build(BuildContext context) {
    _updateTotalSavings(); // Update total savings whenever the widget is built
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OffWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Savings Goals",
          style: TextStyle(
            color: OffWhite,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
// Total Savings Display
                    _buildTotalSavings(),
                    const SizedBox(height: 20),
// Goal Selection Dropdown
                    _buildGoalDropdown(),
                    const SizedBox(height: 20),
// Selected Goals List
                    Expanded(
                      child: _buildGoalsList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSavings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            "Total Savings",
            style: TextStyle(
              fontSize: 16,
              color: secondaryColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "EGP ${_totalSavings.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButton<Goal>(
          dropdownColor: Colors.white,
          isExpanded: true,
          hint: const Text("Select a savings goal"),
          value: selectedGoal,
          items: predefinedGoals
              .where((goal) => !_userGoals.any((g) => g.name == goal.name))
              .map((goal) => DropdownMenuItem<Goal>(
                    value: goal,
                    child: Row(
                      children: [
                        Icon(goal.goalIcon, color: primaryColor),
                        const SizedBox(width: 10),
                        Text(goal.name),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (Goal? newValue) async {
            if (newValue != null) {
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User not logged in')),
                );
                return;
              }
              final alreadyExists =
                  _userGoals.any((g) => g.name == newValue.name);
              if (!alreadyExists) {
                final newGoal = await Supabase.instance.client
                    .from('goals')
                    .upsert({
                      'user_id': userId,
                      'goal_name': newValue.name,
                      'amount_saved': 0.0,
                      'target_amount': 0.0,
                      'created_at': DateTime.now().toIso8601String(),
                    })
                    .select()
                    .single();
                final goal = Goal.fromJson(newGoal);
                setState(() {
                  _userGoals.add(goal.copyWith(goalIcon: newValue.goalIcon));
                  selectedGoal = null;
                  _updateTotalSavings();
                });
                // providers here
                final container =
                    ProviderScope.containerOf(context, listen: false);
                container.invalidate(financialSummaryProvider);
                container.invalidate(goalsProvider);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${newValue.name} goal already added')),
                );
              }
            }
          }),
    );
  }

  Widget _buildGoalsList() {
    if (_userGoals.isEmpty) {
      return Center(
        child: Text(
          "Your savings journey starts here",
          style: TextStyle(
            color: secondaryColor.withOpacity(0.5),
            fontSize: 16,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadUserGoals,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _userGoals.length,
        itemBuilder: (context, index) {
          final goal = _userGoals[index];
          return GestureDetector(
            onTap: () async {
              // Navigate to goal details screen
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GoalDetailsScreen(goal: goal),
                ),
              );
              // If any changes were made in the goal detail screen
              if (updated == true) {
                await _loadUserGoals(); // Refresh goals from Supabase
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: softBlue,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(goal.goalIcon, size: 36, color: primaryColor),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Saved: EGP ${goal.savedAmount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      return IconButton(
                        icon: const Icon(Icons.delete, color: Colors.blue),
                        onPressed: () async {
                          try {
                            await GoalService().deleteGoal(goal.name);
                            print("Goal deleted in Supabase");
                            setState(() {
                              _userGoals.removeAt(index);
                              _updateTotalSavings();
                            });
                            ref.invalidate(financialSummaryProvider);
                            ref.invalidate(goalsProvider);
                          } catch (e) {
                            print("Failed to delete goal: $e");
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// add  get data from supabase
//goal, expense, income, transaction
