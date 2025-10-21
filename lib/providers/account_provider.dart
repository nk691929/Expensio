import 'package:animationandcharts/models/account_model.dart';
import 'package:animationandcharts/services/account_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// ✅ Repository provider
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

/// ✅ Stream provider for all accounts of a user
final accountsStreamProvider = StreamProvider.family<List<Account>, String>((
  ref,
  userId,
) {
  return ref.read(accountRepositoryProvider).getAccounts(userId);
});

/// ✅ StateNotifier for single account CRUD actions
class AccountNotifier extends StateNotifier<AsyncValue<Account?>> {
  final AccountRepository _repository;

  AccountNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createAccount(Account account) async {
    state = const AsyncValue.loading();
    try {
      // Use Firestore auto ID
      await _repository.createAccount(account);
      state = AsyncValue.data(account);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> fetchAccount(String accountId) async {
    state = const AsyncValue.loading();
    try {
      final acc = await _repository.getAccountById(accountId);
      state = AsyncValue.data(acc);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateAccount(Account account) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateAccount(account);
      state = AsyncValue.data(account);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAccount(String accountId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteAccount(accountId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // you can also handle UI toast here
    }
  }

  Future<void> changeBalance(String accountId, double delta) async {
    try {
      await _repository.updateAccountBalance(
        accountId: accountId,
        delta: delta,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// ✅ Provider for AccountNotifier
final accountNotifierProvider =
    StateNotifierProvider<AccountNotifier, AsyncValue<Account?>>((ref) {
      return AccountNotifier(ref.read(accountRepositoryProvider));
    });
