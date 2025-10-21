import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

final userTransactionsProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, userId) {
  final service = ref.watch(transactionServiceProvider);
  return service.listenToUserTransactions(userId);
});

final userTransactionsFutureProvider =
    FutureProvider.family<List<TransactionModel>, String>((ref, userId) async {
  final service = ref.watch(transactionServiceProvider);
  return service.getUserTransactions(userId);
});
