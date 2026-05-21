class Payment {
  const Payment({
    required this.id,
    required this.feeId,
    required this.studentId,
    required this.amount,
    required this.method,
    required this.reference,
    required this.paidAt,
  });

  final int id;
  final int feeId;
  final int studentId;
  final double amount;
  final String method;
  final String reference;
  final DateTime paidAt;

  factory Payment.fromMap(Map<String, Object?> map) {
    return Payment(
      id: map['id'] as int,
      feeId: map['fee_id'] as int,
      studentId: map['student_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      method: map['method'] as String,
      reference: map['reference'] as String,
      paidAt: DateTime.parse(map['paid_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'fee_id': feeId,
      'student_id': studentId,
      'amount': amount,
      'method': method,
      'reference': reference,
      'paid_at': paidAt.toIso8601String(),
    };
  }
}
