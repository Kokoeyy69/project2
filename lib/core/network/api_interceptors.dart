import 'package:dio/dio.dart';
import 'dart:convert';

/// Request interceptor yang menangani autentikasi dan request logging.
/// Implements Fintech standard dengan Basic Authentication untuk Payment Gateway.
class AuthInterceptor extends Interceptor {
  /// Server key untuk Basic Authentication (Midtrans/Xendit format).
  /// PROD: Ganti dengan actual server key dari environment config.
  static const String serverKey = 'SB-Mid-server-XXXXX';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Encode server key dalam format Basic Authentication
    final String credentials = '$serverKey:';
    final String encoded = base64Encode(utf8.encode(credentials));

    // Inject authorization headers
    options.headers['Authorization'] = 'Basic $encoded';
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    super.onRequest(options, handler);
  }
}

/// Logging interceptor untuk development debugging dan monitoring.
/// Captures request/response headers dan bodies untuk troubleshooting.
class CustomLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Log request details untuk development
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('REQUEST: ${options.method.toUpperCase()} ${options.uri}');
    print('───────────────────────────────────────────────────────────');
    print('Headers: ${options.headers}');
    if (options.data != null) {
      print('Body: ${options.data}');
    }
    print('═══════════════════════════════════════════════════════════');
    print('');

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Log response details untuk development
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
    print('───────────────────────────────────────────────────────────');
    print('Body: ${response.data}');
    print('═══════════════════════════════════════════════════════════');
    print('');

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log error details untuk debugging
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('ERROR: ${err.type} - ${err.message}');
    print('───────────────────────────────────────────────────────────');
    print('Response: ${err.response?.data}');
    print('═══════════════════════════════════════════════════════════');
    print('');

    super.onError(err, handler);
  }
}