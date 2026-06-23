import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../services/api_service.dart';
import '../../core/di/locator.dart';
import '../../core/services/exchange_rate_service.dart';

class TransferViewModel extends ChangeNotifier {
  String _displayAmount = 'Rp0';
  String get displayAmount => _displayAmount;

  double _numericAmount = 0.0;
  double get numericAmount => _numericAmount;

  String _selectedContactId = '';
  String get selectedContactId => _selectedContactId;

  String _selectedContactName = '';
  String get selectedContactName => _selectedContactName;

  String _selectedCurrency = 'IDR';
  String get selectedCurrency => _selectedCurrency;

  String _targetCurrency = 'USD';
  String get targetCurrency => _targetCurrency;

  bool _isTransferLoading = false;
  bool get isTransferLoading => _isTransferLoading;

  String? _qrErrorMessage;
  String? get qrErrorMessage => _qrErrorMessage;

  final NumberFormat _currencyFormatIdr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  final ApiService _apiService = locator<ApiService>();
  final ExchangeRateService _exchangeRateService = locator<ExchangeRateService>();

  // Rate Limiting: Track last transfer attempt
  DateTime? _lastTransferAttempt;
  static const Duration _rateLimitDuration = Duration(seconds: 5);

  // Exchange rates (dynamically loaded from service)
  Map<String, double> get rates => _exchangeRateService.rates;

  // Initialize exchange rates on ViewModel creation
  TransferViewModel() {
    _exchangeRateService.loadRates();
  }

  /// Update display format based on wallet index (0=IDR, 1=USD, 2=CNY)
  void updateCurrencyFormat(int walletIndex) {
    _updateDisplay();
    notifyListeners();
  }

  // Fungsi untuk menambah angka yang dipanggil UI
  void appendDigit(String key) {
    HapticFeedback.lightImpact();
    _appendNumber(key);
    _updateDisplay();
    notifyListeners();
  }

  // Fungsi untuk menghapus 1 angka dari belakang (backspace)
  void removeLastDigit() {
    HapticFeedback.lightImpact();
    _handleBackspace();
    _updateDisplay();
    notifyListeners();
  }

  // Fungsi untuk mereset angka jadi 0 (clear)
  void clearAmount() {
    HapticFeedback.lightImpact();
    _numericAmount = 0.0;
    _updateDisplay();
    notifyListeners();
  }

  void _handleBackspace() {
    String currentAmount = _numericAmount.toStringAsFixed(0);
    if (currentAmount.length > 1) {
      currentAmount = currentAmount.substring(0, currentAmount.length - 1);
    } else {
      currentAmount = '0';
    }
    _numericAmount = double.parse(currentAmount);
  }

  void _appendNumber(String number) {
    String currentAmount = _numericAmount.toStringAsFixed(0);

    // Batasi maksimal 12 digit (ratusan miliar) biar layout gak jebol
    if (currentAmount.length >= 12) return;

    if (currentAmount == '0' && number != '0') {
      currentAmount = number;
    } else if (currentAmount != '0') {
      currentAmount += number;
    }
    _numericAmount = double.parse(currentAmount);
  }

  void _updateDisplay() {
    _displayAmount = _currencyFormatIdr.format(_numericAmount);
  }

  void setSelectedContact(String id, String name) {
    _selectedContactId = id;
    _selectedContactName = name;
    notifyListeners();
  }

  void setSelectedCurrency(String currency) {
    _selectedCurrency = currency;
    notifyListeners();
  }

  void setTargetCurrency(String currency) {
    _targetCurrency = currency;
    notifyListeners();
  }

  void toggleCurrencies() {
    final tmp = _selectedCurrency;
    _selectedCurrency = _targetCurrency;
    _targetCurrency = tmp;
    notifyListeners();
  }

  double _getConvertedAmount() {
    if (_numericAmount == 0) return 0.0;
    if (_selectedCurrency == _targetCurrency) return _numericAmount;
    final key = '${_selectedCurrency}_$_targetCurrency';
    final rate = rates[key] ?? 1.0;
    return _numericAmount * rate;
  }

  String _formatConvertedAmount(double amount) {
    if (amount >= 1000) {
      return amount
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return amount.toStringAsFixed(2);
  }

  String get formattedConvertedAmount =>
      _formatConvertedAmount(_getConvertedAmount());

  double get convertedAmount => _getConvertedAmount();

  bool get isTransferReady {
    return _numericAmount > 0 &&
        _selectedContactId.isNotEmpty &&
        !_isTransferLoading;
  }

   Future<bool> processTransfer() async {
      if (!isTransferReady) return false;

      // Rate Limiting: Check if too soon since last transfer attempt
      final now = DateTime.now();
      if (_lastTransferAttempt != null) {
        final timeSinceLastAttempt = now.difference(_lastTransferAttempt!);
        if (timeSinceLastAttempt < _rateLimitDuration) {
          debugPrint('[TransferViewModel] Rate limit triggered. Last attempt: $timeSinceLastAttempt ago.');
          // UI message: "Mohon tunggu beberapa saat sebelum melakukan transfer lagi."
          return false;
        }
      }
      _lastTransferAttempt = now;

      // Check for self-transfer (Identity Mapping Bug)
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == _selectedContactId) {
        debugPrint('[TransferViewModel] Self-transfer blocked.');
        return false;
      }

      // TASK 2: Recipient Validation - Validate recipient exists in Firestore
      try {
        final recipientDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_selectedContactId)
            .get();

        if (!recipientDoc.exists) {
          debugPrint('[TransferViewModel] Recipient account not found in database.');
          _isTransferLoading = false;
          notifyListeners();
          return false;
        }
      } catch (e) {
        debugPrint('[TransferViewModel] Recipient validation error: $e');
        _isTransferLoading = false;
        notifyListeners();
        return false;
      }

      _isTransferLoading = true;
      notifyListeners();

      try {
        // TASK 1: Idempotency Key - Generate unique key to prevent duplicate transfers
        final String idempotencyKey = const Uuid().v4();
        debugPrint('[TransferViewModel] Generated idempotency key: $idempotencyKey');

        final transferReq = TransferRequest(
          senderUid: currentUid ?? '',
          recipientUid: _selectedContactId,
          amount: _numericAmount,
          recipientName: _selectedContactName,
          senderName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          idempotencyKey: idempotencyKey,
        );

        final res = await _apiService.processTransfer(transferReq);

        _isTransferLoading = false;
        notifyListeners();

        return res.success;
      } on DioException catch (e) {
        // Timeout Handling: Specific error messages for timeout scenarios
        debugPrint('[TransferViewModel] DioException: ${e.type}');

        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          debugPrint('[TransferViewModel] Connection timeout detected.');
          // UI message: "Koneksi terputus. Mohon periksa riwayat transaksi Anda sebelum mencoba lagi."
          _isTransferLoading = false;
          notifyListeners();
          return false;
        }

        // Other Dio exceptions
        debugPrint('[TransferViewModel] Transfer error: ${e.error}');
        _isTransferLoading = false;
        notifyListeners();
        return false;
      } catch (e) {
        debugPrint('[TransferViewModel] Transfer error: $e');
        _isTransferLoading = false;
        notifyListeners();
        return false;
      }
    }

  void clearQrErrorMessage() {
    _qrErrorMessage = null;
    notifyListeners();
  }

  void resetTransferState() {
    _isTransferLoading = false;
    notifyListeners();
  }

  Future<void> processQrPayload(String qrData) async {
    if (qrData.trim().isEmpty) {
      _qrErrorMessage = 'Kode QR tidak valid atau Pengguna tidak ditemukan';
      notifyListeners();
      return;
    }

    _isTransferLoading = true;
    notifyListeners();

    String targetUid = '';
    double? targetAmount;

    try {
      final Map<String, dynamic> decoded = jsonDecode(qrData);
      targetUid = decoded['uid'] ?? '';
      if (decoded['amount'] != null) {
        targetAmount = double.tryParse(decoded['amount'].toString());
      }
    } catch (e) {
      // FormatException: Static QR (Plain UID)
      targetUid = qrData.trim();
    }

    targetUid = targetUid.trim();

    // TASK 2: QR Payload Validation - Hardening omni-QR parser with regex + length checks
    if (targetUid.isEmpty || targetUid.length < 5) {
      _qrErrorMessage = 'Format QR tidak valid atau tidak dikenali';
      _isTransferLoading = false;
      notifyListeners();
      return;
    }

    // Validate UID format: only alphanumeric, dash, and underscore allowed
    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(targetUid)) {
      _qrErrorMessage = 'Format QR tidak valid atau tidak dikenali';
      _isTransferLoading = false;
      notifyListeners();
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userName = userData['fullName'] ?? userData['displayName'] ?? 'User';

        setSelectedContact(targetUid, userName);

        if (targetAmount != null && targetAmount > 0) {
          _numericAmount = targetAmount;
          _updateDisplay();
        }
      } else {
        // Reset state if user not found
        _selectedContactId = '';
        _selectedContactName = '';
        _numericAmount = 0.0;
        _updateDisplay();
        _qrErrorMessage = 'Kode QR tidak valid atau Pengguna tidak ditemukan';
        debugPrint('[TransferViewModel] QR User not found: $targetUid');
      }
    } catch (e) {
      _selectedContactId = '';
      _selectedContactName = '';
      _numericAmount = 0.0;
      _updateDisplay();
      _qrErrorMessage = 'Kode QR tidak valid atau Pengguna tidak ditemukan';
      debugPrint('[TransferViewModel] QR Process error: $e');
    } finally {
      _isTransferLoading = false;
      notifyListeners();
    }
  }
}
