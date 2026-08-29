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
      version: 2,
      onCreate: (db, version) async {
        await db.execute(createTransactionsTableSql);
        await db.execute(
          'CREATE INDEX idx_transactions_date ON transactions(date)',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_payee ON transactions(payee)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Dev data can be migrated freely — drop legacy columns if present.
          // ALTER DROP COLUMN is supported on recent SQLite; fallback to recreate.
          try {
            await db.execute('ALTER TABLE transactions DROP COLUMN category');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE transactions DROP COLUMN note');
          } catch (_) {
            // Fallback: recreate table without those columns (preserves payee data).
            try {
              await db.execute(
                'ALTER TABLE transactions RENAME TO transactions_old',
              );
              await db.execute(createTransactionsTableSql);
              await db.execute(
                'INSERT INTO transactions (id, type, amount, currency, payee, date, created_at) '
                'SELECT id, type, amount, currency, payee, date, created_at FROM transactions_old',
              );
              await db.execute('DROP TABLE transactions_old');
              await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date)',
              );
              await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_transactions_payee ON transactions(payee)',
              );
            } catch (_) {}
          }
        }
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
    payee TEXT,
    date INTEGER NOT NULL,
    created_at INTEGER NOT NULL
  )
  ''';
