import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/config/env.dart';

/// API response model
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? error;

  ApiResponse._({required this.success, this.message, this.data, this.error});

  factory ApiResponse.success({String? message, T? data}) {
    return ApiResponse._(success: true, message: message, data: data);
  }

  factory ApiResponse.error({required String error, String? message}) {
    return ApiResponse._(success: false, error: error, message: message);
  }
}

/// Transfer request model
class TransferRequest {
  final String senderUid;
  final String recipientUid;
  final double amount;
  final String? recipientName;
  final String? senderName;

  TransferRequest({
    required this.senderUid,
    required this.recipientUid,
    required this.amount,
    this.recipientName,
    this.senderName,
  });

  Map<String, dynamic> toJson() => {
        'senderUid': senderUid,
        'recipientUid': recipientUid,
        'amount': amount,
        'recipientName': recipientName,
        'senderName': senderName,
      };
}

/// Top-up request model
class TopUpRequest {
  final String uid;
  final double amount;

  TopUpRequest({required this.uid, required this.amount});

  Map<String, dynamic> toJson() => {'uid': uid, 'amount': amount};
}

/// Callback for cold start processing state
typedef OnProcessingCallback =
    void Function(bool isProcessing, String? message);

/// Secure API service for NeoPay backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static ApiService get instance => _instance;

  final Dio _dio = Dio();

  // Updated Vercel URL - change this to your deployed URL
  static const String _apiBaseUrl = String.fromEnvironment(
    'NEOPAY_API_URL',
    defaultValue: 'https://neopay-api-eight.vercel.app',
  );
  static const String _apiKey = String.fromEnvironment(
    'NEOPAY_API_KEY',
    defaultValue: 'neopay-secure-key-2024',
  );

  /// Callback for cold start processing
  OnProcessingCallback? onProcessing;

  /// Initialize Dio with default options
  void _setupDio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 30)
      ..receiveTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 30)
      ..headers = {
        'Content-Type': 'application/json',
        if (_apiKey.isNotEmpty) 'X-API-Key': _apiKey,
      };
  }

  /// Get Firebase Auth token
  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// Process transfer via secure backend
  Future<ApiResponse<Map<String, dynamic>>> processTransfer(
    TransferRequest request,
  ) async {
    try {
      _setupDio();
      final authToken = await _getAuthToken();

      final uri = Uri.parse('$_apiBaseUrl/api/transfer');
      final body = request.toJson();

      // Debug logging (suppressed in release builds)
      debugPrint('[ApiService] POST ${uri}');
      debugPrint('[ApiService] Body: ${jsonEncode(body)}');

      try {
        final response = await _dio.post(
          uri.toString(),
          data: jsonEncode(body),
          options: Options(
            headers: {
              if (authToken != null) 'Authorization': 'Bearer $authToken',
            },
          ),
        );

        debugPrint('[ApiService] Status: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data as Map<String, dynamic>;
          debugPrint('[ApiService] Transfer success: ${data['message']}');
          return ApiResponse.success(
            message: data['message'] as String? ?? 'Transfer successful',
            data: data,
          );
        } else {
          final data = response.data;
          String errorMsg = 'Server error: ${response.statusCode}';
          String? message;
          if (data is Map<String, dynamic>) {
            errorMsg = data['error'] as String? ?? data['message'] as String? ?? errorMsg;
            message = data['message'] as String?;
          } else if (data != null) {
            errorMsg = data.toString();
          }
          debugPrint('[ApiService] Transfer server error $errorMsg');
          return ApiResponse.error(error: errorMsg, message: message ?? 'Transfer failed');
        }
      } catch (e) {
        debugPrint('[ApiService] Network/client error: $e');
        return ApiResponse.error(error: 'Network/Client error: $e');
      }
    } catch (e) {
      return ApiResponse.error(error: 'Unexpected error: ${e.toString()}');
    }
  }

  /// Process top-up via secure backend
  Future<ApiResponse<Map<String, dynamic>>> processTopUp(
    TopUpRequest request,
  ) async {
    try {
      _setupDio();
      final authToken = await _getAuthToken();

      final response = await _dio.post(
        '$_apiBaseUrl/api/topup',
        data: jsonEncode(request.toJson()),
        options: Options(
          headers: {
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return ApiResponse.success(
          message: data['message'] as String? ?? 'Top-up successful',
          data: data,
        );
      } else {
        return ApiResponse.error(
          error: 'Server error: ${response.statusCode}',
          message: 'Top-up failed',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Cannot connect to server. Check your internet.';
      } else if (e.response != null) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          errorMessage =
              data['error'] as String? ??
              data['message'] as String? ??
              errorMessage;
        }
      }

      return ApiResponse.error(error: errorMessage);
    } catch (e) {
      return ApiResponse.error(error: 'Unexpected error: ${e.toString()}');
    }
  }

  /// Verify transaction status
  Future<ApiResponse<Map<String, dynamic>>> verifyTransaction(
    String transactionId,
  ) async {
    try {
      _setupDio();
      final authToken = await _getAuthToken();

      final response = await _dio.get(
        '$_apiBaseUrl/api/transaction/$transactionId',
        options: Options(
          headers: {
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ApiResponse.success(data: data);
      } else {
        return ApiResponse.error(error: 'Transaction not found');
      }
    } catch (e) {
      return ApiResponse.error(error: 'Failed to verify transaction');
    }
  }

  /// Get user balance from backend
  Future<ApiResponse<Map<String, dynamic>>> getUserBalance(String uid) async {
    try {
      _setupDio();
      final authToken = await _getAuthToken();

      final response = await _dio.get(
        '$_apiBaseUrl/api/user/$uid/balance',
        options: Options(
          headers: {
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ApiResponse.success(data: data);
      } else {
        return ApiResponse.error(error: 'Failed to fetch balance');
      }
    } catch (e) {
      return ApiResponse.error(error: 'Failed to fetch balance');
    }
  }
}

/// API error types for better error handling
enum ApiErrorType {
  insufficientBalance,
  userNotFound,
  invalidAmount,
  networkError,
  timeout,
  unauthorized,
  unknown,
}

/// Extension to help parse error types
extension ApiErrorTypeExtension on ApiErrorType {
  String get message {
    switch (this) {
      case ApiErrorType.insufficientBalance:
        return 'Saldo tidak mencukupi';
      case ApiErrorType.userNotFound:
        return 'Pengguna tidak ditemukan';
      case ApiErrorType.invalidAmount:
        return 'Nominal tidak valid';
      case ApiErrorType.networkError:
        return 'Gagal terhubung ke server';
      case ApiErrorType.timeout:
        return 'Waktu koneksi habis, coba lagi';
      case ApiErrorType.unauthorized:
        return 'Silakan login ulang';
      case ApiErrorType.unknown:
        return 'Terjadi kesalahan';
    }
  }
}
