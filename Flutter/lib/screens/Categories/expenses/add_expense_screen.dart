import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:savvy/screens/Categories/models/category_model.dart';
import '../../../providers/app_provider.dart';
import 'constants/categories_list.dart';
import '../../globals.dart';
import '../../shared_components/calendar_picker.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String? initialCategory;

  const AddExpenseScreen({
    Key? key,
    this.initialCategory,
  }) : super(key: key);

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(now);
    if (widget.initialCategory != null) {
      _selectedCategory = globalCategories.firstWhere(
        (cat) => cat.id == widget.initialCategory,
        orElse: () => globalCategories[0],
      );
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
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
          "Add Expense",
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
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  children: [
                    const SizedBox(height: 25),
                    GestureDetector(
                      onTap: () async {
                        DateTime? pickedDate =
                            await showCustomDatePicker(context);
                        if (pickedDate != null) {
                          setState(() {
                            _dateController.text =
                                DateFormat('dd/MM/yyyy').format(pickedDate);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: _buildInputField(
                          label: "Date",
                          hint: "Select Date",
                          controller: _dateController,
                          icon: Icons.calendar_today,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildDropdownField(),
                    const SizedBox(height: 25),
                    _buildInputField(
                      label: "Amount",
                      hint: "EGP 00.00",
                      controller: _amountController,
                    ),
                    const SizedBox(height: 25),
                    _buildInputField(
                      label: "Description (optional)",
                      hint: "e.g. groceries, coffee",
                      controller: _descriptionController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () async {
                        if (_amountController.text.isEmpty ||
                            double.tryParse(_amountController.text) == null ||
                            double.parse(_amountController.text) <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter a valid amount')),
                          );
                          return;
                        }

                        if (_dateController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please select a date')),
                          );
                          return;
                        }

                        try {
                          final selectedDateOnly = DateFormat('dd/MM/yyyy')
                              .parse(_dateController.text);
                          final now = DateTime.now();
                          final selectedDate = DateTime(
                            selectedDateOnly.year,
                            selectedDateOnly.month,
                            selectedDateOnly.day,
                            now.hour,
                            now.minute,
                            now.second,
                          );

                          final expenseData = {
                            'category_id': _selectedCategory?.id,
                            'amount':
                                double.parse(_amountController.text.trim()),
                            'description':
                                _descriptionController.text.trim().isNotEmpty
                                    ? _descriptionController.text.trim()
                                    : null,
                            'created_at': selectedDate.toIso8601String(),
                            'transaction_type': 'Expense',
                          };

                          await ref
                              .read(transactionProvider.notifier)
                              .addTransaction(expenseData, ref);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Expense saved')),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: OffWhite,
                        ),
                      ),
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

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: softBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory?.id,
        hint: const Text("Select Category"),
        items: globalCategories
            .sublist(0, globalCategories.length - 1) // Exclude last
            .map((category) {
          return DropdownMenuItem<String>(
            value: category.id,
            child: Text(category.name),
          );
        }).toList(),
        onChanged: (selectedId) {
          setState(() {
            _selectedCategory =
                globalCategories.firstWhere((cat) => cat.id == selectedId);
          });
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
