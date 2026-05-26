import 'fee.dart';
import 'payment.dart';
import 'user.dart';

class StudentLedger {
  const StudentLedger({
    required this.student,
    required this.totalFees,
    required this.totalPaid,
    required this.balance,
    required this.feesCount,
  });

  final User student;
  final double totalFees;
  final double totalPaid;
  final double balance;
  final int feesCount;

  double get paymentPercentage => totalFees > 0 ? (totalPaid / totalFees) : 0.0;
  bool get isInOrder => balance <= 0;
}

class PaymentRow {
  const PaymentRow({
    required this.payment,
    required this.student,
    required this.fee,
  });

  final Payment payment;
  final User student;
  final Fee fee;
}

class FeeRow {
  const FeeRow({required this.fee, required this.student});

  final Fee fee;
  final User student;
}
