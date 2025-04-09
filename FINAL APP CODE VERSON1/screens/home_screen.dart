import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  String selectedFilter = 'Today';
  List<Map<String, dynamic>> transactions = [];

  final List<String> filterOptions = ['Today', 'Week', 'Month', 'Year'];

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
    DateTime now = DateTime.now();
    return transactions.where((tx) {
      final txDate = DateTime.parse(tx['date']);
      switch (selectedFilter) {
        case 'Today':
          return txDate.year == now.year &&
              txDate.month == now.month &&
              txDate.day == now.day;
        case 'Week':
          return txDate.isAfter(now.subtract(const Duration(days: 7)));
        case 'Month':
          return txDate.year == now.year && txDate.month == now.month;
        case 'Year':
          return txDate.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final int incomeTotal = filteredTransactions
        .where((t) => t['type'] == 'Income')
        .fold(0, (int sum, item) => sum + (item['amount'] as int));

    final int expenseTotal = filteredTransactions
        .where((t) => t['type'] == 'Expense')
        .fold(0, (int sum, item) => sum + (item['amount'] as int));

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F0),
        elevation: 0,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('d/M/yyyy').format(DateTime.now()),
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            const Text("Account Balance",
                style: TextStyle(color: Colors.black87, fontSize: 14)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: CircleAvatar(backgroundColor: Colors.blue),
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBalanceCard("Income", incomeTotal, Colors.green),
              _buildBalanceCard("Expenses", expenseTotal, Colors.red),
            ],
          ),
          const SizedBox(height: 10),
          _buildFilterRow(),
          const SizedBox(height: 10),
          _buildTransactionHeader(),
          Expanded(child: _buildTransactionList()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) async {
          setState(() => selectedIndex = index);
          if (index == 1) {
            await Navigator.pushNamed(context, '/transactions');
            _loadTransactions(); // ✅ Refresh after editing/deleting
          }
          if (index == 2) Navigator.pushNamed(context, '/statistics');
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Transactions"),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Statistics"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, '/add').then((_) => _loadTransactions()),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBalanceCard(String title, int amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 160,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                title == "Income" ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text("৳$amount",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: filterOptions.map((option) {
          final isSelected = selectedFilter == option;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = option),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurple : Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                option,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Recent Transactions",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/transactions'),
            child: const Text("View All",
                style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (filteredTransactions.isEmpty) {
      return const Center(child: Text("No transactions yet"));
    }

    final limitedList = filteredTransactions.take(5).toList(); // top 5 only

    return ListView.builder(
      itemCount: limitedList.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemBuilder: (context, index) {
        final tx = limitedList[index];
        final isIncome = tx['type'] == 'Income';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isIncome
                ? Colors.greenAccent.withOpacity(0.1)
                : Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("৳${tx['amount']}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(tx['category'],
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              Text(tx['type'],
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green : Colors.red)),
            ],
          ),
        );
      },
    );
  }
}
