import 'dart:convert';

import 'package:http/http.dart' as http;

import 'shwary_config.dart';

class ShwaryPaymentResult {
  const ShwaryPaymentResult({
    required this.success,
    required this.isSandbox,
    this.transactionId,
    this.status,
    this.message,
    this.rawResponse,
  });

  final bool success;
  final bool isSandbox;
  final String? transactionId;
  final String? status;
  final String? message;
  final String? rawResponse;
}

class ShwaryService {
  static String normalizePhoneNumber(String value) {
    var cleaned = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
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
        normalized == 'ACCEPTED';
  }

  static Future<ShwaryPaymentResult> initiatePayment({
    required double amount,
    required String phoneNumber,
    String? callbackUrl,
    bool sandboxMode = ShwaryConfig.sandbox,
  }) async {
    if (!ShwaryConfig.isConfigured) {
      throw ShwaryException(
        'Configuration Shwary manquante (Merchant ID / Merchant Key).',
      );
    }

    final normalizedPhone = _normalizeDrcPhoneNumber(phoneNumber);
    _validateDrcPhoneNumber(normalizedPhone);

    final amountInt = amount.round();
    if (amountInt <= 0 || !amount.isFinite) {
      throw ShwaryException('Montant Shwary invalide: $amount.');
    }
    if (amountInt < ShwaryConfig.minimumAmountCdf) {
      throw ShwaryException(
        'Le montant minimum Shwary en CDF est ${ShwaryConfig.minimumAmountCdf}.',
      );
    }

    final payload = {
      'amount': amountInt,
      'clientPhoneNumber': normalizedPhone,
      'callbackUrl': callbackUrl ?? ShwaryConfig.callbackUrl,
    };

    final response = await http
        .post(
          Uri.parse(ShwaryConfig.paymentEndpoint(sandboxMode: sandboxMode)),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(Duration(seconds: ShwaryConfig.timeout));

    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = body.startsWith('{') || body.startsWith('[')
        ? jsonDecode(body)
        : <String, dynamic>{};

    final status = _readValue(decoded, 'status');
    final message =
        _readValue(decoded, 'message') ?? _readValue(decoded, 'error');
    final transactionId =
        _readValue(decoded, 'transactionId') ??
        _readValue(decoded, 'id') ??
        _readValue(decoded, 'referenceId');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final diagnostic =
          'Montant envoye: $amountInt ${ShwaryConfig.currency}. '
          'Telephone: ${_maskPhoneNumber(normalizedPhone)}.';
      throw ShwaryException(
        'Erreur Shwary (${response.statusCode}): $body\n$diagnostic',
      );
    }

    final success =
        isSuccessfulStatus(status) ||
        (status ?? '').trim().toLowerCase() == 'pending' ||
        (message ?? '').toLowerCase() == 'success' ||
        (transactionId ?? '').isNotEmpty;

    return ShwaryPaymentResult(
      success: success,
      isSandbox: sandboxMode,
      transactionId: transactionId,
      status: status,
      message: message,
      rawResponse: body,
    );
  }

  static Future<ShwaryPaymentResult> verifyTransaction(
    String transactionId, {
    bool sandboxMode = ShwaryConfig.sandbox,
  }) async {
    if (!ShwaryConfig.isConfigured) {
      throw ShwaryException('Configuration Shwary manquante.');
    }

    final response = await http
        .get(
          Uri.parse(
            '${ShwaryConfig.transactionsEndpoint(sandboxMode: sandboxMode)}/$transactionId',
          ),
          headers: _headers,
        )
        .timeout(Duration(seconds: ShwaryConfig.timeout));

    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = body.startsWith('{') || body.startsWith('[')
        ? jsonDecode(body)
        : <String, dynamic>{};

    final status = _readValue(decoded, 'status');
    final message =
        _readValue(decoded, 'message') ?? _readValue(decoded, 'error');
    final success =
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        (isSuccessfulStatus(status) ||
            (message ?? '').toLowerCase() == 'success');

    return ShwaryPaymentResult(
      success: success,
      isSandbox: sandboxMode,
      transactionId: transactionId,
      status: status,
      message: message,
      rawResponse: body,
    );
  }

  static Map<String, String> get _headers => {
    'x-merchant-id': ShwaryConfig.merchantId,
    'x-merchant-key': ShwaryConfig.merchantKey,
    'Content-Type': 'application/json',
  };

  static String _normalizeDrcPhoneNumber(String value) {
    var cleaned = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('243')) {
      return '+$cleaned';
    }
    if (cleaned.startsWith('0')) {
      return '+243${cleaned.substring(1)}';
    }
    return '+243$cleaned';
  }

  static void _validateDrcPhoneNumber(String value) {
    if (!RegExp(r'^\+243[0-9]{9}$').hasMatch(value)) {
      throw ShwaryException(
        'Numero Mobile Money invalide pour la RDC. Utilisez un numero comme 0991234567 ou +243991234567.',
      );
    }
  }

  static String _maskPhoneNumber(String value) {
    if (value.length <= 6) {
      return value;
    }
    return '${value.substring(0, 5)}****${value.substring(value.length - 3)}';
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

class ShwaryException implements Exception {
  ShwaryException(this.message);

  final String message;

  @override
  String toString() => message;
}
