import 'package:flutter/foundation.dart';
import 'package:neopay_ai/core/providers/currency_provider.dart';
import 'package:neopay_ai/core/services/gemini_ai_service.dart';
import 'package:neopay_ai/core/services/exchange_rate_model.dart';
import 'package:neopay_ai/core/services/security_service.dart';
import 'package:neopay_ai/services/hive_cache_service.dart';
import '../config/env.dart';

/// Provider for AI chat functionality with transfer intent detection
/// 
/// This provider manages:
/// - Chat history and message state
/// - AI service initialization and communication
/// - Transfer intent detection and confirmation state
/// - Integration with CurrencyProvider for conversions
/// 
/// Usage in widgets:
/// ```dart
/// final aiProvider = context.watch<AIProvider>();
/// aiProvider.sendMessage('Transfer 500 USD to Ahmad');
/// 
/// // Listen for transfer intents
/// if (aiProvider.pendingTransfer != null) {
///   showTransferConfirmation(aiProvider.pendingTransfer!);
/// }
/// ```
class AIProvider extends ChangeNotifier {
  final GeminiAiService _aiService = GeminiAiService.instance;
  CurrencyProvider? _currencyProvider;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  TransferIntent? _pendingTransfer;
  String? _error;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  TransferIntent? get pendingTransfer => _pendingTransfer;
  String? get error => _error;

  /// Initialize the AI provider
  /// Call this on app startup or when entering AI chat
  Future<void> init({CurrencyProvider? currencyProvider}) async {
    if (_isInitialized) return;

    _currencyProvider = currencyProvider;

    try {
      // Get Gemini API key from Hive cache, fallback to env.json
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

  /// Send a message to the AI and get a response
  /// If the AI detects a transfer intent, it will be stored in pendingTransfer
  Future<void> sendMessage(String message) async {
    if (!_isInitialized) {
      _error = 'AI service not initialized';
      notifyListeners();
      return;
    }

    // Add user message
    _addMessage(ChatMessage.user(message));
    _isLoading = true;
    _pendingTransfer = null; // Clear previous pending transfer
    notifyListeners();

    try {
      final response = await _aiService.sendMessage(
        message,
        currencyProvider: _currencyProvider,
      );

      _addMessage(response);

      // If there's a transfer intent, store it
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

  /// Confirm and execute the pending transfer with security check
  /// Returns true if successful
  Future<bool> confirmTransfer() async {
    if (_pendingTransfer == null) return false;

    // Security: require authentication before executing transfer
    final security = SecurityService.instance;
    if (!security.isAuthenticated) {
      _addMessage(ChatMessage.ai(
        '🔒 Untuk keamanan, silakan autentikasi terlebih dahulu sebelum melanjutkan transfer.',
      ));
      notifyListeners();
      return false;
    }

    // Add confirmation message
    _addMessage(ChatMessage.ai(
      '✅ Transfer sedang diproses...\n\n'
      'Mengirim ${_pendingTransfer!.amount} ${_pendingTransfer!.currency} ke ${_pendingTransfer!.recipientName}',
    ));

    // Clear pending transfer
    _pendingTransfer = null;
    notifyListeners();

    return true;
  }

  /// Cancel the pending transfer
  void cancelTransfer() {
    if (_pendingTransfer == null) return;

    _addMessage(ChatMessage.ai(
      '❌ Transfer dibatalkan.\n\n'
      'Ada yang lain yang bisa gua bantu?',
    ));

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

  /// Add a message to the chat history
  void _addMessage(ChatMessage message) {
    _messages.add(message);
  }

  /// Get a formatted summary of the pending transfer for display
  String? getTransferSummary() {
    if (_pendingTransfer == null) return null;

    final intent = _pendingTransfer!;
    final symbol = SupportedCurrencies.getSymbol(intent.currency);

    if (intent.needsConversion) {
      final targetSymbol = SupportedCurrencies.getSymbol(intent.convertedCurrency!);
      return 'Transfer Summary:\n'
          '• Amount: ${symbol}${intent.amount.toStringAsFixed(0)} ${intent.currency}\n'
          '• Converted: ${targetSymbol}${intent.convertedAmount!.toStringAsFixed(0)} ${intent.convertedCurrency}\n'
          '• Rate: 1 ${intent.currency} = ${intent.exchangeRate!.toStringAsFixed(2)} ${intent.convertedCurrency}\n'
          '• Recipient: ${intent.recipientName}';
    }

    return 'Transfer Summary:\n'
        '• Amount: ${symbol}${intent.amount.toStringAsFixed(0)} ${intent.currency}\n'
        '• Recipient: ${intent.recipientName}';
  }

  /// Check if AI service is ready
  bool get isReady => _aiService.isReady;

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}