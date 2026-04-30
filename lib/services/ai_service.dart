import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Robust AI service wrapper.
///
/// Features:
/// - Reads `ai_api_key` and `ai_provider` from SharedPreferences.
/// - Supports cancellable requests via `CancelToken`.
/// - Retries transient errors with exponential backoff.
/// - Maps common network errors into friendly messages.
class AiService {
  final Dio _dio;

  AiService([Dio? dio]) : _dio = dio ?? Dio();

  Future<String> sendMessage(
    String prompt, {
    String model = 'gpt-3.5-turbo',
    int maxTokens = 800,
    double temperature = 0.3,
    CancelToken? cancelToken,
    int maxRetries = 2,
    int baseDelayMs = 500,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('ai_api_key') ?? '';
    final provider = prefs.getString('ai_provider') ?? 'openai';

    if (apiKey.isEmpty) {
      throw Exception('AI API key not configured. Open AI settings.');
    }

    if (provider != 'openai') {
      throw Exception('AI provider $provider not supported yet');
    }

    int attempt = 0;
    while (true) {
      try {
        final payload = {
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
        };

        final resp = await _dio.post(
          'https://api.openai.com/v1/chat/completions',
          data: payload,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            sendTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
          ),
          cancelToken: cancelToken,
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
        if (e.type == DioExceptionType.cancel) {
          throw Exception('AI request cancelled');
        }

        // Treat timeouts and connection errors as transient and retryable
        final transient =
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;

        if (!transient) rethrow;

        if (attempt >= maxRetries) {
          throw Exception('AI request failed after retries: ${e.message}');
        }

        // Exponential backoff with jitter
        final delay = _computeBackoff(attempt, baseDelayMs);
        await Future.delayed(Duration(milliseconds: delay));
        attempt++;
        continue;
      } catch (e) {
        rethrow;
      }
    }
  }

  int _computeBackoff(int attempt, int baseMs) {
    final pow2 = pow(2, attempt).toInt();
    final jitter = Random().nextInt(baseMs);
    return baseMs * pow2 + jitter;
  }
}
