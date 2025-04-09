import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/database_helper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool showIncome = false;
  List<Map<String, dynamic>> allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final data = await DatabaseHelper.instance.getAllTransactions();
    setState(() => allTransactions = data);
  }

  List<Map<String, dynamic>> get filteredByType {
    return allTransactions.where((tx) => tx['type'] == (showIncome ? 'Income' : 'Expense')).toList();
  }

  Map<String, int> get groupedByCategory {
    Map<String, int> result = {};
    for (var tx in filteredByType) {
      final category = tx['category'];
      final amount = tx['amount'] as int;
      result[category] = (result[category] ?? 0) + amount;
    }
    return result;
  }

  List<BarChartGroupData> get weeklyBars {
    return List.generate(7, (i) {
      double total = allTransactions
          .where((tx) => DateTime.parse(tx['date']).weekday == (i + 1))
          .where((tx) => tx['type'] == (showIncome ? 'Income' : 'Expense'))
          .fold(0.0, (sum, tx) => sum + (tx['amount'] as int));
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: total,
          width: 14,
          borderRadius: BorderRadius.circular(6),
          color: showIncome ? Colors.green : Colors.redAccent,
        )
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryData = groupedByCategory;
    final total = categoryData.values.fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Financial Report", style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildBarChart(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildToggleButton("Expense", !showIncome, () => setState(() => showIncome = false), Colors.redAccent),
                const SizedBox(width: 12),
                _buildToggleButton("Income", showIncome, () => setState(() => showIncome = true), Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(flex: 2, child: _buildCategoryList(categoryData, total)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showIncome ? "Weekly Income Overview" : "Weekly Expenses Overview",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 1.7,
          child: BarChart(
            BarChartData(
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(days[value.toInt() % 7], style: const TextStyle(fontSize: 10)),
                    );
                  }),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2000,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          "${value.toInt()}",
                          style: const TextStyle(fontSize: 10, color: Colors.black),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: weeklyBars,
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool selected, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildCategoryList(Map<String, int> categoryData, int total) {
    if (categoryData.isEmpty) {
      return const Center(child: Text("No data available"));
    }

    return ListView(
      children: categoryData.entries.map((entry) {
        final percent = total == 0 ? 0.0 : entry.value / total;
        final color = showIncome ? Colors.green : Colors.redAccent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 6, backgroundColor: color),
                const SizedBox(width: 8),
                Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500))),
                Text("৳ ${entry.value}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 14),
          ],
        );
      }).toList(),
    );
  }
}
