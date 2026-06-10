class ShwaryConfig {
  static const String merchantId = '991492ac-f6de-48d3-9bd5-d89e942c3caa';
  static const String merchantKey =
      'shwary_acc92ffb-d728-4f89-9f64-d7661df576a6';
  static const bool sandbox = false;
  static const String countryCode = 'DRC';
  static const String currency = 'CDF';
  static const String baseUrl = 'https://api.shwary.com/api/v1/merchants';
  static const String apiUrl =
      'https://88bdf6bbfc5c93.lhr.life/PROJETSTBAC3/public';
  static const String callbackUrl = '$apiUrl/api/payment/callback';

  static String get paymentEndpoint => sandbox
      ? '$baseUrl/payment/sandbox/$countryCode'
      : '$baseUrl/payment/$countryCode';

  static String get transactionsEndpoint => '$baseUrl/transactions';
}
