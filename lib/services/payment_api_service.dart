import 'shwary_service.dart';

class PaymentApiService {
  Future<ShwaryPaymentResult> pay({
    required double amount,
    required String phoneNumber,
  }) async {
    final initialised = await ShwaryService.initiatePayment(
      amount: amount,
      phoneNumber: phoneNumber,
    );

    if (!initialised.success || initialised.transactionId == null) {
      return initialised;
    }

    return ShwaryService.verifyTransaction(initialised.transactionId!);
  }
}
