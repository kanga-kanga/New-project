import 'shwary_service.dart';

class PaymentApiService {
  Future<ShwaryPaymentResult> pay({
    required double amount,
    required String phoneNumber,
  }) async {
    try {
      return ShwaryService.initiatePayment(
        amount: amount,
        phoneNumber: phoneNumber,
      );
    } on ShwaryException catch (error) {
      final message = error.message.toLowerCase();
      final shouldRetrySandbox =
          message.contains('invalid merchant key') ||
          message.contains('cle marchande') ||
          message.contains('unauthorized');

      if (!shouldRetrySandbox) {
        rethrow;
      }

      final sandboxInit = await ShwaryService.initiatePayment(
        amount: amount,
        phoneNumber: phoneNumber,
        sandboxMode: true,
      );
      return sandboxInit;
    }
  }
}
