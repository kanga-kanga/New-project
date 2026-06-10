import 'package:flutter_test/flutter_test.dart';
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
  });
}
