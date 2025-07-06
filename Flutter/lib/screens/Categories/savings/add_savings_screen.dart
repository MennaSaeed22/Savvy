import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savvy/screens/Categories/services/goal_service.dart';
import '../../../providers/app_provider.dart';
import '../models/goal_model.dart';
import '../../globals.dart';
import '../../shared_components/calendar_picker.dart';

class AddSavingsScreen extends ConsumerStatefulWidget {
  final Goal goal;
  const AddSavingsScreen({Key? key, required this.goal}) : super(key: key);

  @override
  ConsumerState<AddSavingsScreen> createState() => _AddSavingsScreenState();
}

class _AddSavingsScreenState extends ConsumerState<AddSavingsScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _depositedAmountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _goalAmountController = TextEditingController();

  String? _selectedCategory;
  bool _isGoalEditable = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dateController.text =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    _goalAmountController.text = widget.goal.targetAmount > 0
        ? widget.goal.targetAmount.toStringAsFixed(2)
        : '';
    _isGoalEditable = widget.goal.targetAmount == 0;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _depositedAmountController.dispose();
    _messageController.dispose();
    _goalAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          "Add Savings",
          style: TextStyle(color: OffWhite, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
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
                child: ListView(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        DateTime? pickedDate = await showCustomDatePicker(
                          context,
                          initialDate: _dateController.text.isNotEmpty
                              ? DateTime.parse(_dateController.text)
                              : DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _dateController.text =
                                "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: _buildInputField(
                          label: "Date*",
                          hint: "Select Date",
                          controller: _dateController,
                          icon: Icons.calendar_today,
                          isEnabled: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Goal",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: softBlue,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.goal.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: widget.goal.progressPercentage,
                                backgroundColor: Colors.grey[300],
                                color: primaryColor,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Saved: \$${widget.goal.savedAmount.toStringAsFixed(2)}"),
                                  Text("Target: \$${widget.goal.targetAmount.toStringAsFixed(2)}"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: "Goal Amount*",
                      hint: "EGP 0.00",
                      controller: _goalAmountController,
                      isEnabled: _isGoalEditable,
                      isNumeric: true,
                    ),
                    if (!_isGoalEditable)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isGoalEditable = true;
                            });
                          },
                          child: const Text(
                            "Edit",
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: "Deposited Amount*",
                      hint: "EGP 0.00",
                      controller: _depositedAmountController,
                      isEnabled: true,
                      isNumeric: true,
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Message (Optional)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLargeInputField(
                          hint: "Add a note about this deposit...",
                          controller: _messageController,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _saveDeposit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "SAVE DEPOSIT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDeposit() async {
    if (_depositedAmountController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _goalAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final deposited = double.tryParse(_depositedAmountController.text);
    final newGoalAmount = double.tryParse(_goalAmountController.text);
    if (deposited == null || deposited <= 0 || newGoalAmount == null || newGoalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid positive amounts")),
      );
      return;
    }

    DateTime? date;
    try {
      final pickedDate = DateTime.parse(_dateController.text);
      final now = DateTime.now();
      date = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, now.hour, now.minute);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid date format")),
      );
      return;
    }

    final deposit = Deposit(
      dateTime: date,
      amount: deposited,
      note: _messageController.text.isNotEmpty ? _messageController.text : null,
    );

    setState(() {
      widget.goal.savedAmount += deposited;
      widget.goal.deposits.add(deposit);
      widget.goal.targetAmount = newGoalAmount;
      if (_selectedCategory != null) {
        widget.goal.category = _selectedCategory!;
      }
    });

    try {
      await GoalService().saveGoal(widget.goal);
      print("Goal saved to Supabase successfully");
      // Refresh financial summary
      ref.read(financialSummaryProvider.notifier).fetchFinancialSummary();
      if (mounted) Navigator.pop(context, widget.goal);
    } catch (e) {
      print("Error saving goal to Supabase: $e");
    }
  }

  Widget _buildInputField({
    required bool isEnabled,
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    bool isNumeric = false,
  }) {
    return TextField(
      enabled: isEnabled,
      controller: controller,
      keyboardType:
          isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      inputFormatters: isNumeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
        filled: true,
        fillColor: softBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  Widget _buildLargeInputField({
    required String hint,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: softBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
