import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:neopay_ai/core/config/env.dart';

class AiService {
  GenerativeModel? _model;
  bool _isInitialized = false;

  // 1. HYBRID DETECTION (Cloud vs On-Device fallback)
  Future<bool> _isDeviceCapableForLocalAI() async {
    // Default to false (Cloud) for now. Future: check RAM/NPU.
    return false;
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    
    final apiKey = Env.geminiApiKey;
    final isLocalCapable = await _isDeviceCapableForLocalAI();
    
    // Use Nano if local is capable, otherwise use Flash
    final modelName = isLocalCapable ? 'gemini-nano' : 'gemini-flash-latest';
    print('[AiService] Using architecture: $modelName');

    // 2. JSON MODE & FINTECH PERSONA
    _model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1, // Highly deterministic
      ),
      systemInstruction: Content.system('''
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
  Future<Map<String, dynamic>> sendAgentMessage(String prompt, {String? financialContext}) async {
    await _ensureInitialized();

    String finalPrompt = prompt;
    if (financialContext != null && financialContext.isNotEmpty) {
      finalPrompt = "[SYSTEM CONTEXT: $financialContext]\n\nUser says: $prompt";
    }

    try {
      final response = await _model!.generateContent([Content.text(finalPrompt)]);
      if (response.text != null) {
        // Clean JSON just in case Gemini hallucinates markdown formatting
        String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(cleanJson);
      }
      throw Exception('Empty response from AI');
    } catch (e) {
      print('[AiService] Agent Error: $e');
      return {
        "reply": "Maaf, terjadi kesalahan pada sistem AI.",
        "action": "none",
        "transfer_details": {"amount": 0, "recipient": ""}
      };
    }
  }
}