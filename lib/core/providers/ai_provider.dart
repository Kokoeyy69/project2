import 'package:neopay_ai/core/providers/currency_provider.dart';
import 'package:neopay_ai/core/services/gemini_ai_service.dart';
import 'package:neopay_ai/core/services/exchange_rate_model.dart';
import 'package:neopay_ai/core/services/security_service.dart';
import 'package:neopay_ai/services/api_service.dart';
import 'package:neopay_ai/services/hive_cache_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../config/env.dart';
import '../di/locator.dart';

/// Transfer status untuk signaling ke UI
enum TransferStatus {
  success,
  failed,
  requiresVerification,
  cancelled,
}

/// Provider for AI chat functionality with transfer intent detection
class AIProvider extends ChangeNotifier {
  final GeminiAiService _aiService = locator<GeminiAiService>();
  CurrencyProvider? _currencyProvider;

  final List<ChatMessage> _messages = [];
  int _usageCount = 0;
  bool _isLoading = false;
  bool _isInitialized = false;
  TransferIntent? _pendingTransfer;
  String? _error;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  int get usageCount => _usageCount;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  TransferIntent? get pendingTransfer => _pendingTransfer;
  String? get error => _error;

  /// Initialize AI provider
  Future<void> init({CurrencyProvider? currencyProvider}) async {
    if (_isInitialized) return;

    _currencyProvider = currencyProvider;

    try {
      final cachedKey = HiveCacheService.get('gemini_api_key') as String?;
      final apiKey = cachedKey?.isNotEmpty == true
          ? cachedKey
          : Env.geminiApiKey;
      await _aiService.init(apiKey: apiKey);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Send message to AI
  Future<void> sendMessage(String message) async {
    if (!_isInitialized) {
      _error = 'AI service not initialized';
      notifyListeners();
      return;
    }

    _addMessage(ChatMessage.user(message));
    _isLoading = true;
    _pendingTransfer = null;
    notifyListeners();

    try {
      final response = await _aiService.sendMessage(
        message,
        currencyProvider: _currencyProvider,
      );

      _addMessage(response);
      _usageCount++;

      if (response.transferIntent != null) {
        _pendingTransfer = response.transferIntent;
      }
    } catch (e) {
      _error = e.toString();
      _addMessage(ChatMessage.ai('Maaf, terjadi kesalahan. Coba lagi ya!'));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Confirm transfer - returns status, NOT dialog
  /// UI harus handle status ini dan show dialog jika diperlukan
  Future<TransferStatus> confirmTransfer() async {
    if (_pendingTransfer == null) return TransferStatus.cancelled;

    final security = locator<SecurityService>();
    if (!security.isAuthenticated) {
      // Return status, jangan show dialog di sini
      return TransferStatus.requiresVerification;
    }

    final intent = _pendingTransfer!;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return TransferStatus.failed;

    try {
      final api = locator<ApiService>();
      final res = await api.processTransfer(
        TransferRequest(
          senderUid: currentUser.uid,
          recipientUid: '',
          recipientName: intent.recipientName ?? 'Unknown',
          amount: intent.amount,
          senderName: currentUser.displayName ?? 'User',
        ),
      );

      if (res.success) {
        _addMessage(
          ChatMessage.ai(
            '✅ Sukses! Rp ${intent.amount} terkirim ke ${intent.recipientName}. '
            'Karena ini transaksi berisiko tinggi, dana Anda sementara diamankan di Escrow Vault selama 1 jam.',
          ),
        );
        _pendingTransfer = null;
        notifyListeners();
        return TransferStatus.success;
      } else {
        _addMessage(
          ChatMessage.ai('❌ Transfer gagal: ${res.message}'),
        );
        _pendingTransfer = null;
        notifyListeners();
        return TransferStatus.failed;
      }
    } catch (e) {
      _addMessage(ChatMessage.ai('❌ Error: ${e.toString()}'));
      _pendingTransfer = null;
      notifyListeners();
      return TransferStatus.failed;
    }
  }

  /// Cancel transfer
  void cancelTransfer() {
    if (_pendingTransfer == null) return;

    _addMessage(
      ChatMessage.ai(
        '❌ Transfer dibatalkan.\n\n'
        'Ada yang lain yang bisa gua bantu?',
      ),
    );

    _pendingTransfer = null;
    notifyListeners();
  }

  /// Clear chat history
  void clearChat() {
    _messages.clear();
    _pendingTransfer = null;
    _error = null;
    _aiService.resetChat();
    notifyListeners();
  }

  void _addMessage(ChatMessage message) {
    _messages.add(message);
  }

  String? getTransferSummary() {
    if (_pendingTransfer == null) return null;

    final intent = _pendingTransfer!;
    final symbol = SupportedCurrencies.getSymbol(intent.currency);

    if (intent.needsConversion) {
      final targetSymbol = SupportedCurrencies.getSymbol(
        intent.convertedCurrency!,
      );
      return 'Transfer Summary:\n'
          '• Amount: $symbol${intent.amount.toStringAsFixed(0)} ${intent.currency}\n'
          '• Converted: $targetSymbol${intent.convertedAmount!.toStringAsFixed(0)} ${intent.convertedCurrency}\n'
          '• Rate: 1 ${intent.currency} = ${intent.exchangeRate!.toStringAsFixed(2)} ${intent.convertedCurrency}\n'
          '• Recipient: ${intent.recipientName}';
    }

    return 'Transfer Summary:\n'
        '• Amount: $symbol${intent.amount.toStringAsFixed(0)} ${intent.currency}\n'
        '• Recipient: ${intent.recipientName}';
  }

  bool get isReady => _aiService.isReady;

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}