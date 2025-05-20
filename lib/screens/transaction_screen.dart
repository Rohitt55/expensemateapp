import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../db/database_helper.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<Map<String, dynamic>> transactions = [];
  String selectedPeriod = 'Month';
  String selectedType = 'All';
  String searchQuery = '';
  DateTime selectedDate = DateTime.now();

  final List<String> periodOptions = ['Today', 'Week', 'Month', 'Year'];
  final List<String> typeOptions = ['All', 'Income', 'Expense'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final data = await DatabaseHelper.instance.getAllTransactions();
    setState(() => transactions = data.reversed.toList());
  }

  List<Map<String, dynamic>> get filteredTransactions {
    final now = selectedDate;
    return transactions.where((tx) {
      if (selectedType != 'All' && tx['type'] != selectedType) return false;

      final txDate = DateTime.parse(tx['date']);
      final normalizedTxDate = DateTime(txDate.year, txDate.month, txDate.day);

      bool dateMatch;
      switch (selectedPeriod) {
        case 'Today':
          final today = DateTime(now.year, now.month, now.day);
          dateMatch = normalizedTxDate == today;
          break;
        case 'Week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          dateMatch = normalizedTxDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              normalizedTxDate.isBefore(endOfWeek.add(const Duration(days: 1)));
          break;
        case 'Month':
          dateMatch = txDate.year == now.year && txDate.month == now.month;
          break;
        case 'Year':
          dateMatch = txDate.year == now.year;
          break;
        default:
          dateMatch = true;
      }

      final category = (tx['category'] ?? '').toString().toLowerCase();
      final description = (tx['description'] ?? '').toString().toLowerCase();
      final amount = (tx['amount'] ?? '').toString().toLowerCase();
      final search = searchQuery.toLowerCase();

      return dateMatch && (
          category.contains(search) ||
              description.contains(search) ||
              amount.contains(search)
      );
    }).toList();
  }

  String getFormattedTransactionDate() {
    final now = selectedDate;
    switch (selectedPeriod) {
      case 'Today':
        return DateFormat('d/M/yyyy').format(now);
      case 'Week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return "${DateFormat('d/M').format(start)} - ${DateFormat('d/M').format(end)}";
      case 'Month':
        return DateFormat('MMMM yyyy').format(now);
      case 'Year':
        return DateFormat('yyyy').format(now);
      default:
        return DateFormat('d/M/yyyy').format(now);
    }
  }

  void _showEditDialog(Map<String, dynamic> transaction) {
    final amountController = TextEditingController(text: transaction["amount"].toString());
    final categoryController = TextEditingController(text: transaction["category"]);
    final noteController = TextEditingController(text: transaction["description"]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Transaction", style: TextStyle(fontSize: 16.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Category"),
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Note"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final amountText = amountController.text.trim();
              if (amountText.isEmpty || double.tryParse(amountText) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              final updatedData = {
                'id': transaction['id'],
                'amount': double.parse(amountText),
                'category': categoryController.text,
                'description': noteController.text,
                'date': transaction['date'],
                'type': transaction['type'],
                'userEmail': transaction['userEmail'],
              };

              try {
                await DatabaseHelper.instance.updateTransaction(updatedData);
                Navigator.pop(context);
                _loadTransactions();
              } catch (e) {
                print('Error updating transaction: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Update failed')),
                );
              }
            },
            child: const Text("Save"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    _loadTransactions();
  }

  String formatAmount(double amount) {
    return amount == amount.roundToDouble() ? amount.toInt().toString() : amount.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F0),
        elevation: 0,
        title: Text("Transaction History", style: TextStyle(color: Colors.black, fontSize: 18.sp)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.r),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4.r, offset: const Offset(0,2))],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPeriod,
                          items: periodOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (value) => setState(() => selectedPeriod = value!),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.r),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4.r, offset: const Offset(0,2))],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          items: typeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (value) => setState(() => selectedType = value!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                  child: Row(
                    children: [
                      Text(
                        "Showing: ${getFormattedTransactionDate()}",
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      SizedBox(width: 5.w),
                      Icon(Icons.calendar_today, size: 16.sp, color: Colors.deepPurple),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by category, note or amount',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(child: Text("No transactions available", style: TextStyle(fontSize: 14.sp)))
                  : ListView.builder(
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) {
                  final tx = filteredTransactions[index];
                  final amount = (tx["amount"] as num).toDouble();
                  final isIncome = tx["type"] == "Income";

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 4,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome ? Colors.greenAccent : Colors.redAccent,
                        child: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        "${tx["category"]} - ৳${formatAmount(amount)}",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                      ),
                      subtitle: Text(
                        "${tx["description"]} • ${DateFormat.yMMMd().add_jm().format(DateTime.parse(tx["date"]))}",
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue, size: 20.sp),
                            onPressed: () => _showEditDialog(tx),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red, size: 20.sp),
                            onPressed: () => _deleteTransaction(tx["id"]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
