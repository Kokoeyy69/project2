import 'package:dio/dio.dart';
import 'api_interceptors.dart';
import 'api_exception.dart';

/// Singleton HTTP Client untuk centralized network communication.
/// Implements Dio 5.x+ architecture dengan interceptors, error handling,
/// dan timeout configuration untuk Fintech Payment Gateway.
class DioClient {
  /// Private constructor untuk Singleton pattern
  DioClient._internal();

  /// Singleton instance
  static final DioClient _instance = DioClient._internal();

  /// Factory constructor untuk return singleton instance
  factory DioClient() => _instance;

  /// Dio HTTP client instance
  final Dio _dio = Dio();

  /// Getter untuk Dio instance
  Dio get dio => _dio;

  /// Initialize Dio dengan BaseOptions dan Interceptors.
  /// Called once pada app startup via DI container.
  void initialize() {
    // Configure BaseOptions dengan timeout Duration (Dio 5.x+ standard)
    _dio.options = BaseOptions(
      baseUrl: 'https://api.sandbox.midtrans.com/v2/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
      responseType: ResponseType.json,
    );

    // Register interceptors
    _dio.interceptors.clear();
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(CustomLogInterceptor());

    // Optional: Add custom response interceptor untuk centralized error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          // Convert DioException ke ApiException
          final apiException = ApiException.fromDioException(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: apiException,
              message: apiException.message,
            ),
          );
        },
      ),
    );
  }

  /// Get method wrapper dengan error handling.
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Post method wrapper dengan error handling.
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Put method wrapper dengan error handling.
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Delete method wrapper dengan error handling.
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Update base URL untuk testing atau multiple environments.
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  /// Update server key untuk payment gateway authentication.
  void updateServerKey(String newServerKey) {
    // Note: Actual implementation memerlukan redesign AuthInterceptor
    // untuk support dynamic server key updates
  }

  /// Close Dio client dan release resources.
  void close() {
    _dio.close(force: true);
  }
}