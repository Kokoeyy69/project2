import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:neopay_ai/core/providers/ai_provider.dart';
import 'package:neopay_ai/core/providers/currency_provider.dart';
import 'package:neopay_ai/core/services/gemini_ai_service.dart';
import 'package:neopay_ai/core/services/exchange_rate_model.dart';
import 'package:neopay_ai/core/services/voice_service.dart';
import '../../../theme/app_theme.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingController;
  final VoiceService _voiceService = VoiceService.instance;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _voiceService.init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currencyProvider = context.read<CurrencyProvider>();
      context.read<AIProvider>().init(currencyProvider: currencyProvider);
    });
  }

  void _toggleVoiceInput() async {
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _voiceService.startListening(
        onResult: (text) {
          setState(() {
            _isListening = false;
            _controller.text = text;
          });
          _sendMessage();
        },
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    context.read<AIProvider>().sendMessage(text);

    // Scroll to bottom after message is sent
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildChatList()),
          _buildTransferConfirmationSheet(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: AppTheme.textSecondary,
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Neo AI',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Consumer<AIProvider>(
                builder: (context, provider, _) {
                  return Text(
                    provider.isReady ? 'Online' : 'Initializing...',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.success,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          color: AppTheme.textMuted,
          tooltip: 'Clear chat',
          onPressed: () {
            context.read<AIProvider>().clearChat();
          },
        ),
      ],
    );
  }

  Widget _buildChatList() {
    return Consumer<AIProvider>(
      builder: (context, provider, _) {
        final messages = provider.messages;

        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length + (provider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= messages.length) {
              return _buildTypingIndicator();
            }
            return _buildMessageBubble(messages[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryMuted, AppTheme.accentMuted],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Hi, I\'m Neo!',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your AI-powered financial assistant',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildSuggestionChip('Send 500k to Ahmad'),
          const SizedBox(height: 8),
          _buildSuggestionChip('How much is 100 USD in IDR?'),
          const SizedBox(height: 8),
          _buildSuggestionChip('Transfer \$50 to Siti'),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () {
        _controller.text = label;
        _sendMessage();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.glassBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withAlpha(51)),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accent],
                          )
                        : null,
                    color: isUser ? null : AppTheme.surface.withAlpha(204),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppTheme.glassBorder, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isUser
                              ? Colors.white54
                              : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withAlpha(204),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _typingController,
                      builder: (context, child) {
                        final delay = index * 0.2;
                        final value = (_typingController.value + delay) % 1.0;
                        final scale = 0.6 + 0.4 * (value < 0.5
                            ? value * 2
                            : (1 - value) * 2);
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha((scale * 255).round()),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferConfirmationSheet() {
    return Consumer<AIProvider>(
      builder: (context, provider, _) {
        if (provider.pendingTransfer == null) {
          return const SizedBox.shrink();
        }

        final intent = provider.pendingTransfer!;
        final symbol = SupportedCurrencies.getSymbol(intent.currency);

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppTheme.glassBorder, width: 0.5),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.glassBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.successMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payment_rounded,
                          color: AppTheme.success,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Confirm Transfer',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Amount', '${symbol}${intent.amount.toStringAsFixed(0)} ${intent.currency}'),
                        if (intent.needsConversion) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Converted',
                            '${SupportedCurrencies.getSymbol(intent.convertedCurrency!)}${intent.convertedAmount!.toStringAsFixed(0)} ${intent.convertedCurrency}',
                            highlight: true,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow('Rate', '1 ${intent.currency} = ${intent.exchangeRate!.toStringAsFixed(2)} ${intent.convertedCurrency}'),
                        ],
                        const SizedBox(height: 8),
                        _buildDetailRow('Recipient', intent.recipientName ?? 'Unknown'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => provider.cancelTransfer(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.glassBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await provider.confirmTransfer();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transfer confirmed! Processing...'),
                                  backgroundColor: AppTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Confirm',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.textMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? AppTheme.success : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.glassBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: _isListening ? 'Listening...' : 'Ask Neo anything...',
                            hintStyle: TextStyle(color: _isListening ? AppTheme.primary : AppTheme.textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleVoiceInput,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening ? AppTheme.error.withAlpha(51) : AppTheme.primary.withAlpha(26),
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? AppTheme.error : AppTheme.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Consumer<AIProvider>(
            builder: (context, provider, _) {
              return GestureDetector(
                onTap: provider.isLoading ? null : _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: provider.isLoading
                        ? null
                        : const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.accent],
                          ),
                    color: provider.isLoading ? AppTheme.glassBackground : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: provider.isLoading
                        ? null
                        : [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(89),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: provider.isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}