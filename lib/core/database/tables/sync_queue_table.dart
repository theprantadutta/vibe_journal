import 'package:drift/drift.dart';

/// Sync queue table for tracking pending operations when offline
class SyncQueue extends Table {
  // Primary key (auto-increment)
  IntColumn get id => integer().autoIncrement()();

  // Operation details
  TextColumn get operation => text()(); // 'upload', 'delete', 'update'
  TextColumn get entityType => text()(); // 'vibe', 'user'
  TextColumn get entityId => text()(); // ID of the entity

  // Operation data (stored as JSON string)
  TextColumn get data => text()();

  // Retry tracking
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get maxRetries => integer().withDefault(const Constant(3))();

  // Status
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // 'pending', 'processing', 'failed', 'completed'
  TextColumn get errorMessage => text().nullable()();

  // Metadata
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}
