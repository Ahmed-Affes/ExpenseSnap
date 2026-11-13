import 'dart:io';

import 'package:dio/dio.dart';

import '../config.dart';
import '../models/receipt.dart';

/// Exception specifically thrown during receipt network operations.
class ReceiptException implements Exception {
  final String message;

  ReceiptException(this.message);

  @override
  String toString() => message;
}

/// Service handling all HTTP communication with the n8n backend.
///
/// Communicates through three endpoints:
/// 1. POST /receipts/analyze - Analyzes receipt image using Gemini (Workflow A).
/// 2. POST /receipts - Saves verified receipt into Google Sheets (Workflow B).
/// 3. GET /receipts - Retrieves monthly expense history (Workflow C).
class N8nService {
  final Dio _dio;

  N8nService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 45),
              receiveTimeout: const Duration(seconds: 45),
            ),
          );

  /// Helper to get request headers including the required `x-api-key`.
  Map<String, dynamic> get _authHeaders => {
    AppConfig.apiKeyHeader: AppConfig.apiKey,
  };

  /// Workflow A: Uploads receipt image (JPEG or PNG) to n8n for Gemini analysis.
  ///
  /// - Field name: `file`
  /// - Maximum size: 5 MB
  /// - HTTP 200: Returns extracted receipt fields
  /// - HTTP 422: Throws [ReceiptException] with readable message
  Future<Receipt> analyze(File image) async {
    // Check maximum file size (5 MB limit)
    final fileSize = await image.length();
    const maxSizeBytes = 5 * 1024 * 1024;
    if (fileSize > maxSizeBytes) {
      throw ReceiptException(
        'The selected image exceeds 5 MB. Please choose a smaller photo.',
      );
    }

    // Extract filename safely across Windows and Unix paths
    final fileName = image.path.split(RegExp(r'[/\\]')).last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path, filename: fileName),
    });

    try {
      final response = await _dio.post(
        '${AppConfig.baseUrl}/receipts/analyze',
        data: formData,
        options: Options(headers: _authHeaders),
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        return Receipt.fromJson(data);
      } else {
        throw ReceiptException(
          'Failed to analyze receipt. Server responded with status ${response.statusCode}.',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Workflow B: Saves the approved receipt data to n8n as JSON.
  ///
  /// - HTTP 201: Returns saved receipt with `id` and `createdAt`
  /// - n8n writes record to Google Sheets and sends Telegram alerts if amount > 100 TND
  Future<Receipt> save(Receipt receipt) async {
    try {
      final response = await _dio.post(
        '${AppConfig.baseUrl}/receipts',
        data: receipt.toJson(),
        options: Options(
          headers: {..._authHeaders, 'Content-Type': 'application/json'},
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        return Receipt.fromJson(data);
      } else {
        throw ReceiptException(
          'Failed to save receipt. Server responded with status ${response.statusCode}.',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Workflow C: Retrieves saved expense history from n8n.
  ///
  /// - Optional parameter [month] in format 'YYYY-MM'
  /// - HTTP 200: Returns [ReceiptList] with items and total
  Future<ReceiptList> list({String? month}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null && month.isNotEmpty) {
        queryParams['month'] = month;
      }

      final response = await _dio.get(
        '${AppConfig.baseUrl}/receipts',
        queryParameters: queryParams,
        options: Options(headers: _authHeaders),
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        return ReceiptList.fromJson(data);
      } else {
        throw ReceiptException(
          'Failed to fetch receipt history. Server responded with status ${response.statusCode}.',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Formats Dio errors into student-friendly, clear exception messages.
  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      // Handle Workflow A unreadable image error
      if (statusCode == 422) {
        return ReceiptException(
          'The receipt is unreadable. Please make sure the photo is sharp, well-lit, and shows the entire receipt.',
        );
      }

      // Handle Authentication error
      if (statusCode == 401 || statusCode == 403) {
        return ReceiptException(
          'Authentication failed. Please verify that your x-api-key is correctly configured.',
        );
      }

      if (data is Map && data['error'] != null) {
        return ReceiptException('Backend error: ${data['error']}');
      }

      return ReceiptException('Server returned error code $statusCode.');
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ReceiptException(
          'Connection timed out. Please check your network and verify n8n is responding.',
        );
      case DioExceptionType.connectionError:
        return ReceiptException(
          'Could not connect to n8n server (${AppConfig.baseUrl}). Ensure n8n is running.',
        );
      default:
        return ReceiptException(
          'Network request error: ${e.message ?? 'Unknown error'}',
        );
    }
  }
}
