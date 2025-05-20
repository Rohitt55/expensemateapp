import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../db/database_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final List<String> _categories = [
    'Food',
    'Shopping',
    'Fuel',
    'Salary',
    'Subscription',
    'Grocery',
    'Personal',
    'Medicine', // Changed from Health
    'Others'    // Newly added
  ];

  String _selectedCategory = 'Food';
  String _selectedType = 'Income';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat.yMMMd().format(_selectedDate);
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat.yMMMd().format(picked);
      });
    }
  }

  void _saveTransaction() async {
    final amountText = _amountController.text.trim();
    final desc = _descController.text.trim();

    if (amountText.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    try {
      final amount = double.parse(amountText);
      final formattedDate = _selectedDate.toIso8601String();

      await DatabaseHelper.instance.addTransaction(
        amount,
        _selectedCategory,
        _selectedType,
        formattedDate,
        desc,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount value')),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F0),
        elevation: 0,
        title: Text("Add Transaction", style: TextStyle(color: Colors.black, fontSize: 18.sp)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("How much?", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.h),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Text('৳', style: TextStyle(fontSize: 20.sp)),
                  ),
                  hintText: "Enter amount",
                  border: const OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.h),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 14.sp))))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: InputDecoration(
                  labelText: "Category",
                  labelStyle: TextStyle(fontSize: 14.sp),
                  border: const OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: "Description",
                  labelStyle: TextStyle(fontSize: 14.sp),
                  border: const OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: Text("Income", style: TextStyle(fontSize: 14.sp)),
                    selected: _selectedType == 'Income',
                    selectedColor: Colors.green,
                    onSelected: (_) => setState(() => _selectedType = 'Income'),
                  ),
                  SizedBox(width: 12.w),
                  ChoiceChip(
                    label: Text("Expense", style: TextStyle(fontSize: 14.sp)),
                    selected: _selectedType == 'Expense',
                    selectedColor: Colors.red,
                    onSelected: (_) => setState(() => _selectedType = 'Expense'),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: InputDecoration(
                  labelText: "Date",
                  labelStyle: TextStyle(fontSize: 14.sp),
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
              ),
              SizedBox(height: 30.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text("Continue", style: TextStyle(fontSize: 16.sp, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
