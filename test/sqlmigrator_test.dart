import 'package:flutter_test/flutter_test.dart';
import 'package:sqlmigrator/sqlmigrator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() {
  test('getPlatformVersion', () async {
    // migrations dir
    // get current dir
    final currentDir = Directory.current;
    // get migrations dir
    final migrationsDir = Directory('${currentDir.path}/test/migrations');
    var db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    final sqlmigrator = Sqlmigrator(db, migrationsPath: migrationsDir.path);
    await sqlmigrator.init();
    final results = await db.query('migrations');
    print(results);
    expect(results, isNotNull);
    await sqlmigrator.migrate(1);
    final results2 = await db.query('migrations');
    print(results2);
    expect(results2[0]['version'], 1);
    await sqlmigrator.undoMigrations(0);
    final results3 = await db.query('migrations');
    print(results3);
    expect(results3.isEmpty, true);
  });
}
