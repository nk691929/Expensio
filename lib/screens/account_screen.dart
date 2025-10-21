import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/account_provider.dart';
import '../providers/currency_provider.dart';
import 'add_edit_account_screen.dart';

class AccountsScreen extends ConsumerWidget {
  final String userId;
  const AccountsScreen({super.key, required this.userId});

  IconData _mapLogoToIcon(String logo) {
    switch (logo) {
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'account_balance':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider(userId));
    final currencyAsync = ref.watch(userCurrencyProvider(userId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Accounts",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Text(
                "No accounts added yet.\nTap + to add one.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: colorScheme.onBackground.withOpacity(0.6),
                ),
              ).animate().fadeIn(duration: 800.ms),
            );
          }

          final currencySymbol = currencyAsync.maybeWhen(
            data: (c) => c?.symbol ?? "PKR",
            orElse: () => "₹PKR",
          );

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final acc = accounts[index];
              return Hero(
                tag: "account_${acc.id}",
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(acc.colorValue).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Color(acc.colorValue).withOpacity(0.15),
                      radius: 28,
                      child: Icon(
                        _mapLogoToIcon(acc.logo),
                        color: Color(acc.colorValue),
                        size: 30,
                      ),
                    ),
                    title: Text(
                      acc.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      acc.number ?? "—",
                      style: GoogleFonts.inter(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${acc.balance >= 0 ? '' : '-'}$currencySymbol${acc.balance.abs().toStringAsFixed(2)}",
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: acc.balance >= 0
                                ? Colors.green
                                : Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddEditAccountScreen(
                                      account: acc,
                                      userId: userId,
                                    ),
                                  ),
                                );
                              },
                              child: const Icon(Icons.edit, size: 20),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Delete Account"),
                                    content: Text(
                                      "Are you sure you want to delete '${acc.name}'?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await ref
                                        .read(accountNotifierProvider.notifier)
                                        .deleteAccount(acc.id);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                }
                              },
                              child: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 200).ms).slideX(begin: 0.1),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            "⚠️ Error loading accounts: $e",
            style: GoogleFonts.inter(color: Colors.redAccent),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditAccountScreen(userId: userId),
            ),
          );
        },
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add),
        label: Text(
          "Add Account",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ).animate().scale(delay: 500.ms),
    );
  }
}
