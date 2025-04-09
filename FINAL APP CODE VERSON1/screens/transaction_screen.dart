import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
          return txDate.year == now.year &&
              txDate.month == now.month &&
              txDate.day == now.day;
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
              keyboardType: TextInputType.number,
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
              await DatabaseHelper.instance.updateTransaction({
                'id': transaction['id'],
                'amount': double.parse(amountController.text),
                'category': categoryController.text,
                'description': noteController.text,
                'date': transaction['date'],
                'type': transaction['type'],
              });
              Navigator.pop(context);
              _loadTransactions();
            },
            child: const Text("Save"),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
        ],
      ),
    );
  }

  void _deleteTransaction(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transaction History")),
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
                  onChanged: (value) =>
                      setState(() => selectedPeriod = value!),
                ),
                const SizedBox(width: 20),
                DropdownButton<String>(
                  value: selectedType,
                  items: typeOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => selectedType = value!),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final tx = filteredTransactions[index];
                return Card(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text("${tx["category"]} - ৳${tx["amount"]}"),
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
