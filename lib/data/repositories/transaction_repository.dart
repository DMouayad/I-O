import 'package:sqflite/sqflite.dart';
import '../../models/transaction_model.dart';

abstract class TransactionRepository {
  Future<int> insert(TransactionModel t);
  Future<int> update(TransactionModel t);
  Future<int> delete(int id);
  Future<List<TransactionModel>> getAll();
  Future<List<String>> getPayeeSuggestions({String? query, int limit = 20});
}

class SqfliteTransactionRepository implements TransactionRepository {
  SqfliteTransactionRepository(this._db);
  final Database _db;

  @override
  Future<int> insert(TransactionModel t) =>
      _db.insert('transactions', t.toMap());

  @override
  Future<int> update(TransactionModel t) =>
      _db.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);

  @override
  Future<int> delete(int id) =>
      _db.delete('transactions', where: 'id = ?', whereArgs: [id]);

  @override
  Future<List<TransactionModel>> getAll() async {
    final rows = await _db.query('transactions', orderBy: 'date DESC');
    return rows.map(TransactionModel.fromMap).toList();
  }

  @override
  Future<List<String>> getPayeeSuggestions({
    String? query,
    int limit = 20,
  }) async {
    final hasQuery = query != null && query.trim().isNotEmpty;
    final rows = await _db.rawQuery(
      '''
      SELECT payee, MAX(date) AS last_used
      FROM transactions
      WHERE payee IS NOT NULL AND TRIM(payee) != ''
      ${hasQuery ? "AND payee LIKE ? ESCAPE '\\'" : ''}
      GROUP BY payee COLLATE NOCASE
      ORDER BY last_used DESC
      LIMIT ?
      ''',
      [if (hasQuery) '%${_escapeLike(query.trim())}%', limit],
    );
    return rows.map((r) => r['payee'] as String).toList();
  }

  static String _escapeLike(String input) => input
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
