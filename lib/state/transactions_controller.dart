import 'package:signals_flutter/signals_flutter.dart';
import '../data/dev_seed.dart';
import '../data/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

class TransactionsController {
  TransactionsController(this._repo);
  final TransactionRepository _repo;

  final Signal<List<TransactionModel>> transactions = signal(
    <TransactionModel>[],
  );
  final Signal<bool> isLoading = signal(false);

  Future<void> load() async {
    isLoading.value = true;
    transactions.value = await _repo.getAll();
    isLoading.value = false;
  }

  Future<int> add(TransactionModel t) async {
    final id = await _repo.insert(t);
    await load();
    return id;
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    await load();
  }

  Future<void> update(TransactionModel t) async {
    await _repo.update(t);
    await load();
  }

  /// Deletes one calendar day (optionally one [type] slice) and returns the
  /// removed rows so the caller can offer Undo. Day boundaries use the same
  /// local-midnight convention as the reports grouping.
  Future<List<TransactionModel>> removeDay(
    DateTime day, {
    TransactionType? type,
  }) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final snapshot = transactions.value
        .where(
          (t) =>
              !t.date.isBefore(start) &&
              t.date.isBefore(end) &&
              (type == null || t.type == type),
        )
        .toList();
    if (snapshot.isEmpty) return const [];
    await _repo.deleteByDay(day, type: type);
    await load();
    return snapshot;
  }

  /// Re-inserts rows previously removed by [removeDay] (single refresh).
  Future<void> restoreAll(List<TransactionModel> snapshot) async {
    for (final t in snapshot) {
      await _repo.insert(t);
    }
    await load();
  }

  /// Dev-only: replaces (or appends to) all transactions with generated
  /// demo data for the current year. Returns the inserted count.
  Future<int> seedYearToDate({int seed = 42, bool wipe = true}) async {
    final now = DateTime.now();
    final rows = generateYearToDate(year: now.year, today: now, seed: seed);
    if (wipe) await _repo.deleteAll();
    for (final t in rows) {
      await _repo.insert(t);
    }
    await load();
    return rows.length;
  }

  /// Sync suggestions for Autocomplete (filters in-memory, ordered by recency).
  /// Covers empty query so recent payees show immediately.
  List<String> payeeSuggestions(String query) {
    final q = query.trim().toLowerCase();
    final seen = <String>{};
    final out = <String>[];
    // transactions is ordered by date DESC from getAll()
    for (final t in transactions.value) {
      final p = t.payee?.trim();
      if (p == null || p.isEmpty) continue;
      final lower = p.toLowerCase();
      if (!seen.add(lower)) continue;
      if (q.isEmpty || lower.contains(q)) {
        out.add(p);
        if (out.length >= 5) break;
      }
    }
    return out;
  }

  /// Async fallback when you need DB-level suggestions (e.g. before load).
  Future<List<String>> payeeSuggestionsAsync({String? query, int limit = 5}) =>
      _repo.getPayeeSuggestions(query: query, limit: limit);
}
