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
  final String? category;
  final String? payee;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.currency,
    this.category,
    this.payee,
    this.note,
    required this.date,
    required this.createdAt,
  });

  TransactionModel copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? currency,
    String? category,
    bool clearCategory = false,
    String? payee,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: clearCategory ? null : (category ?? this.category),
      payee: payee ?? this.payee,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'type': type.value,
    'amount': amount,
    'currency': currency,
    'category': category,
    'payee': payee,
    'note': note,
    'date': date.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: TransactionTypeX.fromValue(map['type'] as String),
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      category: map['category'] as String?,
      payee: map['payee'] as String?,
      note: map['note'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
