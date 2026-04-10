import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/water_log.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'hydro.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE water_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            type TEXT NOT NULL,
            amount_ml INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertLog(WaterLog log) async {
    final d = await db;
    await d.insert('water_logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await _pruneOldLogs(d);
  }

  Future<List<WaterLog>> getLogsForDay(DateTime day) async {
    final d = await db;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await d.query(
      'water_logs',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );
    return rows.map(WaterLog.fromMap).toList();
  }

  Future<void> deleteLog(int id) async {
    final d = await db;
    await d.delete('water_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteLogsForDay(DateTime day) async {
    final d = await db;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    await d.delete('water_logs',
        where: 'timestamp >= ? AND timestamp < ?',
        whereArgs: [
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ]);
  }

  Future<void> _pruneOldLogs(Database d) async {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 2))
        .millisecondsSinceEpoch;
    await d.delete('water_logs',
        where: 'timestamp < ?', whereArgs: [cutoff]);
  }
}
