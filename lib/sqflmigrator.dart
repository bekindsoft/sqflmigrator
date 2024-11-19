import 'sqlmigrator_platform_interface.dart';
import 'package:sqflite/sqflite.dart';
// path
import 'dart:io';
import 'package:path/path.dart' as p;

const String schema = '''CREATE TABLE IF NOT EXISTS migrations (
  version INTEGER PRIMARY KEY, name TEXT, md5 TEXT, run_at TIMESTAMP WITH TIME ZONE
);''';

enum MigrationType {
  //do
  UP,
  //undo
  DOWN,
}

MigrationType migrationTypeFromString(String type) {
  switch (type) {
    case 'do':
      return MigrationType.UP;
    case 'undo':
      return MigrationType.DOWN;
    default:
      throw Exception('Invalid migration type');
  }
}

class Migration {
  final int version;
  final String name;
  final String md5;
  // migration path
  final String path;
  final MigrationType type;

  Migration({
    required this.version,
    required this.type,
    required this.name,
    required this.md5,
    required this.path,
  });
}

class Sqlmigrator {
  Database db;

  // path to migrations
  String migrationsPath;

  Sqlmigrator(
    this.db, {
    required this.migrationsPath,
  });

  Future<String?> getPlatformVersion() {
    return SqlmigratorPlatform.instance.getPlatformVersion();
  }

  Future<void> init() async {
    await db.execute(schema);
  }

  Future<List<Migration>> getMigrationFiles() async {
    final files = await Directory(migrationsPath).list().toList();
    final migrations = files
        .map((file) {
          // get version from file name in format 0001.do.name.sql
          final extension = p.extension(file.path);
          print("Extension: $extension");
          if (extension != '.sql') {
            return null;
          }
          final filename = p.basenameWithoutExtension(file.path);
          //file.path.split('/').last;

          final filesplit = filename.split('.');
          final fileVersion = int.parse(filesplit.first);
          // should do?
          // will break if file name is not in format 0001.do.name.sql
          final shouldDo = filesplit.elementAt(1);
          final migrationType = migrationTypeFromString(shouldDo);

          // get name from file name in format 0001_do_name.sql
          final name = filename.split('.').elementAtOrNull(2);
          //final version = filename.split('_')[0];
          //// get name from file name in format 0001_name.sql
          //final name = filename.split('_')[1].split('.').first;
          // get md5 from file
          final md5 = 'todo';
          // get run_at from file
          return Migration(
            version: fileVersion,
            name: name ?? '',
            md5: md5,
            path: file.path,
            type: migrationType,
          );
        })
        .toList()
        .whereType<Migration>()
        .toList();
    migrations.sort((a, b) {
      // sort by comparing version int and name string
      if (a.version == b.version) {
        return a.name.compareTo(b.name);
      }
      return a.version.compareTo(b.version);
    });
    return migrations;
  }

  Future<void> migrate(int? version) async {
    // get all files in migrationsPath
    // get all migrations from db
    // compare and run migrations
    print("Migrating to version $version with path $migrationsPath");
    final files = await Directory(migrationsPath).list().toList();
    print("Files: $files");
    final migrations = await getMigrationFiles();

    print("Migration list: $migrations");

    final upMigrations = migrations.where((migration) => migration.type == MigrationType.UP).toList();
    //for (final migration in migrations) {
    await Future.wait(
        upMigrations.where((migration) => version != null ? migration.version <= version : true).map((migration) async {
      // check if migration exists in db
      final result = await db.query('migrations', where: 'version = ?', whereArgs: [migration.version]);
      if (result.isEmpty) {
        // run migration
        final file = File(migration.path);
        final sql = await file.readAsString();
        print("Running migration ${migration.version} - ${migration.name} with sql $sql");
        await db.execute(sql);
        // save migration to db
        await db.insert('migrations', {
          'version': migration.version,
          'name': migration.name,
          'md5': migration.md5,
          'run_at': DateTime.now().toIso8601String(),
        });
      }
    }));
  }

  /// Undo migrations to a specific version e.g. 1 would undo all migrations up to version 1
  Future<void> undoMigrations(int? version) async {
    // get all migrations from db
    // sort by version desc
    // run undo on each migration
    final migrations = await getMigrationFiles();
    // only down migrations
    var downMigrations = migrations.where((migration) => migration.type == MigrationType.DOWN).toList();
    downMigrations = downMigrations.reversed.toList();

    // TODO migrate down to version is dangerous, if null only undo the last migration
    await Future.wait(downMigrations
        .where((migration) => version != null ? migration.version > version : true)
        .map((migration) async {
      final res = await db.query('migrations', where: 'version = ?', whereArgs: [migration.version]);
      // no need to undo if migration does not exist
      if (res.isEmpty) {
        return;
      }

      // run undo migration
      final file = File(migration.path);
      final sql = await file.readAsString();
      print("Running undo migration ${migration.version} - ${migration.name} with sql $sql");
      await db.execute(sql);
      // delete migration from db
      await db.delete('migrations', where: 'version = ?', whereArgs: [migration.version]);
    }));
  }
}
