class Fee {
  const Fee({
    required this.id,
    required this.studentId,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final int studentId;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String status;
  final DateTime createdAt;

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';

  factory Fee.fromMap(Map<String, Object?> map) {
    return Fee(
      id: map['id'] as int,
      studentId: map['student_id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date'] as String),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'title': title,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
