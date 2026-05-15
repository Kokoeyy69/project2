import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:neopay_ai/services/ai_service.dart';
import 'package:neopay_ai/theme/app_theme.dart';
import 'package:neopay_ai/services/hive_cache_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final AiService _ai = AiService();
  final TextEditingController _ctl = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _ctl.clear();
      _isSending = true;
    });

    try {
      // 1. READ DATA DIRECTLY FROM LOCAL CACHE (BYPASSING PROVIDER)
      // We use ?? 0.0 as a fallback in case the cache is empty
      final double realBalance = (HiveCacheService.getCachedBalance()) ?? 0.0;

      // 2. CREATE REAL CONTEXT
      String realContext = "Saldo utama User saat ini adalah: Rp $realBalance.";

      // 3. CALL AI SERVICE WITH REAL CONTEXT
      final aiResponse = await _ai.sendAgentMessage(
        text,
        financialContext: realContext,
      );

      String replyText = aiResponse['reply'] ?? "Tidak ada respon";
      String action = aiResponse['action'] ?? "none";

      // Add reply text to chat bubble UI
      setState(() {
        _messages.add({'role': 'assistant', 'text': replyText});
      });

      // 3. DOUBLE VALIDATION SECURITY DIALOG
      if (action == 'transfer') {
        final details = aiResponse['transfer_details'];
        final amount = details['amount'] ?? 0;
        final recipient = details['recipient'] ?? 'Tidak diketahui';

        if (amount > 0) {
          _showTransferConfirmationDialog(recipient, amount);
        }
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'Error: ${e.toString()}'});
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showTransferConfirmationDialog(String recipient, int amount) {
    // Setup currency formatter for proper Rupiah display
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final formattedAmount = currencyFormatter.format(amount);
    
    bool isProcessing = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('🔒 Keamanan NeoPay'),
            content: Text('AI mendeteksi perintah transfer.\n\nPenerima: $recipient\nNominal: $formattedAmount\n\nLanjutkan transaksi ini?'),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: isProcessing
                    ? null
                    : () async {
                        setDialogState(() => isProcessing = true);

                        final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
                        final formattedAmount = currencyFormatter.format(amount);
                        final double originalBalance = (HiveCacheService.getCachedBalance()) ?? 0.0;

                        try {
                          // 1. SEARCH RECIPIENT IN FIRESTORE
                          // We search for a user whose 'name' matches the recipient detected by AI
                          final recipientQuery = await FirebaseFirestore.instance
                              .collection('users')
                              .where('name', isEqualTo: recipient)
                              .limit(1)
                              .get();

                          if (recipientQuery.docs.isEmpty) {
                            throw 'User "$recipient" tidak ditemukan di database NeoPay.';
                          }

                          final recipientDoc = recipientQuery.docs.first;
                          final String recipientUid = recipientDoc.id;
                          final double recipientCurrentBalance = (recipientDoc.data()['balance'] ?? 0.0).toDouble();

                          // 2. SENDER VALIDATION
                          if (originalBalance < amount) {
                            throw 'Saldo Anda tidak mencukupi untuk transfer ini.';
                          }

                          // 3. ATOMIC TRANSACTION (The "Golden" Rule of Fintech)
                          final User? currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser != null) {
                            final String senderUid = currentUser.uid;
                            final WriteBatch batch = FirebaseFirestore.instance.batch();

                            // A. Update Sender Balance (Local & Firestore)
                            final double senderNewBalance = originalBalance - amount;
                            await HiveCacheService.setCachedBalance(senderNewBalance);
                            batch.update(FirebaseFirestore.instance.collection('users').doc(senderUid), {'balance': senderNewBalance});

                            // B. Update Recipient Balance (Firestore Only)
                            final double recipientNewBalance = recipientCurrentBalance + amount;
                            batch.update(FirebaseFirestore.instance.collection('users').doc(recipientUid), {'balance': recipientNewBalance});

                            // C. Record Transaction Receipt
                            final DocumentReference trxRef = FirebaseFirestore.instance.collection('transactions').doc();
                            batch.set(trxRef, {
                              'senderUid': senderUid,
                              'recipientUid': recipientUid,
                              'recipientName': recipient,
                              'amount': amount,
                              'timestamp': FieldValue.serverTimestamp(),
                              'type': 'p2p_transfer',
                              'status': 'success'
                            });

                            await batch.commit();
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('✅ Sukses! $formattedAmount terkirim ke $recipient'), backgroundColor: Colors.green),
                          );
                          if (context.mounted) Navigator.pop(dialogContext);

                        } catch (e) {
                          // ROLLBACK local cache if anything fails
                          await HiveCacheService.setCachedBalance(originalBalance);
                          setDialogState(() => isProcessing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('❌ Transfer Gagal: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : const Text('Lanjut Transfer', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBubble(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          msg['text'] ?? '',
          style: GoogleFonts.inter(
            color: isUser ? Colors.white : AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _buildBubble(_messages[i]),
            ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'AI is typing...',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Ask the assistant...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSending ? null : _send,
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}