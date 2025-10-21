import 'package:animationandcharts/providers/account_provider.dart';
import 'package:animationandcharts/providers/currency_provider.dart';
import 'package:animationandcharts/screens/add_transaction_screen.dart';
import 'package:animationandcharts/screens/transactions_list_screen.dart';
import 'package:animationandcharts/models/transaction_model.dart';
import 'package:animationandcharts/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String userId;
  const DashboardScreen({super.key, required this.userId});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final transactionsAsync = ref.watch(
      userTransactionsProvider(widget.userId),
    );
    ref.watch(accountsStreamProvider(widget.userId));

    final currencyAsync = ref.watch(userCurrencyProvider(widget.userId));
    final currencySymbol = currencyAsync.maybeWhen(
            data: (c) => c?.symbol ?? "PKR",
            orElse: () => "PKR",
          );

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.background,
        title: Text(
          "Dashboard",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onBackground,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: CircleAvatar(
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Icon(Icons.person, color: colorScheme.primary),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTx = await Navigator.push<TransactionModel?>(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditTransactionScreen(userId: widget.userId),
            ),
          );
          if (newTx != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Transaction Added!")));
          }
        },
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Total Balance Card
            transactionsAsync.when(
              data: (transactions) => _buildTotalBalanceCard(
                colorScheme,
                transactions,
                currencySymbol
              ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text("Transactions error: $e"),
            ),
            const SizedBox(height: 30),

            // ✅ Chart
            Text(
              "Income vs Expense",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            transactionsAsync.when(
              data: (transactions) => _buildChart(colorScheme, transactions)
                  .animate()
                  .fadeIn(duration: 800.ms, delay: 200.ms)
                  .slideY(begin: 0.2),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                "Error loading transactions: $e",
                style: TextStyle(color: colorScheme.error),
              ),
            ),

            const SizedBox(height: 30),

            // ✅ Recent Transactions
            Text(
              "Recent Transactions",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            transactionsAsync.when(
              data: (transactions) =>
                  _buildTransactionList(transactions, colorScheme,currencySymbol),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                "Error loading transactions: $e",
                style: TextStyle(color: colorScheme.error),
              ),
            ),

            // ✅ View All Button
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionsListScreen(userId: widget.userId),
                ),
              ),
              child: Text(
                "View All",
                style: GoogleFonts.inter(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ TOTAL BALANCE CARD ------------------

  Widget _buildTotalBalanceCard(
    ColorScheme colorScheme,
    List<TransactionModel> transactions,
    String currencySymbol
  ) {
    // Calculate totals dynamically based on type
    final totalIncome = transactions
        .where((tx) => tx.type.toLowerCase() == 'income')
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    final totalExpense = transactions
        .where((tx) => tx.type.toLowerCase() == 'expense')
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    // 🏦 Sum all account balances
    // final totalAccountsBalance = accounts.fold<double>(
    //   0,
    //   (sum, acc) => sum + acc.balance,
    // );

    // ✅ Total balance = all accounts + (income - expense)
    final totalBalance = totalIncome - totalExpense;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Income & Expense Summary",
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            "\ $currencySymbol${totalBalance.toStringAsFixed(2)}",
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: totalBalance < 0 ? Colors.redAccent : Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat(
                "Income",
                totalIncome,
                Icons.arrow_upward,
                Colors.green,
                currencySymbol
              ),
              _buildStat(
                "Expense",
                totalExpense,
                Icons.arrow_downward,
                Colors.redAccent,
                currencySymbol
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------ STAT ROW ------------------
  Widget _buildStat(
    String label,
    double value,
    IconData icon,
    Color iconColor,
    String currencySymbol
  ) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            Text(
              "$currencySymbol${value.toStringAsFixed(2)}",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------ INCOME VS EXPENSE CHART ------------------
  Widget _buildChart(
    ColorScheme colorScheme,
    List<TransactionModel> transactions,
  ) {
    final now = DateTime.now();

    // 📆 Generate last 7 days (oldest first, today last)
    final last7Days = List.generate(
      7,
      (i) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i)),
    );

    // 📊 Initialize
    final incomePerDay = List.filled(7, 0.0);
    final expensePerDay = List.filled(7, 0.0);

    // 📈 Fill data for each day
    for (var tx in transactions) {
      for (int i = 0; i < 7; i++) {
        final day = last7Days[i];
        if (tx.date.year == day.year &&
            tx.date.month == day.month &&
            tx.date.day == day.day) {
          if (tx.type.toLowerCase() == 'income') {
            incomePerDay[i] += tx.amount;
          } else if (tx.type.toLowerCase() == 'expense') {
            expensePerDay[i] += tx.amount;
          }
        }
      }
    }

    // 📅 Create labels (Mon, Tue, ...)
    final dayLabels = last7Days.map((d) {
      return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][d.weekday - 1];
    }).toList();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < dayLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        dayLabels[idx],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onBackground,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          barGroups: List.generate(7, (index) {
            return BarChartGroupData(
              x: index,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: incomePerDay[index],
                  color: Colors.greenAccent,
                  width: 10,
                  borderRadius: BorderRadius.circular(6),
                ),
                BarChartRodData(
                  toY: expensePerDay[index],
                  color: Colors.redAccent,
                  width: 10,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    List<TransactionModel> transactions,
    ColorScheme colorScheme,
    String currencySymbol
  ) {
    
    final firstFive = transactions.take(5).toList();
    return Column(
      children: firstFive.map((tx) {
        final isExpense = tx.type.toLowerCase() == 'expense';
        return Dismissible(
          key: Key(tx.id),
          background: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            color: Colors.redAccent,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          secondaryBackground: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            color: Colors.blueAccent,
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // handle delete
              final confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Delete Transaction"),
                  content: const Text(
                    "Are you sure you want to delete this transaction?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref
                    .read(transactionServiceProvider)
                    .deleteTransaction(tx.id);
                return true;
              }
              return false;
            } else if (direction == DismissDirection.endToStart) {
              final edited = await Navigator.push<TransactionModel?>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditTransactionScreen(
                    userId: widget.userId,
                    transaction: tx,
                  ),
                ),
              );
              if (edited != null) {
                // refresh list automatically via provider
              }
              return false;
            }
            return false;
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      (isExpense ? Colors.redAccent : Colors.greenAccent)
                          .withOpacity(0.2),
                  child: Icon(
                    isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isExpense ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onBackground,
                        ),
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
                  "${isExpense ? '-' : '+'}\ $currencySymbol${tx.amount.abs().toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isExpense ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
