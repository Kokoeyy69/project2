import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neopay_ai/services/ai_service.dart';
import 'package:neopay_ai/theme/app_theme.dart';
import 'package:neopay_ai/routes/app_routes.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString('ai_api_key') ?? '';
      if (key.isEmpty) {
        // Ask user to configure AI key
        if (!mounted) return;
        final go =
            await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('AI not configured'),
                content: const Text(
                  'Please add your AI API key in AI Settings to use this feature.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            ) ??
            false;
        if (!mounted) return;
        if (go) Navigator.pushNamed(context, AppRoutes.aiSettingsScreen);
        setState(() => _isSending = false);
        return;
      }

      final response = await _ai.sendMessage(text);
      setState(() {
        _messages.add({'role': 'assistant', 'text': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'Error: ${e.toString()}'});
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
