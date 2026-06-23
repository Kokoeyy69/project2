import 'package:get_it/get_it.dart';

import '../../repositories/firestore_transactions_repository.dart';
import '../../repositories/users_repository.dart';
import '../../services/api_service.dart';
import '../services/app_lock_service.dart';
import '../services/exchange_rate_service.dart';
import '../services/fraud_shield_service.dart';
import '../services/gemini_ai_service.dart';
import '../services/security_service.dart';
import '../services/transaction_auth_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  if (!locator.isRegistered<ApiService>()) {
    locator.registerLazySingleton(() => ApiService());
  }
  if (!locator.isRegistered<SecurityService>()) {
    locator.registerLazySingleton(() => SecurityService());
  }
  if (!locator.isRegistered<AppLockService>()) {
    locator.registerLazySingleton(() => AppLockService());
  }
  if (!locator.isRegistered<TransactionAuthService>()) {
    locator.registerLazySingleton(() => TransactionAuthService());
  }
  if (!locator.isRegistered<FraudShieldService>()) {
    locator.registerLazySingleton(() => FraudShieldService());
  }
  if (!locator.isRegistered<GeminiAiService>()) {
    locator.registerLazySingleton(() => GeminiAiService());
  }
  if (!locator.isRegistered<ExchangeRateService>()) {
    locator.registerLazySingleton(() => ExchangeRateService());
  }
  if (!locator.isRegistered<FirestoreTransactionsRepository>()) {
    locator.registerLazySingleton(() => FirestoreTransactionsRepository());
  }
  if (!locator.isRegistered<UsersRepository>()) {
    locator.registerLazySingleton(() => UsersRepository());
  }
}
