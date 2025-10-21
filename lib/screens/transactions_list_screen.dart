import 'dart:io';

import 'package:animationandcharts/models/account_model.dart';
import 'package:animationandcharts/models/category_model.dart';
import 'package:animationandcharts/providers/account_provider.dart';
import 'package:animationandcharts/providers/category_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/currency_provider.dart';
import 'add_transaction_screen.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TransactionsListScreen extends ConsumerStatefulWidget {
  final String userId;
  const TransactionsListScreen({super.key, required this.userId});

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen> {
  String selectedFilter = "All"; // 👈 store selected filter
  String searchQuery = ""; // 👈 add this

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(userTransactionsProvider(widget.userId));
    final currencyAsync = ref.watch(userCurrencyProvider(widget.userId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Transactions",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: colorScheme.primary),
            onPressed: () => _showDateRangeDialog(context, txAsync.value ?? []),
          ),

          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: colorScheme.primary),
            initialValue: selectedFilter,
            onSelected: (value) {
              setState(() {
                selectedFilter = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "All", child: Text("All")),
              PopupMenuItem(value: "Income", child: Text("Income")),
              PopupMenuItem(value: "Expense", child: Text("Expense")),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        onPressed: () async {
          final newTx = await Navigator.push<TransactionModel?>(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditTransactionScreen(userId: widget.userId),
            ),
          );
          if (newTx != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Transaction added")),
            );
          }
        },
        child: const Icon(Icons.add, size: 28),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: txAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return Center(
                child: Text(
                  "No transactions yet",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: colorScheme.onBackground.withOpacity(0.5),
                  ),
                ),
              );
            }

            final currencySymbol = currencyAsync.maybeWhen(
              data: (c) => c?.symbol ?? "₹",
              orElse: () => "₹",
            );

            // ✅ Apply filter + search here:
            List<TransactionModel> filteredTx = transactions;

            // 1. Type filter
            if (selectedFilter != "All") {
              filteredTx = filteredTx
                  .where(
                    (tx) =>
                        tx.type.toLowerCase() == selectedFilter.toLowerCase(),
                  )
                  .toList();
            }

            // 2. Search filter
            if (searchQuery.isNotEmpty) {
              filteredTx = filteredTx.where((tx) {
                final titleMatch = tx.title.toLowerCase().contains(searchQuery);
                final descMatch = (tx.description ?? "").toLowerCase().contains(
                  searchQuery,
                );
                final amountMatch = tx.amount.toString().contains(searchQuery);
                return titleMatch || descMatch || amountMatch;
              }).toList();
            }

            // ✅ Group transactions by date
            final groupedTransactions = <String, List<TransactionModel>>{};
            for (var tx in filteredTx) {
              final dateKey =
                  "${tx.date.day}-${tx.date.month}-${tx.date.year}"; // e.g. "28-9-2025"
              groupedTransactions.putIfAbsent(dateKey, () => []).add(tx);
            }

            // ✅ Convert to a list to maintain order (latest first)
            final sortedGroups = groupedTransactions.entries.toList()
              ..sort((a, b) {
                final dateA = a.value.first.date;
                final dateB = b.value.first.date;
                return dateB.compareTo(dateA);
              });

            return Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search transactions...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 16),
                // ✅ Show filtered list
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: sortedGroups.length,
                    itemBuilder: (context, groupIndex) {
                      final dateKey = sortedGroups[groupIndex].key;
                      final txList = sortedGroups[groupIndex].value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🗓️ Date header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              dateKey,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),

                          // 🧾 List of transactions for this date
                          ...txList.asMap().entries.map((entry) {
                            final tx = entry.value;
                            final isIncome = tx.type.toLowerCase() == 'income';
                            final isExpense =
                                tx.type.toLowerCase() == 'expense';

                            return Dismissible(
                              key: ValueKey(tx.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Delete Transaction"),
                                    content: const Text(
                                      "Are you sure you want to delete this transaction?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  try {
                                    await ref
                                        .read(transactionServiceProvider)
                                        .deleteTransaction(tx.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("✅ Transaction deleted"),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Failed to delete: $e"),
                                      ),
                                    );
                                  }
                                }
                                return false;
                              },
                              child: _buildTransactionTile(
                                tx,
                                currencySymbol,
                                colorScheme,
                                entry.key,
                                isIncome,
                                isExpense,
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              "Error loading transactions: $e",
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    TransactionModel tx,
    String currencySymbol,
    ColorScheme colorScheme,
    int index,
    bool isIncome,
    bool isExpense,
  ) {
    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push<TransactionModel?>(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditTransactionScreen(
              transaction: tx, // 👈 Pass the selected transaction
              userId: widget.userId, // 👈 Pass userId too
            ),
          ),
        );

        if (updated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Transaction updated")),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: isExpense
                    ? colorScheme.error.withOpacity(0.1)
                    : colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? colorScheme.primary : colorScheme.error,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx.description ?? "",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colorScheme.onBackground.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${tx.type} • ${tx.date.day}-${tx.date.month}-${tx.date.year}",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "${isExpense ? '-' : '+'}$currencySymbol${tx.amount.toStringAsFixed(2)}",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isExpense ? colorScheme.error : colorScheme.primary,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.2),
    );
  }

  Future<void> _showDateRangeDialog(
    BuildContext context,
    List<TransactionModel> allTransactions,
  ) async {
    DateTime? startDate;
    DateTime? endDate;

    String? selectedCategoryId;
    String? selectedAccountId;

    final userId = FirebaseAuth.instance.currentUser!.uid;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("📆 Filter Transactions"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 📅 Start Date Picker
                  ListTile(
                    title: Text(
                      startDate == null
                          ? "Start Date"
                          : "${startDate!.day}-${startDate!.month}-${startDate!.year}",
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => startDate = picked);
                    },
                  ),

                  // 📅 End Date Picker
                  ListTile(
                    title: Text(
                      endDate == null
                          ? "End Date"
                          : "${endDate!.day}-${endDate!.month}-${endDate!.year}",
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => endDate = picked);
                    },
                  ),

                  const SizedBox(height: 20),

                  // 📂 Category Dropdown
                  StreamBuilder<List<CategoryModel>>(
                    stream: ref
                        .read(categoryRepositoryProvider)
                        .streamUserCategories(userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final categories = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Select Category",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedCategoryId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text("All Categories"),
                          ),
                          ...categories.map(
                            (cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => selectedCategoryId = val),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // 💳 Account Dropdown
                  StreamBuilder<List<Account>>(
                    stream: ref
                        .read(accountRepositoryProvider)
                        .getAccounts(userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final accounts = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Select Account",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedAccountId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text("All Accounts"),
                          ),
                          ...accounts.map(
                            (acc) => DropdownMenuItem(
                              value: acc.id,
                              child: Text(acc.name),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => selectedAccountId = val),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _generatePdf(
                    allTransactions,
                    startDate,
                    endDate,
                    selectedCategoryId,
                    selectedAccountId,
                  );
                },
                child: const Text("Generate PDF"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generatePdf(
    List<TransactionModel> allTransactions,
    DateTime? start,
    DateTime? end,
    String? categoryId, // 🆕
    String? accountId,
  ) async {
    final pdf = pw.Document();

    // ✅ Apply filters
    final filtered = allTransactions.where((tx) {
      if (start != null && tx.date.isBefore(start)) return false;
      if (end != null && tx.date.isAfter(end)) return false;
      if (categoryId != null && tx.categoryId != categoryId) return false; // 🆕
      if (accountId != null && tx.accountId != accountId) return false; // 🆕
      return true;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));

    // ✅ Calculate summary values
    final totalIncome = filtered
        .where((tx) => tx.type.toLowerCase() == 'income')
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final totalExpense = filtered
        .where((tx) => tx.type.toLowerCase() == 'expense')
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final totalBalance = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: await PdfGoogleFonts.robotoRegular(),
            bold: await PdfGoogleFonts.robotoBold(),
          ),
        ),
        build: (context) => [
          // 🏷️ Header
          pw.Header(
            level: 0,
            child: pw.Text(
              "Transaction Report",
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            start == null && end == null
                ? "Period: All Transactions"
                : "Period: ${start?.day}-${start?.month}-${start?.year} to ${end?.day}-${end?.month}-${end?.year}",
            style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),

          // 📊 Transaction Table
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            headers: ["Date", "Title", "Type", "Amount", "Description"],
            data: filtered.map((tx) {
              return [
                "${tx.date.day}-${tx.date.month}-${tx.date.year}",
                tx.title,
                tx.type,
                tx.amount.toStringAsFixed(2),
                tx.description ?? "-",
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 30),

          // 📊 Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(12),
              color: PdfColors.blue100,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Summary",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                _summaryRow(
                  "Total Income:",
                  "\$${totalIncome.toStringAsFixed(2)}",
                  PdfColors.green,
                ),
                _summaryRow(
                  "Total Expense:",
                  "\$${totalExpense.toStringAsFixed(2)}",
                  PdfColors.red,
                ),
                pw.Divider(),
                _summaryRow(
                  "Total Balance:",
                  "\$${totalBalance.toStringAsFixed(2)}",
                  PdfColors.blue900,
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // 📂 Save the PDF
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/transactions_report.pdf");
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ PDF saved: ${file.path}")));
    }

    // 📤 Share / Preview PDF
    await Printing.sharePdf(bytes: bytes, filename: "transactions_report.pdf");
  }

  // 🧩 Helper widget for summary row
  pw.Widget _summaryRow(
    String label,
    String value,
    PdfColor color, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
