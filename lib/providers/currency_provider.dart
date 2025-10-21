import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/currency_model.dart';
import '../services/currency_service.dart';

/// 🛠️ Provide the CurrencyService
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});

/// 📡 Stream provider: listen to user's selected currency in real time
final userCurrencyProvider = StreamProvider.family<CurrencyModel?, String>((ref, userId) {
  return ref.watch(currencyServiceProvider).listenToUserCurrency(userId);
});

/// 📦 Future provider: get user's selected currency once
final userCurrencyFutureProvider = FutureProvider.family<CurrencyModel?, String>((ref, userId) {
  return ref.watch(currencyServiceProvider).getUserCurrency(userId);
});
