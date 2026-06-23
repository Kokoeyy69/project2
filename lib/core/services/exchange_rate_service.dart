import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ExchangeRateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default hardcoded rates as fallback
  final Map<String, double> _rates = {
    'IDR_USD': 0.000064,
    'IDR_CNY': 0.000463,
    'USD_IDR': 15625.0,
    'USD_CNY': 7.24,
    'CNY_IDR': 2159.0,
    'CNY_USD': 0.138,
  };

  Map<String, double> get rates => Map.unmodifiable(_rates);

  /// Load rates from Firestore
  Future<void> loadRates() async {
    try {
      debugPrint('[ExchangeRateService] Loading rates from Firestore...');
      final doc = await _firestore.collection('config').doc('exchange_rates').get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data.forEach((key, value) {
          if (value is num) {
            _rates[key] = value.toDouble();
          }
        });
        debugPrint('[ExchangeRateService] Rates updated from Firestore: $_rates');
      } else {
        debugPrint('[ExchangeRateService] No rates found in Firestore, using fallbacks.');
        // Optionally create the document with defaults if it doesn't exist
        // await _firestore.collection('config').doc('exchange_rates').set(_rates);
      }
    } catch (e) {
      debugPrint('[ExchangeRateService] Error loading rates: $e. Using fallbacks.');
    }
  }

  /// Manually update a specific rate (for testing or admin purposes)
  void updateRate(String pair, double rate) {
    _rates[pair] = rate;
  }
}