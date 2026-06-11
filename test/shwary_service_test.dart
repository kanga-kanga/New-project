import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:academic_fees_app/services/shwary_config.dart';
import 'package:academic_fees_app/services/shwary_service.dart';

void main() {
  group('ShwaryService', () {
    test('normalise les numéros RDC au format international', () {
      expect(ShwaryService.normalizePhoneNumber('0991234567'), '+243991234567');
      expect(
        ShwaryService.normalizePhoneNumber('243991234567'),
        '+243991234567',
      );
      expect(
        ShwaryService.normalizePhoneNumber('+243991234567'),
        '+243991234567',
      );
    });

    test('reconnait les statuts de paiement valides', () {
      expect(ShwaryService.isSuccessfulStatus('COMPLETED'), isTrue);
      expect(ShwaryService.isSuccessfulStatus('SUCCESS'), isTrue);
      expect(ShwaryService.isSuccessfulStatus('ACCEPTED'), isTrue);
      expect(ShwaryService.isSuccessfulStatus('success'), isTrue);
      expect(ShwaryService.isSuccessfulStatus('PENDING'), isFalse);
      expect(ShwaryService.isSuccessfulStatus('FAILED'), isFalse);
    });

    test('charge la configuration Shwary depuis les valeurs validées', () {
      expect(ShwaryConfig.gateway, 'shwary');
      expect(ShwaryConfig.merchantId, '991492ac-f6de-48d3-9bd5-d89e942c3caa');
      expect(
        ShwaryConfig.merchantKey,
        'shwary_d0fc8728-5274-4716-be97-3eb06b58e3c1',
      );
      expect(ShwaryConfig.minimumAmountCdf, 2900);
      expect(ShwaryConfig.isConfigured, isTrue);
      expect(
        ShwaryConfig.paymentEndpoint(),
        kIsWeb
            ? 'http://127.0.0.1:39102/api/shwary/payment'
            : 'https://api.shwary.com/api/v1/merchants/payment/DRC',
      );
    });
  });
}
