class ShwaryConfig {
  static const String gateway = 'shwary';
  static const String merchantId = '991492ac-f6de-48d3-9bd5-d89e942c3caa';
  static const String merchantKey =
      'shwary_4340e1a3-5472-4b09-896e-38934efe6e9a';
  static const bool sandbox = false;
  static const int timeout = 30;
  static const int connectTimeout = 15;
  static const String countryCode = 'DRC';
  static const String currency = 'CDF';
  static const String baseUrl = 'https://api.shwary.com/api/v1/merchants';
  static const String appUrl =
      'https://88bdf6bbfc5c93.lhr.life/PROJETSTBAC3/public';
  static const String returnUrl = '$appUrl/payment/return';
  static const String notifyUrl = '$appUrl/payment/notify';
  static const String callbackUrl = '$appUrl/api/payment/callback';
  static const int minimumAmountCdf = 2900;

  static String paymentEndpoint({bool sandboxMode = sandbox}) {
    return sandboxMode
        ? '$baseUrl/payment/sandbox/$countryCode'
        : '$baseUrl/payment/$countryCode';
  }

  static String transactionsEndpoint({bool sandboxMode = sandbox}) =>
      '$baseUrl/transactions';

  static bool get isConfigured =>
      merchantId.isNotEmpty && merchantKey.isNotEmpty;
}
