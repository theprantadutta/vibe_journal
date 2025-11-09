import 'package:drift/drift.dart';

/// Users table for caching user data locally
class Users extends Table {
  // Primary key
  TextColumn get uid => text()();

  // User profile
  TextColumn get email => text().nullable()();
  TextColumn get fullName => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get plan => text().withDefault(const Constant('free'))();
  IntColumn get cloudVibeCount => integer().withDefault(const Constant(0))();

  // Plan details
  IntColumn get maxCloudVibes => integer().withDefault(const Constant(75))();
  IntColumn get maxRecordingDurationMinutes => integer().withDefault(const Constant(5))();

  // Notification preferences (stored as JSON string)
  TextColumn get notificationPreferences => text().withDefault(const Constant('{}'))();

  // Metadata
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {uid};
}
