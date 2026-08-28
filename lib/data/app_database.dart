import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  Database? _db;

  Database get database {
    final db = _db;
    if (db == null) throw StateError('Database not initialized');
    return db;
  }

  Future<void> init() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'i_and_o.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(createTransactionsTableSql);
        await db.execute(
          'CREATE INDEX idx_transactions_date ON transactions(date)',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_payee ON transactions(payee)',
        );
      },
    );
  }
}

const createTransactionsTableSql = '''
  CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    amount REAL NOT NULL,
    currency TEXT NOT NULL,
    category TEXT,
    payee TEXT,
    note TEXT,
    date INTEGER NOT NULL,
    created_at INTEGER NOT NULL
  )
 ''';
