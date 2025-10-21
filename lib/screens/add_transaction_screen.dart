import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/category_provider.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final String userId;
  final TransactionModel? transaction; // null → Add mode, non-null → Edit mode

  const AddEditTransactionScreen({
    super.key,
    required this.userId,
    this.transaction,
  });

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _transactionType = "Expense";
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();

  bool _saving = false;
  final uuid = const Uuid();

  bool get isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final tx = widget.transaction!;
      _titleController.text = tx.title;
      _descriptionController.text = tx.description ?? '';
      _amountController.text = tx.amount.abs().toString();
      _transactionType = tx.amount >= 0 ? "Income" : "Expense";
      _selectedCategoryId = tx.categoryId;
      _selectedAccountId = tx.accountId;
      _selectedDate = tx.date;
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveOrUpdateTransaction() async {
  if (!_formKey.currentState!.validate()) return;
  if (_selectedAccountId == null || _selectedCategoryId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select account and category")),
    );
    return;
  }

  setState(() => _saving = true);

  final double amount = double.tryParse(_amountController.text) ?? 0.0;
  final double finalAmount =
      _transactionType.toLowerCase() == "income" ? amount : -amount;
  final now = DateTime.now();

  final tx = TransactionModel(
    id: isEdit ? widget.transaction!.id : uuid.v4(),
    userId: widget.userId,
    accountId: _selectedAccountId!,
    categoryId: _selectedCategoryId!,
    title: _titleController.text.trim(),
    description: _descriptionController.text.trim().isEmpty
        ? ''
        : _descriptionController.text.trim(),
    amount: finalAmount.abs(),
    type: _transactionType,
    date: _selectedDate,
    createdAt: isEdit ? widget.transaction!.createdAt : now,
    updatedAt: now,
  );

  try {
    final accountNotifier = ref.read(accountNotifierProvider.notifier);

    if (isEdit) {
      // 1️⃣ Revert old transaction's effect
      final oldTx = widget.transaction!;
      final oldAmount =
          oldTx.type.toLowerCase() == "income" ? oldTx.amount : -oldTx.amount;

      // If account was changed, revert from old account and apply to new
      if (oldTx.accountId != _selectedAccountId) {
        // revert old account
         accountNotifier.changeBalance(oldTx.accountId, -oldAmount);
        // apply new account
         accountNotifier.changeBalance(_selectedAccountId!, finalAmount);
      } else {
        // same account → just adjust the difference
        final double difference = finalAmount - oldAmount;
         accountNotifier.changeBalance(_selectedAccountId!, difference);
      }

      // 2️⃣ Update transaction
       ref.read(transactionServiceProvider).updateTransaction(tx);
    } else {
      // ➕ New transaction: directly adjust balance
       accountNotifier.changeBalance(_selectedAccountId!, finalAmount);

      // 💾 Create transaction
       ref.read(transactionServiceProvider).createTransaction(tx);
    }

    if (mounted) Navigator.pop(context, tx);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Failed to ${isEdit ? "update" : "save"} transaction: $e",
        ),
      ),
    );
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accountsAsync = ref.watch(accountsStreamProvider(widget.userId));
    final categoriesAsync = ref.watch(
      userCategoriesStreamProvider(widget.userId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? "Edit Transaction" : "Add Transaction",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Transaction Type",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: "Income",
                    label: Text("Income"),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: "Expense",
                    label: Text("Expense"),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_transactionType},
                onSelectionChanged: (val) =>
                    setState(() => _transactionType = val.first),
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Title",
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? "Please enter a title"
                    : null,
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? "Enter amount" : null,
              ),
              const SizedBox(height: 16),

              // Category
              categoriesAsync.when(
                data: (cats) {
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: "Category",
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: cats
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                    validator: (val) =>
                        val == null ? "Select a category" : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  "Error loading categories: $e",
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
              const SizedBox(height: 16),

              // Account
              accountsAsync.when(
                data: (accs) {
                  return DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    decoration: InputDecoration(
                      labelText: "Account",
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: accs
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedAccountId = val),
                    validator: (val) =>
                        val == null ? "Select an account" : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  "Error loading accounts: $e",
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
              const SizedBox(height: 16),

              // Date picker
              InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Date",
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description",
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveOrUpdateTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isEdit ? "Updating..." : "Saving...",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              isEdit ? "Save Changes" : "Add Transaction",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: colorScheme.onPrimary
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
