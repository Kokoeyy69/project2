import 'package:dio/dio.dart';

/// Centralized API exception handler untuk Fintech Payment Gateway.
/// Maps DioException ke structured error response dengan pesan lokal.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  ApiException({
    required this.message,
    this.statusCode,
    this.errorType,
  });

  /// Factory constructor untuk convert DioException ke ApiException.
  /// Implements Dio 5.x+ exception mapping dengan business logic untuk Fintech.
  factory ApiException.fromDioException(DioException error) {
    String message;
    String? errorType;
    int? statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Koneksi ke server habis, silakan coba lagi nanti.';
        errorType = 'TIMEOUT_ERROR';
        break;

      case DioExceptionType.badResponse:
        statusCode = error.response?.statusCode;
        errorType = 'BAD_RESPONSE';

        // Extract custom error message dari response body jika tersedia
        final responseData = error.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          message = responseData['message'] as String? ?? _mapStatusCodeToMessage(statusCode);
        } else {
          message = _mapStatusCodeToMessage(statusCode);
        }
        break;

      case DioExceptionType.cancel:
        message = 'Permintaan ke server dibatalkan.';
        errorType = 'REQUEST_CANCELLED';
        break;

      case DioExceptionType.connectionError:
        message = 'Tidak ada koneksi internet. Pastikan perangkat Anda terhubung.';
        errorType = 'CONNECTION_ERROR';
        break;

      case DioExceptionType.unknown:
        message = 'Terjadi kesalahan sistem yang tidak diketahui.';
        errorType = 'UNKNOWN_ERROR';
        break;

      default:
        message = 'Terjadi kesalahan sistem yang tidak diketahui.';
        errorType = 'UNKNOWN_ERROR';
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      errorType: errorType,
    );
  }

  /// Map HTTP status code ke user-friendly message untuk Fintech context.
  static String _mapStatusCodeToMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
      case 422:
        return 'Validasi data gagal. Periksa kembali informasi yang Anda kirimkan.';
      case 401:
        return 'Akses tidak sah. Silakan login kembali.';
      case 403:
        return 'Token kedaluwarsa. Silakan login kembali.';
      case 404:
        return 'Data tidak ditemukan di server.';
      case 409:
        return 'Konflik data. Transaksi mungkin sudah diproses sebelumnya.';
      case 500:
      case 503:
        return 'Server bank sedang maintenance. Silakan coba beberapa saat lagi.';
      default:
        return 'Terjadi kesalahan pada server. Kode: $statusCode';
    }
  }

  @override
  String toString() => 'ApiException: [$errorType] $message (HTTP $statusCode)';
}