import 'dart:convert';

import 'package:http/http.dart' as http;

import 'shwary_config.dart';

class ShwaryPaymentResult {
  const ShwaryPaymentResult({
    required this.success,
    this.transactionId,
    this.status,
    this.message,
    this.rawResponse,
  });

  final bool success;
  final String? transactionId;
  final String? status;
  final String? message;
  final String? rawResponse;
}

class ShwaryService {
  static String normalizePhoneNumber(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+243')) {
      return cleaned;
    }
    if (cleaned.startsWith('243')) {
      return '+$cleaned';
    }
    if (cleaned.startsWith('0')) {
      return '+243${cleaned.substring(1)}';
    }
    return '+243$cleaned';
  }

  static bool isSuccessfulStatus(String? status) {
    final normalized = (status ?? '').trim().toUpperCase();
    return normalized == 'COMPLETED' ||
        normalized == 'SUCCESS' ||
        normalized == 'ACCEPTED' ||
        normalized == 'SUCCESS';
  }

  static Future<ShwaryPaymentResult> initiatePayment({
    required double amount,
    required String phoneNumber,
    String? callbackUrl,
  }) async {
    final normalizedPhone = normalizePhoneNumber(phoneNumber);
    if (!RegExp(r'^\+243\d{9}$').hasMatch(normalizedPhone)) {
      throw const FormatException(
        'Le numéro de téléphone doit être un numéro RDC valide.',
      );
    }

    final roundedAmount = amount.round();
    if (roundedAmount < 2900) {
      throw const FormatException(
        'Le montant doit être au minimum de 2900 CDF.',
      );
    }

    final response = await http.post(
      Uri.parse(ShwaryConfig.paymentEndpoint),
      headers: {
        'x-merchant-id': ShwaryConfig.merchantId,
        'x-merchant-key': ShwaryConfig.merchantKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': roundedAmount,
        'clientPhoneNumber': normalizedPhone,
        'callbackUrl': callbackUrl ?? ShwaryConfig.callbackUrl,
      }),
    );

    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = body.startsWith('{') || body.startsWith('[')
        ? jsonDecode(body)
        : <String, dynamic>{};

    final status = _readValue(decoded, 'status');
    final message = _readValue(decoded, 'message');
    final transactionId = _readValue(decoded, 'transactionId');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Erreur Shwary (${response.statusCode}) : $body',
        response.statusCode,
      );
    }

    final success =
        isSuccessfulStatus(status) ||
        (message ?? '').toLowerCase() == 'success' ||
        (transactionId ?? '').isNotEmpty;

    return ShwaryPaymentResult(
      success: success,
      transactionId: transactionId,
      status: status,
      message: message,
      rawResponse: body,
    );
  }

  static Future<ShwaryPaymentResult> verifyTransaction(
    String transactionId,
  ) async {
    final response = await http.get(
      Uri.parse('${ShwaryConfig.transactionsEndpoint}/$transactionId'),
      headers: {
        'x-merchant-id': ShwaryConfig.merchantId,
        'x-merchant-key': ShwaryConfig.merchantKey,
      },
    );

    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = body.startsWith('{') || body.startsWith('[')
        ? jsonDecode(body)
        : <String, dynamic>{};

    final status = _readValue(decoded, 'status');
    final message = _readValue(decoded, 'message');
    final success =
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        (isSuccessfulStatus(status) ||
            (message ?? '').toLowerCase() == 'success');

    return ShwaryPaymentResult(
      success: success,
      transactionId: transactionId,
      status: status,
      message: message,
      rawResponse: body,
    );
  }

  static String? _readValue(dynamic decoded, String key) {
    if (decoded is Map<String, dynamic>) {
      final value = decoded[key];
      if (value is String) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
    }
    if (decoded is Map) {
      final value = decoded[key];
      if (value is String) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }
}

class HttpException implements Exception {
  const HttpException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
