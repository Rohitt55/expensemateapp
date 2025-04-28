import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final List<String> periodOptions = ['Today', 'Week', 'Month', 'Year'];
  final List<String> typeOptions = ['All', 'Income', 'Expense'];

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
    final now = DateTime.now();

    return transactions.where((tx) {
      if (selectedType != 'All' && tx["type"] != selectedType) return false;

      final txDate = DateTime.parse(tx["date"]);

      switch (selectedPeriod) {
        case 'Today':
          return txDate.year == now.year && txDate.month == now.month && txDate.day == now.day;
        case 'Week':
          final weekAgo = now.subtract(const Duration(days: 7));
          return txDate.isAfter(weekAgo) || txDate.isAtSameMomentAs(weekAgo);
        case 'Month':
          return txDate.year == now.year && txDate.month == now.month;
        case 'Year':
          return txDate.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  void _showEditDialog(Map<String, dynamic> transaction) {
    TextEditingController amountController =
    TextEditingController(text: transaction["amount"].toString());
    TextEditingController categoryController =
    TextEditingController(text: transaction["category"]);
    TextEditingController noteController =
    TextEditingController(text: transaction["description"]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Transaction"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
              if (amountText.isEmpty || double.tryParse(amountText) == null) { // ✅ double check
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid amount')),
                );
                return;
              }

              final updatedData = {
                'id': transaction['id'],
                'amount': double.parse(amountText), // ✅ double.parse
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
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    } else {
      return amount.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F0),
        elevation: 0,
        title: const Text("Transaction History", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: selectedPeriod,
                  items: periodOptions
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedPeriod = value!),
                ),
                const SizedBox(width: 20),
                DropdownButton<String>(
                  value: selectedType,
                  items: typeOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(child: Text("No transactions available"))
                : ListView.builder(
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final tx = filteredTransactions[index];
                final amount = (tx["amount"] as num).toDouble();
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text("${tx["category"]} - ৳${formatAmount(amount)}"), // ✅ formatted display
                    subtitle: Text(
                        "${tx["description"]} • ${DateFormat.yMMMd().format(DateTime.parse(tx["date"]))}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditDialog(tx),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
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
    );
  }
}
