import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:neopay_ai/core/providers/currency_provider.dart';
import 'package:neopay_ai/services/hive_cache_service.dart';

/// HomeViewModel manages the user's balance and currency conversions.
/// 
/// The base currency is IDR (stored in Firestore as 'balance').
/// USD and CNY balances are calculated dynamically using CurrencyProvider.
class HomeViewModel extends ChangeNotifier {
  double _balance = 0.0; // Base currency: IDR
  double _balanceUsd = 0.0; // Calculated from IDR using CurrencyProvider
  double _balanceCny = 0.0; // Calculated from IDR using CurrencyProvider
  bool _isLoading = true;
  bool _hasError = false;
  String? _error;
  
  final CurrencyProvider _currencyProvider;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  double get balance => _balance;
  double get balanceUsd => _balanceUsd;
  double get balanceCny => _balanceCny;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get error => _error;

  HomeViewModel({CurrencyProvider? currencyProvider})
      : _currencyProvider = currencyProvider ?? CurrencyProvider();

  /// Start listening to Firestore balance updates
  Future<void> start() async {
    _isLoading = true;
    notifyListeners();

    // Initialize currency provider if needed
    if (!_currencyProvider.hasRates) {
      try {
        await _currencyProvider.init();
      } catch (e) {
        debugPrint('[HomeViewModel] CurrencyProvider init error: $e');
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoading = false;
      _hasError = true;
      _error = 'Not signed in';
      notifyListeners();
      return;
    }

    final cached = HiveCacheService.getCachedBalance();
    if (cached != null) {
      _balance = cached;
      _recalculateConvertedBalances();
    }

    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snap) async {
            if (!snap.exists) return;
            final data = snap.data();
            // Only read base balance (IDR) from Firestore
            _balance = (data?['balance'] as num?)?.toDouble() ?? 0.0;
            
            // Calculate USD and CNY dynamically using CurrencyProvider
            _recalculateConvertedBalances();
            
            try {
              await HiveCacheService.setCachedBalance(_balance);
            } catch (_) {}
            _isLoading = false;
            _hasError = false;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            _isLoading = false;
            _hasError = true;
            _error = e.toString();
            notifyListeners();
          },
        );
  }

  /// Refresh balance data from Firestore
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoading = false;
      _hasError = true;
      _error = 'Not signed in';
      notifyListeners();
      return;
    }
    try {
      // Refresh exchange rates if stale
      await _currencyProvider.refreshIfStale();
      
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snap.data();
      // Only read base balance (IDR) from Firestore
      _balance = (data?['balance'] as num?)?.toDouble() ?? 0.0;
      
      // Calculate USD and CNY dynamically
      _recalculateConvertedBalances();
      
      await HiveCacheService.setCachedBalance(_balance);
      _hasError = false;
      _error = null;
    } catch (e) {
      _hasError = true;
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Recalculate USD and CNY balances from the base IDR balance
  /// using the current exchange rates from CurrencyProvider.
  void _recalculateConvertedBalances() {
    // Formula: balanceUsd = balance (IDR) * (usdRate / idrRate)
    // This is equivalent to: balanceIDR / idrPerUsd
    _balanceUsd = _currencyProvider.convert(_balance, 'IDR', 'USD');
    _balanceCny = _currencyProvider.convert(_balance, 'IDR', 'CNY');
  }

  /// Convert a foreign currency amount to IDR before adding to balance.
  /// Use this for top-up logic when user tops up in USD or CNY.
  double convertToBaseCurrency(double amount, String currency) {
    return _currencyProvider.convert(amount, currency, 'IDR');
  }

  /// Get the current exchange rate between two currencies
  double? getExchangeRate(String from, String to) {
    return _currencyProvider.getRate(from, to);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}