import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart' as google_ai;
import '../core/config/env.dart';

class AiService {
  google_ai.GenerativeModel? _model;
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    final apiKey = Env.geminiApiKey;

    // Strictly use gemini-2.5-flash for cloud assistant
    final modelName = 'gemini-2.5-flash';
    print('[AiService] Using architecture: $modelName');

    // 2. JSON MODE & FINTECH PERSONA
    _model = google_ai.GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: google_ai.GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1, // Highly deterministic
      ),
      systemInstruction: google_ai.Content.system('''
        You are NeoPay AI, a secure financial assistant.
        ALWAYS respond in valid JSON format ONLY. No markdown, no extra text.
        Schema:
        {
          "reply": "Your natural conversational response to the user.",
          "action": "none" | "transfer",
          "transfer_details": {
            "amount": 0,
            "recipient": "string"
          }
        }
        Use the injected [SYSTEM CONTEXT] to answer questions about balances.
        If user asks to send/transfer money, set action to "transfer" and parse the amount and recipient. Otherwise, action is "none".
      '''),
    );
    _isInitialized = true;
  }

  // 3. CONTEXT INJECTION & JSON PARSING
  Future<Map<String, dynamic>> sendAgentMessage(
    String prompt, {
    String? financialContext,
  }) async {
    await _ensureInitialized();

    String finalPrompt = prompt;
    if (financialContext != null && financialContext.isNotEmpty) {
      finalPrompt = "[SYSTEM CONTEXT: $financialContext]\n\nUser says: $prompt";
    }

    try {
      final response = await _model!.generateContent([
        google_ai.Content.text(finalPrompt),
      ]);
      if (response.text != null) {
        // Extract only the JSON object using RegExp to prevent hallucination
        final textResponse = response.text!;
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(textResponse);
        if (match != null) {
          return jsonDecode(match.group(0)!);
        } else {
          throw Exception('Invalid JSON format from AI');
        }
      }
      throw Exception('Empty response from AI');
    } catch (e) {
      print('[AiService Error]: $e');
      return {
        "reply":
            "Maaf, terjadi kendala saat memproses permintaan Anda. (Info log: ${e.toString()})",
        "action": "none",
        "transfer_details": {"amount": 0, "recipient": ""},
      };
    }
  }
}
