# sqflmigrator

A sqflite migration helper for Flutter.

## Usage

```dart
import 'package:sqflmigrator/sqflmigrator.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
    final migrationsDir = Directory('./migrations');
    var db = await openDatabase('my_db.db');
    final migrator = SqflMigrator(
        db,
        migrationsDir: migrationsDir,
    );
    await migrator.init();
    await migrator.migrate();
}
```
    
