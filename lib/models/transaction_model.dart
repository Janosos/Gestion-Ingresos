class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final TransactionCategory category;
  final String? description;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.description,
  });

  // Persistence methods
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.index,
      'category': category.index,
      'description': description,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      type: TransactionType.values[json['type']],
      category: TransactionCategory.values[json['category']],
      description: json['description'],
    );
  }
}


enum TransactionType {
  income,
  expense,
}

enum TransactionCategory {
  // Income
  salesCash,
  salesCard,
  salesTransfer,
  
  // Expense
  supplier,
  various,
}

