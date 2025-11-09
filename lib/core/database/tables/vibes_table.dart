import 'package:drift/drift.dart';

/// Vibes table for caching journal entries locally
class Vibes extends Table {
  // Primary key (UUID from backend)
  TextColumn get id => text()();

  // Foreign key
  TextColumn get userId => text()();

  // Audio file info
  TextColumn get audioPath => text()(); // URL to audio file
  TextColumn get fileName => text()();
  IntColumn get duration => integer()(); // Duration in milliseconds

  // Content
  TextColumn get transcription => text().withDefault(const Constant(''))();
  TextColumn get mood => text().withDefault(const Constant('unknown'))();
  RealColumn get sentimentScore => real().nullable()();
  RealColumn get sentimentMagnitude => real().nullable()();

  // Processing status
  TextColumn get processingStatus => text().withDefault(const Constant('completed'))();

  // Metadata
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get processedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  // Local flags
  BoolColumn get isPendingUpload => boolean().withDefault(const Constant(false))();
  BoolColumn get isPendingDelete => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
