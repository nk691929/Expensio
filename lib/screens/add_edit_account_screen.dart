import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/account_model.dart';
import '../providers/account_provider.dart';

class AddEditAccountScreen extends ConsumerStatefulWidget {
  final Account? account;
  final String userId;

  const AddEditAccountScreen({super.key, this.account, required this.userId});

  @override
  ConsumerState<AddEditAccountScreen> createState() =>
      _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends ConsumerState<AddEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _holderController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();

  Color selectedColor = Colors.indigo;
  IconData? selectedLogo;
  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _holderController.text = widget.account!.holder ?? '';
      _numberController.text = widget.account!.number ?? '';
      _balanceController.text = widget.account!.balance.toString();
      selectedColor = Color(widget.account!.colorValue);
      selectedLogo = _stringToIcon(widget.account!.logo);
    }
  }

  String _iconToString(IconData icon) {
    if (icon == Icons.account_balance) return "account_balance";
    if (icon == Icons.savings) return "savings";
    if (icon == Icons.credit_card) return "credit_card";
    if (icon == Icons.wallet) return "wallet";
    if (icon == Icons.attach_money) return "attach_money";
    return "account_balance_wallet";
  }

  IconData _stringToIcon(String name) {
    switch (name) {
      case "account_balance":
        return Icons.account_balance;
      case "savings":
        return Icons.savings;
      case "credit_card":
        return Icons.credit_card;
      case "wallet":
        return Icons.wallet;
      case "attach_money":
        return Icons.attach_money;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final double balance = double.tryParse(_balanceController.text) ?? 0.0;

    print("acc id ${widget.account?.id}  and user id by using widget id ${widget.userId} \n and here is diectly getted id from firebase ${FirebaseAuth.instance.currentUser!.uid} ");
    final account = Account(
      id: widget.account?.id ?? 'acc_${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.userId,
      name: _nameController.text,
      holder: _holderController.text.isEmpty ? null : _holderController.text,
      number: _numberController.text.isEmpty ? null : _numberController.text,
      balance: balance,
      colorValue: selectedColor.value,
      logo: _iconToString(selectedLogo ?? Icons.account_balance_wallet),
      createdAt: widget.account?.createdAt ?? now,
      updatedAt: now,
    );

    print("After update \n name: ${account.name} \n id: ${account.id} \n userid: ${account.userId} \n balance: ${account.balance} \n colorval: ${account.colorValue} \n logo: ${account.logo} \n createdAt: ${account.createdAt}  \n updatedAt: ${account.updatedAt}");

    final notifier = ref.read(accountNotifierProvider.notifier);
    if (widget.account == null) {
      await notifier.createAccount(account);
    } else {
      await notifier.updateAccount(account);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.account != null ? "Edit Account" : "Add Account",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Account Name",
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter account name" : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _holderController,
                decoration: InputDecoration(
                  labelText: "Holder Name",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Account Number",
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                enabled:  false,
                
                decoration: InputDecoration(
                  labelText: widget.account!=null?"Balance": "Intialize balance with Income",                  
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                // validator: (v) =>
                //     v == null || v.isEmpty ? "Enter balance" : null,
              ),
              const SizedBox(height: 25),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Choose Color",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var color in [
                    Colors.indigo,
                    Colors.teal,
                    Colors.deepPurple,
                    Colors.orange,
                    Colors.redAccent,
                    Colors.green,
                    Colors.blueGrey,
                  ])
                    GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color
                                ? colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 25),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Choose Logo",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                children: [
                  for (var logo in [
                    Icons.account_balance,
                    Icons.savings,
                    Icons.credit_card,
                    Icons.wallet,
                    Icons.attach_money,
                  ])
                    GestureDetector(
                      onTap: () => setState(() => selectedLogo = logo),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selectedLogo == logo
                              ? colorScheme.primary.withOpacity(0.15)
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedLogo == logo
                                ? colorScheme.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Icon(
                          logo,
                          size: 32,
                          color: selectedLogo == logo
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 40),

              Consumer(
                builder: (context, ref, child) {
                  final accountState = ref.watch(accountNotifierProvider);

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: accountState.isLoading ? null : _saveAccount,
                      child: accountState.isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  widget.account != null
                                      ? "Updating..."
                                      : "Saving...",
                                  style: GoogleFonts.inter(fontSize: 17),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save),
                                const SizedBox(width: 8),
                                Text(
                                  widget.account != null
                                      ? "Update Account"
                                      : "Save Account",
                                  style: GoogleFonts.inter(fontSize: 17),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
