enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get value => this == TransactionType.income ? 'income' : 'expense';

  static TransactionType fromValue(String v) =>
      v == 'income' ? TransactionType.income : TransactionType.expense;
}

class TransactionModel {
  final int? id;
  final TransactionType type;
  final double amount;
  final String currency;
  final String? payee;
  final DateTime date;
  final DateTime createdAt;

  const TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.currency,
    this.payee,
    required this.date,
    required this.createdAt,
  });

  TransactionModel copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? currency,
    String? payee,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      payee: payee ?? this.payee,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'type': type.value,
    'amount': amount,
    'currency': currency,
    'payee': payee,
    'date': date.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: TransactionTypeX.fromValue(map['type'] as String),
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      payee: map['payee'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
