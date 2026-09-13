import 'package:io/data/repositories/transaction_repository.dart';
import 'package:io/models/transaction_model.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<TransactionModel> _items = [];
  int _nextId = 1;

  @override
  Future<int> insert(TransactionModel t) async {
    final withId = t.copyWith(id: _nextId++);
    _items.add(withId);
    return withId.id!;
  }

  @override
  Future<int> update(TransactionModel t) async {
    final idx = _items.indexWhere((e) => e.id == t.id);
    if (idx != -1) _items[idx] = t;
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    _items.removeWhere((e) => e.id == id);
    return 1;
  }

  @override
  Future<int> deleteAll() async {
    final count = _items.length;
    _items.clear();
    return count;
  }

  @override
  Future<int> deleteByDay(DateTime day, {TransactionType? type}) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final before = _items.length;
    _items.removeWhere(
      (e) =>
          !e.date.isBefore(start) &&
          e.date.isBefore(end) &&
          (type == null || e.type == type),
    );
    return before - _items.length;
  }

  @override
  Future<List<TransactionModel>> getAll() async {
    final copy = List<TransactionModel>.of(_items);
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  // FakeTransactionRepository
  @override
  Future<List<String>> getPayeeSuggestions({
    String? query,
    int limit = 20,
  }) async {
    final q = query?.trim().toLowerCase() ?? '';
    final names =
        _items
            .map((e) => e.payee)
            .whereType<String>()
            .where((p) => p.trim().isNotEmpty)
            .where((p) => q.isEmpty || p.toLowerCase().contains(q))
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names.take(limit).toList();
  }
}
