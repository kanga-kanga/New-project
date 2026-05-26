import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:academic_fees_app/widgets/common_widgets.dart';
import 'package:academic_fees_app/models/fee.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  test('formats academic fee amounts', () {
    expect(formatMoney(450), contains('450'));
    expect(formatMoney(450), contains('CDF'));
  });

  test('formats academic dates', () {
    // formatMoney uses 'dd MMM yyyy' in fr_FR
    final formatted = formatDate(DateTime(2026, 5, 11));
    expect(formatted, contains('11'));
    expect(formatted, contains('mai'));
  });

  test('recognizes paid fees', () {
    final fee = Fee(
      id: 1,
      studentId: 1,
      title: 'Frais academiques',
      amount: 450,
      dueDate: DateTime(2026, 6, 10),
      status: 'paid',
      createdAt: DateTime(2026, 5, 11),
    );

    expect(fee.isPaid, isTrue);
  });
}
