import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal AI service that supports OpenAI Chat Completions.
///
/// It reads a user-configured API key and provider from SharedPreferences:
/// - `ai_api_key` (String) and `ai_provider` (String, default `openai`).
///
/// This is intentionally small and resilient: it provides timeouts,
/// basic error mapping, and a single `sendMessage` method the UI can call.
class AiService {
  final Dio _dio;

  AiService([Dio? dio]) : _dio = dio ?? Dio();

  Future<String> sendMessage(
    String prompt, {
    String model = 'gpt-3.5-turbo',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('ai_api_key') ?? '';
    final provider = prefs.getString('ai_provider') ?? 'openai';

    if (apiKey.isEmpty) {
      throw Exception('AI API key not configured. Open AI settings.');
    }

    if (provider == 'openai') {
      try {
        final payload = {
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 800,
          'temperature': 0.3,
        };

        final resp = await _dio.post(
          'https://api.openai.com/v1/chat/completions',
          data: payload,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            sendTimeout: const Duration(milliseconds: 20000),
            receiveTimeout: const Duration(milliseconds: 20000),
          ),
        );

        if (resp.statusCode == 200) {
          final data = resp.data;
          final text = data['choices']?[0]?['message']?['content'];
          if (text != null) return text.toString();
          throw Exception('Unexpected response format from OpenAI');
        }

        throw Exception(
          'OpenAI error: ${resp.statusCode} ${resp.statusMessage}',
        );
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw Exception('AI request timed out');
        }
        rethrow;
      }
    }

    throw Exception('AI provider $provider not supported yet');
  }
}
