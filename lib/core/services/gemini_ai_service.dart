import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:neopay_ai/core/config/env.dart';
import 'package:neopay_ai/core/providers/currency_provider.dart';
import 'package:neopay_ai/core/services/exchange_rate_model.dart';
import 'package:neopay_ai/repositories/firestore_transactions_repository.dart';
import 'package:neopay_ai/core/di/locator.dart';

/// Transfer intent detected by AI
/// This is the bridge between AI function calling and the transfer system
class TransferIntent {
  final double amount;
  final String currency;
  final String? recipientName;
  final String? recipientId;
  final double? convertedAmount;
  final String? convertedCurrency;
  final double? exchangeRate;

  const TransferIntent({
    required this.amount,
    required this.currency,
    this.recipientName,
    this.recipientId,
    this.convertedAmount,
    this.convertedCurrency,
    this.exchangeRate,
  });

  bool get needsConversion =>
      convertedAmount != null && convertedCurrency != null;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'recipientName': recipientName,
      'recipientId': recipientId,
      'convertedAmount': convertedAmount,
      'convertedCurrency': convertedCurrency,
      'exchangeRate': exchangeRate,
      'needsConversion': needsConversion,
    };
  }

  @override
  String toString() {
    if (needsConversion) {
      return '$amount $currency → $convertedAmount $convertedCurrency to $recipientName';
    }
    return '$amount $currency to $recipientName';
  }
}

/// Chat message model for the AI chat interface
enum MessageStatus {
  none,
  escrowPending,
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final TransferIntent? transferIntent;
  final bool isProcessing;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.transferIntent,
    this.isProcessing = false,
    this.status = MessageStatus.none,
  });

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.ai(String content, {TransferIntent? intent, MessageStatus status = MessageStatus.none}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      transferIntent: intent,
      status: status,
    );
  }

  factory ChatMessage.processing() {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isProcessing: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'transferIntent': transferIntent?.toJson(),
      'isProcessing': isProcessing,
    };
  }
}

/// Gemini AI Service with Function Calling for smart transfers
///
/// This service integrates with Google's Generative AI to provide:
/// - Natural language understanding for transfer requests
/// - Function calling to detect transfer intents
/// - Automatic currency conversion suggestions
///
/// The AI is instructed to use the `initiateTransfer` function when the user
/// wants to send/transfer money. The function parameters include amount, currency,
/// and recipient name. If any parameter is missing, the AI will ask for clarification.
class GeminiAiService {
  static final GeminiAiService _instance = GeminiAiService._internal();
  factory GeminiAiService() => _instance;
  GeminiAiService._internal();

  static GeminiAiService get instance => _instance;

  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;
  String? _apiKey;
  final FirestoreTransactionsRepository _transactionsRepo =
      locator<FirestoreTransactionsRepository>();

  // Mock recipient database for demo purposes
  final Map<String, String> _mockRecipients = {
    'ahmad': 'ahmad_demo_uid',
    'ahmad fauzi': 'ahmad_demo_uid',
    'siti': 'siti_demo_uid',
    'budi': 'budi_demo_uid',
    'john': 'john_demo_uid',
    'jane': 'jane_demo_uid',
  };

  /// Default recipient currency (IDR for Indonesian users)
  static const String _defaultRecipientCurrency = 'IDR';

  /// Initialize the Gemini AI service
  Future<void> init({String? apiKey}) async {
    if (_isInitialized) return;

    // Priority: Provided apiKey, then Env.obfuscated key
    _apiKey = apiKey ?? Env.geminiApiKey;

    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint(
        '[GeminiAiService] No API key provided, AI features will be limited',
      );
      return;
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey!,
        systemInstruction: Content.system(_buildSystemInstruction()),
      );
      _chatSession = _model!.startChat();
      _isInitialized = true;
      debugPrint('[GeminiAiService] Initialized successfully');
    } catch (e) {
      debugPrint('[GeminiAiService] Initialization error: $e');
      rethrow;
    }
  }

  /// Build the system instruction for the AI
  String _buildSystemInstruction() {
    return '''
You are Neo, the intelligent AI assistant for NeoPay AI, a premium fintech application.

YOUR CORE BEHAVIOR:
- You help users with financial transactions, especially money transfers
- You speak in a friendly, professional manner with occasional Indonesian slang (e.g., "gua", "lu", "Rico")
- You always confirm transfer details before proceeding
- You inform users about exchange rates when currency conversion is needed

TRANSFER DETECTION:
When a user asks to send, transfer, or pay money, you MUST use the `initiateTransfer` function.

FUNCTION PARAMETERS:
- amount: The amount to transfer (as a number, e.g., 500000)
- currency: The currency code (e.g., 'IDR', 'USD', 'EUR')
- recipientName: The name of the recipient

MISSING INFORMATION:
- If the user doesn't specify the amount, ask: "Berapa yang mau lu kirim?"
- If the user doesn't specify the recipient, ask: "Ke siapa gua harus kirim [amount] [currency]-nya, Rico?"
- If the currency is unclear, assume IDR for Indonesian context but confirm

CURRENCY CONVERSION:
- If the user wants to send in a different currency than the recipient's local currency (IDR),
  inform them about the conversion. For example:
  "Oke, 50 USD itu sekitar Rp 800.000 dengan kurs saat ini. Mau lanjut?"

SECURITY:
- Never confirm a transfer without all required information
- Always show the total amount including any fees
- Remind users that transfers cannot be undone once confirmed

Keep responses concise and natural. Use emojis sparingly for a premium feel.
''';
  }

  /// Define the tools (function calling) for Gemini
  List<Tool> _getTools() {
    return [
      Tool(
        functionDeclarations: [
          FunctionDeclaration(
            'initiateTransfer',
            'Call this function when the user wants to send or transfer money to someone. '
                'Ensure you have the amount, currency, and recipient name before calling.',
            Schema.object(
              properties: {
                'amount': Schema.number(
                  description: 'The amount to transfer (as a numeric value)',
                ),
                'currency': Schema.string(
                  description: 'The currency code (e.g., IDR, USD, EUR)',
                ),
                'recipientName': Schema.string(
                  description: 'The name of the recipient',
                ),
              },
              requiredProperties: ['amount', 'currency', 'recipientName'],
            ),
          ),
        ],
      ),
    ];
  }

  /// Send a message and get a response with potential function calls
  Future<ChatMessage> sendMessage(
    String message, {
    CurrencyProvider? currencyProvider,
  }) async {
    if (!_isInitialized || _chatSession == null) {
      return ChatMessage.ai(
        'AI service is not initialized. Please check your API key in settings.',
      );
    }

    debugPrint('[GeminiAiService] sendMessage called: $message');

    try {
      // PHASE 2: Fetch recent transactions for context injection
      String transactionContext = '';
      try {
        final result = await _transactionsRepo.fetchPage(pageSize: 20);
        if (result.items.isNotEmpty) {
          final formattedTransactions = result.items
              .take(20)
              .map((t) {
                final dateStr = t.timestamp != null
                    ? _formatDate(t.timestamp!)
                    : 'N/A';
                final noteStr = t.recipientNote != null
                    ? ' - ${t.recipientNote}'
                    : '';
                return '[$dateStr] ${t.category}: ${t.amount} ${t.currency}$noteStr';
              })
              .join('\n');
          transactionContext =
              'Recent transaction history:\n$formattedTransactions\n\n';
        }
      } catch (e) {
        debugPrint('[GeminiAiService] Failed to fetch transactions: $e');
      }

      // DEBUG: Print data before API call
      print("DEBUG_AI_DATA: $transactionContext");

      // Inject transaction context into the message
      final contextualMessage = '${transactionContext}User message: $message';
      final transactionHistoryString = transactionContext;
      print("DEBUG_AI_DATA: $transactionHistoryString");
      print("DEBUG_AI_CONTEXT_FINAL: $contextualMessage");

      // Update tools with current rates context
      _model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: _apiKey!,
        systemInstruction: Content.system(_buildSystemInstruction()),
        tools: _getTools(),
      );
      _chatSession = _model!.startChat();

      final response = await _chatSession!.sendMessage(
        Content.text(contextualMessage),
      );

      // Check for function calls
      final functionCalls = response.functionCalls;
      if (functionCalls.isNotEmpty) {
        for (final call in functionCalls) {
          if (call.name == 'initiateTransfer') {
            final intent = await _processTransferIntent(call, currencyProvider);
            return ChatMessage.ai(
              _generateTransferConfirmation(intent),
              intent: intent,
            );
          }
        }
      }

      // Return normal text response
      final text =
          response.text ?? 'I did not understand that. Could you rephrase?';
      return ChatMessage.ai(text);
    } catch (e) {
      debugPrint('[GeminiAiService] Error: $e');
      return ChatMessage.ai(
        'Maaf, ada masalah dengan koneksi AI. Coba lagi ya!',
      );
    }
  }

  /// Process the transfer intent from function call
  Future<TransferIntent> _processTransferIntent(
    FunctionCall call,
    CurrencyProvider? currencyProvider,
  ) async {
    final args = call.args;
    final amount = (args['amount'] as num?)?.toDouble() ?? 0.0;
    final currency = (args['currency'] as String?)?.toUpperCase() ?? 'IDR';
    final recipientName = args['recipientName'] as String? ?? 'Unknown';

    // Look up recipient ID (mock)
    final recipientId = _mockRecipients[recipientName.toLowerCase()];

    // Check if conversion is needed
    double? convertedAmount;
    String? convertedCurrency;
    double? exchangeRate;

    if (currencyProvider != null && currency != _defaultRecipientCurrency) {
      convertedCurrency = _defaultRecipientCurrency;
      convertedAmount = currencyProvider.convert(
        amount,
        currency,
        convertedCurrency,
      );
      exchangeRate = currencyProvider.getRate(currency, convertedCurrency);
    }

    return TransferIntent(
      amount: amount,
      currency: currency,
      recipientName: recipientName,
      recipientId: recipientId,
      convertedAmount: convertedAmount,
      convertedCurrency: convertedCurrency,
      exchangeRate: exchangeRate,
    );
  }

  /// Generate a natural language confirmation message
  String _generateTransferConfirmation(TransferIntent intent) {
    final symbol = SupportedCurrencies.getSymbol(intent.currency);

    if (intent.needsConversion) {
      final cc = intent.convertedCurrency;
      if (cc == null) return '';
      final targetSymbol = SupportedCurrencies.getSymbol(cc);
      final rate = intent.exchangeRate;
      final rateText = rate != null
          ? '(kurs: 1 ${intent.currency} = ${rate.toStringAsFixed(2)} ${intent.convertedCurrency})'
          : '';

      final convertedAmount = intent.convertedAmount;
      if (convertedAmount == null) return '';
      return 'Oke, siap! Mau kirim $symbol${intent.amount.toStringAsFixed(0)} ${intent.currency} ke ${intent.recipientName}.\n\n'
          '💱 Dengan kurs saat ini, itu sekitar $targetSymbol${convertedAmount.toStringAsFixed(0)} ${intent.convertedCurrency}\n'
          '$rateText\n\n'
          'Lanjut transfer?';
    }

    return 'Oke, siap! Mau kirim $symbol${intent.amount.toStringAsFixed(0)} ${intent.currency} ke ${intent.recipientName}.\n\nLanjut transfer?';
  }

  /// Analyze recent transactions and return a short financial insight
  Future<String> analyzeTransactions(
    List<Map<String, dynamic>> recentTransactions,
  ) async {
    if (!_isInitialized || _model == null) {
      return 'Wah, lagi error nih. Tapi tetap pantau pengeluaran lo ya!';
    }

    try {
      if (recentTransactions.isEmpty) {
        return 'Belum ada transaksi bulan ini. Yuk mulai kelola keuangan lu!';
      }

      final summary = recentTransactions
          .map((t) => '${t['type']}: ${t['amount']} ${t['currency']}')
          .join(', ');
      final prompt =
          'Ini transaksi terakhir gua: $summary. Berikan satu tips keuangan yang sangat singkat, friendly, dan menggunakan bahasa gaul (seperti lu/gua). Maksimal 2 kalimat pendek tanpa markdown atau bold.';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ??
          'Tetap pantau pengeluaran lo ya biar tujuan cepat tercapai!';
    } catch (e) {
      debugPrint('[GeminiAiService] Insight error: $e');
      return 'Tetap pantau pengeluaran lo ya biar tujuan cepat tercapai!';
    }
  }

  /// Format date for transaction display
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Check if the service is ready
  bool get isReady => _isInitialized && _chatSession != null;

  /// Reset the chat session
  void resetChat() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }

  /// Dispose the service
  void dispose() {
    _isInitialized = false;
    _chatSession = null;
    _model = null;
  }
}
