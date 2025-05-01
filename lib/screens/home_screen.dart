
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../db/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int selectedIndex = 0;
  String selectedFilter = 'Today';
  List<Map<String, dynamic>> transactions = [];
  double? _monthlyBudget;
  late AnimationController _fabController;

  final List<String> filterOptions = ['Today', 'Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _loadBudget();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final data = await DatabaseHelper.instance.getAllTransactions();
    setState(() => transactions = data.reversed.toList());
  }

  Future<void> _loadBudget() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyBudget = prefs.getDouble('monthly_budget');
    });
  }

  List<Map<String, dynamic>> get filteredTransactions {
    final now = DateTime.now();
    return transactions.where((tx) {
      final txDate = DateTime.parse(tx['date']);
      final normalizedTxDate = DateTime(txDate.year, txDate.month, txDate.day);

      switch (selectedFilter) {
        case 'Today':
          final today = DateTime(now.year, now.month, now.day);
          return normalizedTxDate == today;
        case 'Week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          return normalizedTxDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              normalizedTxDate.isBefore(endOfWeek.add(const Duration(days: 1)));
        case 'Month':
          return txDate.year == now.year && txDate.month == now.month;
        case 'Year':
          return txDate.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  String getFormattedDate() {
    final now = DateTime.now();
    return DateFormat('d/M/yyyy').format(now);
  }

  @override
  Widget build(BuildContext context) {
    final double incomeTotal = filteredTransactions
        .where((t) => t['type'] == 'Income')
        .fold(0.0, (sum, item) => sum + double.parse(item['amount'].toString()));

    final double expenseTotal = filteredTransactions
        .where((t) => t['type'] == 'Expense')
        .fold(0.0, (sum, item) => sum + double.parse(item['amount'].toString()));

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.deepPurple),
                const SizedBox(width: 6),
                Text(getFormattedDate(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Text("Account Balance", style: TextStyle(fontSize: 14, color: Colors.black87)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(backgroundColor: Colors.grey[400]),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Monthly Budget: ৳${_monthlyBudget?.toStringAsFixed(0) ?? '--'}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (_monthlyBudget != null)
                  Text("Remaining: ৳${(_monthlyBudget! - expenseTotal).toStringAsFixed(0)}",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: (expenseTotal > _monthlyBudget!) ? Colors.red : Colors.green)),
              ],
            ),
          ),
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
          Expanded(child: _buildAnimatedTransactionList()),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(
          parent: _fabController,
          curve: Curves.easeInOut,
        )),
        child: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/add').then((_) => _loadTransactions()),
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) async {
          setState(() => selectedIndex = index);
          if (index == 1) {
            await Navigator.pushNamed(context, '/transactions');
            _loadTransactions();
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
    );
  }

  Widget _buildBalanceCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 160,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(title == "Income" ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text("৳${amount.toStringAsFixed(0)}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          const Text("Recent Transactions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/transactions'),
            child: const Text("View All",
                style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTransactionList() {
    final limitedList = filteredTransactions.take(5).toList();

    return ListView.builder(
      itemCount: limitedList.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemBuilder: (context, index) {
        final tx = limitedList[index];
        final isIncome = tx['type'] == 'Income';
        final cardColor = (isIncome ? Colors.greenAccent : Colors.redAccent).withOpacity(0.1);

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + index * 100),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: child,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? Colors.green : Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("৳${tx['amount']}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(tx['description'] ?? '',
                          style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ),
                Text(tx['type'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green : Colors.red,
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
