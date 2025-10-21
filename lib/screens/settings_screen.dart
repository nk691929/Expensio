import 'package:animationandcharts/providers/auth_provider.dart';
import 'package:animationandcharts/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/currency_model.dart';
import '../providers/currency_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final String userId; // 👈 pass the current user's UID here

  const SettingsScreen({super.key, required this.userId});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // bool _notificationsEnabled = true;

  void _showCurrencyPicker(CurrencyModel? selectedCurrency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Currency",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...currencyList.map(
                (currency) => ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text(
                    "${currency.name} (${currency.code})",
                    style: GoogleFonts.inter(fontSize: 18),
                  ),
                  trailing: selectedCurrency?.code == currency.code
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () async {
                    // ✅ Save selection to Firestore
                    await ref
                        .read(currencyServiceProvider)
                        .saveUserCurrency(widget.userId, currency);

                    if (mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

 void _showChangePasswordDialog() {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  bool showOldPassword = false;
  bool showNewPassword = false;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("Change Password 🔐"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: !showOldPassword,
              decoration: InputDecoration(
                labelText: "Old Password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    showOldPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => showOldPassword = !showOldPassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: !showNewPassword,
              decoration: InputDecoration(
                labelText: "New Password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    showNewPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => showNewPassword = !showNewPassword);
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final oldPassword = oldPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();

              if (oldPassword.isEmpty || newPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill both fields.")),
                );
                return;
              }

              try {
                await ref.read(authServiceProvider).changePassword(
                      oldPassword: oldPassword,
                      newPassword: newPassword,
                    );

                if (context.mounted) Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Password changed successfully"),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ ${e.message}")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Something went wrong: $e")),
                );
              }
            },
            child: const Text("Change"),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // 👇 Watch real-time currency updates
    final currencyAsync = ref.watch(userCurrencyProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🌙 THEME SECTION
          Text(
            "🎨 Appearance",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                size: 28,
              ),
              title: Text("Dark Mode", style: GoogleFonts.inter(fontSize: 16)),
              subtitle: Text(
                isDark
                    ? "Switch to light theme"
                    : "Switch to dark theme for better night experience",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              value: isDark,
              onChanged: (val) {
                ref.read(themeModeProvider.notifier).toggleTheme(val);
              },
            ),
          ),
          const SizedBox(height: 20),

          // 🪙 Currency Section
          Text(
            "💱 Currency",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: currencyAsync.when(
              data: (currency) {
                final current = currency ?? currencyList.first;
                return ListTile(
                  leading: const Icon(Icons.attach_money, size: 28),
                  title: Text(
                    "Default Currency",
                    style: GoogleFonts.inter(fontSize: 16),
                  ),
                  subtitle: Text(
                    "${current.name} (${current.code})",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                  ),
                  onTap: () => _showCurrencyPicker(current),
                );
              },
              loading: () => const ListTile(
                title: Text("Loading currency..."),
                trailing: CircularProgressIndicator(),
              ),
              error: (e, _) => ListTile(
                title: const Text("Failed to load currency"),
                subtitle: Text(e.toString()),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 🔑 Password Section
          Text(
            "🔐 Security",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.lock, size: 28),
              title: Text(
                "Change Password",
                style: GoogleFonts.inter(fontSize: 16),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: _showChangePasswordDialog,
            ),
          ),
          const SizedBox(height: 20),

          // 🔔 Notifications
          // Text(
          //   "🔔 Notifications",
          //   style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          // ),
          // const SizedBox(height: 8),
          // Card(
          //   shape: RoundedRectangleBorder(
          //     borderRadius: BorderRadius.circular(16),
          //   ),
          //   child: SwitchListTile(
          //     secondary: const Icon(Icons.notifications_active, size: 28),
          //     title: Text(
          //       "Push Notifications",
          //       style: GoogleFonts.inter(fontSize: 16),
          //     ),
          //     subtitle: Text(
          //       _notificationsEnabled
          //           ? "You will receive transaction alerts and summaries"
          //           : "Notifications are turned off",
          //       style: GoogleFonts.inter(
          //         fontSize: 14,
          //         color: colorScheme.onSurface.withOpacity(0.7),
          //       ),
          //     ),
          //     value: _notificationsEnabled,
          //     onChanged: (val) => setState(() => _notificationsEnabled = val),
          //   ),
          // ),
          // const SizedBox(height: 20),

          // 👤 Profile Navigation
          Text(
            "👤 Account",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.person, size: 28),
              title: Text("Profile", style: GoogleFonts.inter(fontSize: 16)),
              subtitle: Text(
                "View or edit your profile information",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ),
        ],
      ),
    );
  }
}
