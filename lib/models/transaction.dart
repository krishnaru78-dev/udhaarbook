class UdhaarTransaction {
  final int? id;
  final int customerId;
  final String type; // 'udhaar' or 'payment'
  final double amount;
  final String? note;
  final String date;
  final String createdAt;

  UdhaarTransaction({
    this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    this.note,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'type': type,
      'amount': amount,
      'note': note,
      'date': date,
      'created_at': createdAt,
    };
  }

  factory UdhaarTransaction.fromMap(Map<String, dynamic> map) {
    return UdhaarTransaction(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      date: map['date'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  bool get isUdhaar => type == 'udhaar';
  bool get isPayment => type == 'payment';
}