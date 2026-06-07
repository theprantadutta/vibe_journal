import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/users_table.dart';
import 'tables/vibes_table.dart';
import 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

/// Main application database using Drift
@DriftDatabase(tables: [Users, Vibes, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle database migrations here when schema changes
        if (from < 2) {
          // Add subscription fields in schema version 2
          await m.addColumn(users, users.subscriptionType);
          await m.addColumn(users, users.subscriptionStatus);
        }
        if (from < 3) {
          // Add local audio cache fields in schema version 3
          await m.addColumn(vibes, vibes.localAudioPath);
          await m.addColumn(vibes, vibes.isAudioDownloaded);
        }
        if (from < 4) {
          // Remove complex sync flags in schema version 4 (simplified architecture)
          // Note: SQLite doesn't support dropping columns easily.
          // Drift will automatically handle this on table access.
          // Data will be preserved, removed columns will be ignored.
        }
      },
    );
  }
}

/// Open database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'vibe_journal.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
