class Receivable {
  final String id;
  final String clientName;
  final double amount;
  final DateTime date;
  bool isPaid;
  String? paymentTransactionId; // Link to the income transaction

  Receivable({
    required this.id,
    required this.clientName,
    required this.amount,
    required this.date,
    this.isPaid = false,
    this.paymentTransactionId,
  });
  // Persistence methods
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'amount': amount,
      'date': date.toIso8601String(),
      'isPaid': isPaid,
      'paymentTransactionId': paymentTransactionId,
    };
  }

  factory Receivable.fromJson(Map<String, dynamic> json) {
    return Receivable(
      id: json['id'],
      clientName: json['clientName'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      isPaid: json['isPaid'] ?? false,
      paymentTransactionId: json['paymentTransactionId'],
    );
  }
}

