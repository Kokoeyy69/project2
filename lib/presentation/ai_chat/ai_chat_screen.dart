import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math';
import 'package:neopay_ai/core/di/locator.dart';
import 'package:neopay_ai/core/services/analytics_service.dart';
import '../../core/providers/ai_provider.dart';
import '../../core/services/gemini_ai_service.dart';
import '../../routes/app_routes.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final aiProvider = Provider.of<AIProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(aiProvider)),
          if (aiProvider.usageCount >= 5) _buildPremiumUpgradeCard(context),
          if (aiProvider.isLoading) const LinearProgressIndicator(),
          _buildInputArea(context, aiProvider),
        ],
      ),
    );
  }

  Widget _buildPremiumUpgradeCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.deepPurple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade200.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Unlock Premium AI!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Get unlimited AI interactions and exclusive features.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              locator<AnalyticsService>().logBusinessEvent(
                AnalyticsService.EVENT_PREMIUM_UPGRADE_CLICK,
                {'source': 'ai_chat_screen_card'},
              );
              debugPrint('Premium Upgrade Clicked!');
              // TODO: Navigate to premium upgrade screen
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.deepPurple.shade900, backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Upgrade Now',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(AIProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];
        bool isBurnerResponse =
            !message.isUser && message.content.contains("Burner Card");

        return Column(
          children: [
            StealthChatBubble(
              message: message.content,
              isUser: message.isUser,
              status: message.status,
            ),
            if (isBurnerResponse) const BurnerCardWidget(),
            if (message.status == MessageStatus.escrowPending) const EscrowStatusBadge(),
          ],
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context, AIProvider provider) {
    final TextEditingController controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Show transfer confirmation if pending
          if (provider.pendingTransfer != null)
            _buildTransferConfirmation(context, provider),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  provider.sendMessage(controller.text);
                  controller.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransferConfirmation(BuildContext context, AIProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.getTransferSummary() ?? 'Transfer confirmation',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  provider.cancelTransfer();
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _handleConfirmTransfer(context, provider),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleConfirmTransfer(BuildContext context, AIProvider provider) async {
    final status = await provider.confirmTransfer();
    if (status == TransferStatus.requiresVerification) {
      _showVerificationDialog(context);
    }
  }

  void _showVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Security Verification'),
          content: const Text(
            'Transaksi ini memerlukan verifikasi tambahan untuk keamanan dana Anda.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushNamed(AppRoutes.pinEntryScreen);
              },
              child: const Text('Verify Now'),
            ),
          ],
        );
      },
    );
  }
}

class StealthChatBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final MessageStatus? status;

  const StealthChatBubble({Key? key, required this.message, required this.isUser, this.status})
      : super(key: key);

  @override
  _StealthChatBubbleState createState() => _StealthChatBubbleState();
}

class _StealthChatBubbleState extends State<StealthChatBubble> {
  bool isObscured = true;

  bool get isSensitive {
    if (widget.isUser) return false;
    final keywords = ["Saldo", "Total Kekayaan", "Mutasi", "Rp"];
    return keywords.any((k) => widget.message.contains(k));
  }

  @override
  Widget build(BuildContext context) {
    Widget textContent = Text(
      widget.message,
      style: const TextStyle(color: Colors.black87),
    );

    Widget bubbleContent = textContent;

    if (isSensitive) {
      bubbleContent = GestureDetector(
        onPanDown: (_) => setState(() => isObscured = false),
        onPanCancel: () => setState(() => isObscured = true),
        onPanEnd: (_) => setState(() => isObscured = true),
        child: ImageFiltered(
          imageFilter: isObscured
              ? ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0)
              : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
          child: textContent,
        ),
      );
    }

    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: bubbleContent,
      ),
    );
  }
}

class EscrowStatusBadge extends StatefulWidget {
  const EscrowStatusBadge({Key? key}) : super(key: key);

  @override
  State<EscrowStatusBadge> createState() => _EscrowStatusBadgeState();
}

class _EscrowStatusBadgeState extends State<EscrowStatusBadge> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _opacity = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, color: Colors.amber.shade800, size: 16),
            const SizedBox(width: 6),
            Text(
              "Secured in Escrow",
              style: TextStyle(
                color: Colors.amber.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BurnerCardWidget extends StatelessWidget {
  const BurnerCardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final random = Random();
    String cardNumber = "";
    for (int i = 0; i < 4; i++) {
      cardNumber +=
          (1000 + random.nextInt(9000)).toString() + (i == 3 ? "" : " ");
    }
    String validThru =
        "${(random.nextInt(12) + 1).toString().padLeft(2, '0')}/${25 + random.nextInt(5)}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1a2a6c), Color(0xFFb21f1f), Color(0xFFfdbb2d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "NeoPay Virtual",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              Icon(Icons.contactless, color: Colors.white.withOpacity(0.8)),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            cardNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("VALID THRU",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 10)),
                  Text(validThru,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
              const Spacer(),
              Container(
                width: 45,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Container(
                    width: 30,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}