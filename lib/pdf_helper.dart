import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'db/database_helper.dart';

class PDFHelper {
  static Future<File> generateTransactionPdf({
    required Map<String, dynamic> user,
    String categoryFilter = 'All',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final allTransactions = await DatabaseHelper.instance.getAllTransactions();

    final filteredTransactions = allTransactions.where((tx) {
      final txDate = DateTime.parse(tx['date']);
      final isAfterStart = startDate == null || !txDate.isBefore(startDate);
      final isBeforeEnd = endDate == null || !txDate.isAfter(endDate);
      final matchesType = categoryFilter == 'All' || tx['type'] == categoryFilter;
      return isAfterStart && isBeforeEnd && matchesType;
    }).toList();

    final totalIncome = filteredTransactions
        .where((tx) => tx['type'] == 'Income')
        .fold<double>(0, (sum, tx) => sum + (tx['amount'] as num).toDouble());

    final totalExpense = filteredTransactions
        .where((tx) => tx['type'] == 'Expense')
        .fold<double>(0, (sum, tx) => sum + (tx['amount'] as num).toDouble());

    final balance = totalIncome - totalExpense;

    final now = DateTime.now();
    final reportTitle = 'Transaction Report - ${DateFormat('MMMM yyyy').format(now)}';

    final tableHeaders = ['Date', 'Amount', 'Category', 'Type', 'Description'];
    final tableData = filteredTransactions.map((tx) {
      final formattedDate = DateFormat('d MMM yyyy, hh:mm a').format(DateTime.parse(tx['date']));
      return [
        formattedDate,
        "${tx['amount']}", // Removed Taka symbol
        tx['category'] ?? '-',
        tx['type'],
        tx['description'] ?? '',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(reportTitle,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('User: ${user['username']} (${user['email']})'),
          if (user['phone'] != null) pw.Text('Phone: ${user['phone']}'),
          pw.SizedBox(height: 10),

          if (startDate != null || endDate != null || categoryFilter != 'All')
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                'Filters Applied: '
                    '${startDate != null ? 'From: ${DateFormat.yMMMd().format(startDate)} ' : ''}'
                    '${endDate != null ? 'To: ${DateFormat.yMMMd().format(endDate)} ' : ''}'
                    '${categoryFilter != 'All' ? '| Type: $categoryFilter' : ''}',
                style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic),
              ),
            ),

          pw.SizedBox(height: 10),
          pw.Text("Summary", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Bullet(text: "Total Income: ${totalIncome.toStringAsFixed(2)}"),
          pw.Bullet(text: "Total Expense: ${totalExpense.toStringAsFixed(2)}"),
          pw.Bullet(text: "Balance: ${balance.toStringAsFixed(2)}"),
          pw.SizedBox(height: 12),

          pw.TableHelper.fromTextArray(
            headers: tableHeaders,
            data: tableData,
            border: pw.TableBorder.all(width: 0.4),
            cellStyle: pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.center,
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(3),
            },
          ),
        ],
      ),
    );

    final outputDir = await getApplicationDocumentsDirectory();
    final file = File('${outputDir.path}/transactions_${now.millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
