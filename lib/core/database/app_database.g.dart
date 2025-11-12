// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planMeta = const VerificationMeta('plan');
  @override
  late final GeneratedColumn<String> plan = GeneratedColumn<String>(
    'plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('free'),
  );
  static const VerificationMeta _cloudVibeCountMeta = const VerificationMeta(
    'cloudVibeCount',
  );
  @override
  late final GeneratedColumn<int> cloudVibeCount = GeneratedColumn<int>(
    'cloud_vibe_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxCloudVibesMeta = const VerificationMeta(
    'maxCloudVibes',
  );
  @override
  late final GeneratedColumn<int> maxCloudVibes = GeneratedColumn<int>(
    'max_cloud_vibes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(75),
  );
  static const VerificationMeta _maxRecordingDurationMinutesMeta =
      const VerificationMeta('maxRecordingDurationMinutes');
  @override
  late final GeneratedColumn<int> maxRecordingDurationMinutes =
      GeneratedColumn<int>(
        'max_recording_duration_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(5),
      );
  static const VerificationMeta _subscriptionTypeMeta = const VerificationMeta(
    'subscriptionType',
  );
  @override
  late final GeneratedColumn<String> subscriptionType = GeneratedColumn<String>(
    'subscription_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subscriptionStatusMeta =
      const VerificationMeta('subscriptionStatus');
  @override
  late final GeneratedColumn<String> subscriptionStatus =
      GeneratedColumn<String>(
        'subscription_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('free'),
      );
  static const VerificationMeta _notificationPreferencesMeta =
      const VerificationMeta('notificationPreferences');
  @override
  late final GeneratedColumn<String> notificationPreferences =
      GeneratedColumn<String>(
        'notification_preferences',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uid,
    email,
    fullName,
    photoUrl,
    plan,
    cloudVibeCount,
    maxCloudVibes,
    maxRecordingDurationMinutes,
    subscriptionType,
    subscriptionStatus,
    notificationPreferences,
    createdAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('plan')) {
      context.handle(
        _planMeta,
        plan.isAcceptableOrUnknown(data['plan']!, _planMeta),
      );
    }
    if (data.containsKey('cloud_vibe_count')) {
      context.handle(
        _cloudVibeCountMeta,
        cloudVibeCount.isAcceptableOrUnknown(
          data['cloud_vibe_count']!,
          _cloudVibeCountMeta,
        ),
      );
    }
    if (data.containsKey('max_cloud_vibes')) {
      context.handle(
        _maxCloudVibesMeta,
        maxCloudVibes.isAcceptableOrUnknown(
          data['max_cloud_vibes']!,
          _maxCloudVibesMeta,
        ),
      );
    }
    if (data.containsKey('max_recording_duration_minutes')) {
      context.handle(
        _maxRecordingDurationMinutesMeta,
        maxRecordingDurationMinutes.isAcceptableOrUnknown(
          data['max_recording_duration_minutes']!,
          _maxRecordingDurationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('subscription_type')) {
      context.handle(
        _subscriptionTypeMeta,
        subscriptionType.isAcceptableOrUnknown(
          data['subscription_type']!,
          _subscriptionTypeMeta,
        ),
      );
    }
    if (data.containsKey('subscription_status')) {
      context.handle(
        _subscriptionStatusMeta,
        subscriptionStatus.isAcceptableOrUnknown(
          data['subscription_status']!,
          _subscriptionStatusMeta,
        ),
      );
    }
    if (data.containsKey('notification_preferences')) {
      context.handle(
        _notificationPreferencesMeta,
        notificationPreferences.isAcceptableOrUnknown(
          data['notification_preferences']!,
          _notificationPreferencesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      plan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan'],
      )!,
      cloudVibeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cloud_vibe_count'],
      )!,
      maxCloudVibes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_cloud_vibes'],
      )!,
      maxRecordingDurationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_recording_duration_minutes'],
      )!,
      subscriptionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subscription_type'],
      ),
      subscriptionStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subscription_status'],
      )!,
      notificationPreferences: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notification_preferences'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String uid;
  final String? email;
  final String? fullName;
  final String? photoUrl;
  final String plan;
  final int cloudVibeCount;
  final int maxCloudVibes;
  final int maxRecordingDurationMinutes;
  final String? subscriptionType;
  final String subscriptionStatus;
  final String notificationPreferences;
  final DateTime createdAt;
  final DateTime? lastSyncedAt;
  const User({
    required this.uid,
    this.email,
    this.fullName,
    this.photoUrl,
    required this.plan,
    required this.cloudVibeCount,
    required this.maxCloudVibes,
    required this.maxRecordingDurationMinutes,
    this.subscriptionType,
    required this.subscriptionStatus,
    required this.notificationPreferences,
    required this.createdAt,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || fullName != null) {
      map['full_name'] = Variable<String>(fullName);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    map['plan'] = Variable<String>(plan);
    map['cloud_vibe_count'] = Variable<int>(cloudVibeCount);
    map['max_cloud_vibes'] = Variable<int>(maxCloudVibes);
    map['max_recording_duration_minutes'] = Variable<int>(
      maxRecordingDurationMinutes,
    );
    if (!nullToAbsent || subscriptionType != null) {
      map['subscription_type'] = Variable<String>(subscriptionType);
    }
    map['subscription_status'] = Variable<String>(subscriptionStatus);
    map['notification_preferences'] = Variable<String>(notificationPreferences);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      uid: Value(uid),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      fullName: fullName == null && nullToAbsent
          ? const Value.absent()
          : Value(fullName),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      plan: Value(plan),
      cloudVibeCount: Value(cloudVibeCount),
      maxCloudVibes: Value(maxCloudVibes),
      maxRecordingDurationMinutes: Value(maxRecordingDurationMinutes),
      subscriptionType: subscriptionType == null && nullToAbsent
          ? const Value.absent()
          : Value(subscriptionType),
      subscriptionStatus: Value(subscriptionStatus),
      notificationPreferences: Value(notificationPreferences),
      createdAt: Value(createdAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      uid: serializer.fromJson<String>(json['uid']),
      email: serializer.fromJson<String?>(json['email']),
      fullName: serializer.fromJson<String?>(json['fullName']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      plan: serializer.fromJson<String>(json['plan']),
      cloudVibeCount: serializer.fromJson<int>(json['cloudVibeCount']),
      maxCloudVibes: serializer.fromJson<int>(json['maxCloudVibes']),
      maxRecordingDurationMinutes: serializer.fromJson<int>(
        json['maxRecordingDurationMinutes'],
      ),
      subscriptionType: serializer.fromJson<String?>(json['subscriptionType']),
      subscriptionStatus: serializer.fromJson<String>(
        json['subscriptionStatus'],
      ),
      notificationPreferences: serializer.fromJson<String>(
        json['notificationPreferences'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'email': serializer.toJson<String?>(email),
      'fullName': serializer.toJson<String?>(fullName),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'plan': serializer.toJson<String>(plan),
      'cloudVibeCount': serializer.toJson<int>(cloudVibeCount),
      'maxCloudVibes': serializer.toJson<int>(maxCloudVibes),
      'maxRecordingDurationMinutes': serializer.toJson<int>(
        maxRecordingDurationMinutes,
      ),
      'subscriptionType': serializer.toJson<String?>(subscriptionType),
      'subscriptionStatus': serializer.toJson<String>(subscriptionStatus),
      'notificationPreferences': serializer.toJson<String>(
        notificationPreferences,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  User copyWith({
    String? uid,
    Value<String?> email = const Value.absent(),
    Value<String?> fullName = const Value.absent(),
    Value<String?> photoUrl = const Value.absent(),
    String? plan,
    int? cloudVibeCount,
    int? maxCloudVibes,
    int? maxRecordingDurationMinutes,
    Value<String?> subscriptionType = const Value.absent(),
    String? subscriptionStatus,
    String? notificationPreferences,
    DateTime? createdAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => User(
    uid: uid ?? this.uid,
    email: email.present ? email.value : this.email,
    fullName: fullName.present ? fullName.value : this.fullName,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    plan: plan ?? this.plan,
    cloudVibeCount: cloudVibeCount ?? this.cloudVibeCount,
    maxCloudVibes: maxCloudVibes ?? this.maxCloudVibes,
    maxRecordingDurationMinutes:
        maxRecordingDurationMinutes ?? this.maxRecordingDurationMinutes,
    subscriptionType: subscriptionType.present
        ? subscriptionType.value
        : this.subscriptionType,
    subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
    notificationPreferences:
        notificationPreferences ?? this.notificationPreferences,
    createdAt: createdAt ?? this.createdAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      uid: data.uid.present ? data.uid.value : this.uid,
      email: data.email.present ? data.email.value : this.email,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      plan: data.plan.present ? data.plan.value : this.plan,
      cloudVibeCount: data.cloudVibeCount.present
          ? data.cloudVibeCount.value
          : this.cloudVibeCount,
      maxCloudVibes: data.maxCloudVibes.present
          ? data.maxCloudVibes.value
          : this.maxCloudVibes,
      maxRecordingDurationMinutes: data.maxRecordingDurationMinutes.present
          ? data.maxRecordingDurationMinutes.value
          : this.maxRecordingDurationMinutes,
      subscriptionType: data.subscriptionType.present
          ? data.subscriptionType.value
          : this.subscriptionType,
      subscriptionStatus: data.subscriptionStatus.present
          ? data.subscriptionStatus.value
          : this.subscriptionStatus,
      notificationPreferences: data.notificationPreferences.present
          ? data.notificationPreferences.value
          : this.notificationPreferences,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('uid: $uid, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('plan: $plan, ')
          ..write('cloudVibeCount: $cloudVibeCount, ')
          ..write('maxCloudVibes: $maxCloudVibes, ')
          ..write('maxRecordingDurationMinutes: $maxRecordingDurationMinutes, ')
          ..write('subscriptionType: $subscriptionType, ')
          ..write('subscriptionStatus: $subscriptionStatus, ')
          ..write('notificationPreferences: $notificationPreferences, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uid,
    email,
    fullName,
    photoUrl,
    plan,
    cloudVibeCount,
    maxCloudVibes,
    maxRecordingDurationMinutes,
    subscriptionType,
    subscriptionStatus,
    notificationPreferences,
    createdAt,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.uid == this.uid &&
          other.email == this.email &&
          other.fullName == this.fullName &&
          other.photoUrl == this.photoUrl &&
          other.plan == this.plan &&
          other.cloudVibeCount == this.cloudVibeCount &&
          other.maxCloudVibes == this.maxCloudVibes &&
          other.maxRecordingDurationMinutes ==
              this.maxRecordingDurationMinutes &&
          other.subscriptionType == this.subscriptionType &&
          other.subscriptionStatus == this.subscriptionStatus &&
          other.notificationPreferences == this.notificationPreferences &&
          other.createdAt == this.createdAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> uid;
  final Value<String?> email;
  final Value<String?> fullName;
  final Value<String?> photoUrl;
  final Value<String> plan;
  final Value<int> cloudVibeCount;
  final Value<int> maxCloudVibes;
  final Value<int> maxRecordingDurationMinutes;
  final Value<String?> subscriptionType;
  final Value<String> subscriptionStatus;
  final Value<String> notificationPreferences;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.uid = const Value.absent(),
    this.email = const Value.absent(),
    this.fullName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.plan = const Value.absent(),
    this.cloudVibeCount = const Value.absent(),
    this.maxCloudVibes = const Value.absent(),
    this.maxRecordingDurationMinutes = const Value.absent(),
    this.subscriptionType = const Value.absent(),
    this.subscriptionStatus = const Value.absent(),
    this.notificationPreferences = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String uid,
    this.email = const Value.absent(),
    this.fullName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.plan = const Value.absent(),
    this.cloudVibeCount = const Value.absent(),
    this.maxCloudVibes = const Value.absent(),
    this.maxRecordingDurationMinutes = const Value.absent(),
    this.subscriptionType = const Value.absent(),
    this.subscriptionStatus = const Value.absent(),
    this.notificationPreferences = const Value.absent(),
    required DateTime createdAt,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       createdAt = Value(createdAt);
  static Insertable<User> custom({
    Expression<String>? uid,
    Expression<String>? email,
    Expression<String>? fullName,
    Expression<String>? photoUrl,
    Expression<String>? plan,
    Expression<int>? cloudVibeCount,
    Expression<int>? maxCloudVibes,
    Expression<int>? maxRecordingDurationMinutes,
    Expression<String>? subscriptionType,
    Expression<String>? subscriptionStatus,
    Expression<String>? notificationPreferences,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (email != null) 'email': email,
      if (fullName != null) 'full_name': fullName,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (plan != null) 'plan': plan,
      if (cloudVibeCount != null) 'cloud_vibe_count': cloudVibeCount,
      if (maxCloudVibes != null) 'max_cloud_vibes': maxCloudVibes,
      if (maxRecordingDurationMinutes != null)
        'max_recording_duration_minutes': maxRecordingDurationMinutes,
      if (subscriptionType != null) 'subscription_type': subscriptionType,
      if (subscriptionStatus != null) 'subscription_status': subscriptionStatus,
      if (notificationPreferences != null)
        'notification_preferences': notificationPreferences,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? uid,
    Value<String?>? email,
    Value<String?>? fullName,
    Value<String?>? photoUrl,
    Value<String>? plan,
    Value<int>? cloudVibeCount,
    Value<int>? maxCloudVibes,
    Value<int>? maxRecordingDurationMinutes,
    Value<String?>? subscriptionType,
    Value<String>? subscriptionStatus,
    Value<String>? notificationPreferences,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      plan: plan ?? this.plan,
      cloudVibeCount: cloudVibeCount ?? this.cloudVibeCount,
      maxCloudVibes: maxCloudVibes ?? this.maxCloudVibes,
      maxRecordingDurationMinutes:
          maxRecordingDurationMinutes ?? this.maxRecordingDurationMinutes,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (plan.present) {
      map['plan'] = Variable<String>(plan.value);
    }
    if (cloudVibeCount.present) {
      map['cloud_vibe_count'] = Variable<int>(cloudVibeCount.value);
    }
    if (maxCloudVibes.present) {
      map['max_cloud_vibes'] = Variable<int>(maxCloudVibes.value);
    }
    if (maxRecordingDurationMinutes.present) {
      map['max_recording_duration_minutes'] = Variable<int>(
        maxRecordingDurationMinutes.value,
      );
    }
    if (subscriptionType.present) {
      map['subscription_type'] = Variable<String>(subscriptionType.value);
    }
    if (subscriptionStatus.present) {
      map['subscription_status'] = Variable<String>(subscriptionStatus.value);
    }
    if (notificationPreferences.present) {
      map['notification_preferences'] = Variable<String>(
        notificationPreferences.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('uid: $uid, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('plan: $plan, ')
          ..write('cloudVibeCount: $cloudVibeCount, ')
          ..write('maxCloudVibes: $maxCloudVibes, ')
          ..write('maxRecordingDurationMinutes: $maxRecordingDurationMinutes, ')
          ..write('subscriptionType: $subscriptionType, ')
          ..write('subscriptionStatus: $subscriptionStatus, ')
          ..write('notificationPreferences: $notificationPreferences, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VibesTable extends Vibes with TableInfo<$VibesTable, Vibe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VibesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioPathMeta = const VerificationMeta(
    'audioPath',
  );
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
    'audio_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transcriptionMeta = const VerificationMeta(
    'transcription',
  );
  @override
  late final GeneratedColumn<String> transcription = GeneratedColumn<String>(
    'transcription',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _sentimentScoreMeta = const VerificationMeta(
    'sentimentScore',
  );
  @override
  late final GeneratedColumn<double> sentimentScore = GeneratedColumn<double>(
    'sentiment_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sentimentMagnitudeMeta =
      const VerificationMeta('sentimentMagnitude');
  @override
  late final GeneratedColumn<double> sentimentMagnitude =
      GeneratedColumn<double>(
        'sentiment_magnitude',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _processingStatusMeta = const VerificationMeta(
    'processingStatus',
  );
  @override
  late final GeneratedColumn<String> processingStatus = GeneratedColumn<String>(
    'processing_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('completed'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processedAtMeta = const VerificationMeta(
    'processedAt',
  );
  @override
  late final GeneratedColumn<DateTime> processedAt = GeneratedColumn<DateTime>(
    'processed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingUploadMeta = const VerificationMeta(
    'isPendingUpload',
  );
  @override
  late final GeneratedColumn<bool> isPendingUpload = GeneratedColumn<bool>(
    'is_pending_upload',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_upload" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPendingDeleteMeta = const VerificationMeta(
    'isPendingDelete',
  );
  @override
  late final GeneratedColumn<bool> isPendingDelete = GeneratedColumn<bool>(
    'is_pending_delete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending_delete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncRetryCountMeta = const VerificationMeta(
    'syncRetryCount',
  );
  @override
  late final GeneratedColumn<int> syncRetryCount = GeneratedColumn<int>(
    'sync_retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncAttemptMeta = const VerificationMeta(
    'lastSyncAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAttempt =
      GeneratedColumn<DateTime>(
        'last_sync_attempt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localAudioPathMeta = const VerificationMeta(
    'localAudioPath',
  );
  @override
  late final GeneratedColumn<String> localAudioPath = GeneratedColumn<String>(
    'local_audio_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAudioDownloadedMeta = const VerificationMeta(
    'isAudioDownloaded',
  );
  @override
  late final GeneratedColumn<bool> isAudioDownloaded = GeneratedColumn<bool>(
    'is_audio_downloaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_audio_downloaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    audioPath,
    fileName,
    duration,
    transcription,
    mood,
    sentimentScore,
    sentimentMagnitude,
    processingStatus,
    createdAt,
    processedAt,
    lastSyncedAt,
    isPendingUpload,
    isPendingDelete,
    isSynced,
    syncRetryCount,
    lastSyncAttempt,
    localAudioPath,
    isAudioDownloaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vibes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Vibe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('audio_path')) {
      context.handle(
        _audioPathMeta,
        audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta),
      );
    } else if (isInserting) {
      context.missing(_audioPathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('transcription')) {
      context.handle(
        _transcriptionMeta,
        transcription.isAcceptableOrUnknown(
          data['transcription']!,
          _transcriptionMeta,
        ),
      );
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('sentiment_score')) {
      context.handle(
        _sentimentScoreMeta,
        sentimentScore.isAcceptableOrUnknown(
          data['sentiment_score']!,
          _sentimentScoreMeta,
        ),
      );
    }
    if (data.containsKey('sentiment_magnitude')) {
      context.handle(
        _sentimentMagnitudeMeta,
        sentimentMagnitude.isAcceptableOrUnknown(
          data['sentiment_magnitude']!,
          _sentimentMagnitudeMeta,
        ),
      );
    }
    if (data.containsKey('processing_status')) {
      context.handle(
        _processingStatusMeta,
        processingStatus.isAcceptableOrUnknown(
          data['processing_status']!,
          _processingStatusMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('processed_at')) {
      context.handle(
        _processedAtMeta,
        processedAt.isAcceptableOrUnknown(
          data['processed_at']!,
          _processedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_pending_upload')) {
      context.handle(
        _isPendingUploadMeta,
        isPendingUpload.isAcceptableOrUnknown(
          data['is_pending_upload']!,
          _isPendingUploadMeta,
        ),
      );
    }
    if (data.containsKey('is_pending_delete')) {
      context.handle(
        _isPendingDeleteMeta,
        isPendingDelete.isAcceptableOrUnknown(
          data['is_pending_delete']!,
          _isPendingDeleteMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('sync_retry_count')) {
      context.handle(
        _syncRetryCountMeta,
        syncRetryCount.isAcceptableOrUnknown(
          data['sync_retry_count']!,
          _syncRetryCountMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_attempt')) {
      context.handle(
        _lastSyncAttemptMeta,
        lastSyncAttempt.isAcceptableOrUnknown(
          data['last_sync_attempt']!,
          _lastSyncAttemptMeta,
        ),
      );
    }
    if (data.containsKey('local_audio_path')) {
      context.handle(
        _localAudioPathMeta,
        localAudioPath.isAcceptableOrUnknown(
          data['local_audio_path']!,
          _localAudioPathMeta,
        ),
      );
    }
    if (data.containsKey('is_audio_downloaded')) {
      context.handle(
        _isAudioDownloadedMeta,
        isAudioDownloaded.isAcceptableOrUnknown(
          data['is_audio_downloaded']!,
          _isAudioDownloadedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vibe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vibe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      audioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_path'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      transcription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcription'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      )!,
      sentimentScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sentiment_score'],
      ),
      sentimentMagnitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sentiment_magnitude'],
      ),
      processingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}processing_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      processedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}processed_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      isPendingUpload: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_upload'],
      )!,
      isPendingDelete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending_delete'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      syncRetryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_retry_count'],
      )!,
      lastSyncAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_attempt'],
      ),
      localAudioPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_audio_path'],
      ),
      isAudioDownloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_audio_downloaded'],
      )!,
    );
  }

  @override
  $VibesTable createAlias(String alias) {
    return $VibesTable(attachedDatabase, alias);
  }
}

class Vibe extends DataClass implements Insertable<Vibe> {
  final String id;
  final String userId;
  final String audioPath;
  final String fileName;
  final int duration;
  final String transcription;
  final String mood;
  final double? sentimentScore;
  final double? sentimentMagnitude;
  final String processingStatus;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? lastSyncedAt;
  final bool isPendingUpload;
  final bool isPendingDelete;
  final bool isSynced;
  final int syncRetryCount;
  final DateTime? lastSyncAttempt;
  final String? localAudioPath;
  final bool isAudioDownloaded;
  const Vibe({
    required this.id,
    required this.userId,
    required this.audioPath,
    required this.fileName,
    required this.duration,
    required this.transcription,
    required this.mood,
    this.sentimentScore,
    this.sentimentMagnitude,
    required this.processingStatus,
    required this.createdAt,
    this.processedAt,
    this.lastSyncedAt,
    required this.isPendingUpload,
    required this.isPendingDelete,
    required this.isSynced,
    required this.syncRetryCount,
    this.lastSyncAttempt,
    this.localAudioPath,
    required this.isAudioDownloaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['audio_path'] = Variable<String>(audioPath);
    map['file_name'] = Variable<String>(fileName);
    map['duration'] = Variable<int>(duration);
    map['transcription'] = Variable<String>(transcription);
    map['mood'] = Variable<String>(mood);
    if (!nullToAbsent || sentimentScore != null) {
      map['sentiment_score'] = Variable<double>(sentimentScore);
    }
    if (!nullToAbsent || sentimentMagnitude != null) {
      map['sentiment_magnitude'] = Variable<double>(sentimentMagnitude);
    }
    map['processing_status'] = Variable<String>(processingStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || processedAt != null) {
      map['processed_at'] = Variable<DateTime>(processedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['is_pending_upload'] = Variable<bool>(isPendingUpload);
    map['is_pending_delete'] = Variable<bool>(isPendingDelete);
    map['is_synced'] = Variable<bool>(isSynced);
    map['sync_retry_count'] = Variable<int>(syncRetryCount);
    if (!nullToAbsent || lastSyncAttempt != null) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt);
    }
    if (!nullToAbsent || localAudioPath != null) {
      map['local_audio_path'] = Variable<String>(localAudioPath);
    }
    map['is_audio_downloaded'] = Variable<bool>(isAudioDownloaded);
    return map;
  }

  VibesCompanion toCompanion(bool nullToAbsent) {
    return VibesCompanion(
      id: Value(id),
      userId: Value(userId),
      audioPath: Value(audioPath),
      fileName: Value(fileName),
      duration: Value(duration),
      transcription: Value(transcription),
      mood: Value(mood),
      sentimentScore: sentimentScore == null && nullToAbsent
          ? const Value.absent()
          : Value(sentimentScore),
      sentimentMagnitude: sentimentMagnitude == null && nullToAbsent
          ? const Value.absent()
          : Value(sentimentMagnitude),
      processingStatus: Value(processingStatus),
      createdAt: Value(createdAt),
      processedAt: processedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(processedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      isPendingUpload: Value(isPendingUpload),
      isPendingDelete: Value(isPendingDelete),
      isSynced: Value(isSynced),
      syncRetryCount: Value(syncRetryCount),
      lastSyncAttempt: lastSyncAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAttempt),
      localAudioPath: localAudioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localAudioPath),
      isAudioDownloaded: Value(isAudioDownloaded),
    );
  }

  factory Vibe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vibe(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      audioPath: serializer.fromJson<String>(json['audioPath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      duration: serializer.fromJson<int>(json['duration']),
      transcription: serializer.fromJson<String>(json['transcription']),
      mood: serializer.fromJson<String>(json['mood']),
      sentimentScore: serializer.fromJson<double?>(json['sentimentScore']),
      sentimentMagnitude: serializer.fromJson<double?>(
        json['sentimentMagnitude'],
      ),
      processingStatus: serializer.fromJson<String>(json['processingStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      processedAt: serializer.fromJson<DateTime?>(json['processedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      isPendingUpload: serializer.fromJson<bool>(json['isPendingUpload']),
      isPendingDelete: serializer.fromJson<bool>(json['isPendingDelete']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      syncRetryCount: serializer.fromJson<int>(json['syncRetryCount']),
      lastSyncAttempt: serializer.fromJson<DateTime?>(json['lastSyncAttempt']),
      localAudioPath: serializer.fromJson<String?>(json['localAudioPath']),
      isAudioDownloaded: serializer.fromJson<bool>(json['isAudioDownloaded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'audioPath': serializer.toJson<String>(audioPath),
      'fileName': serializer.toJson<String>(fileName),
      'duration': serializer.toJson<int>(duration),
      'transcription': serializer.toJson<String>(transcription),
      'mood': serializer.toJson<String>(mood),
      'sentimentScore': serializer.toJson<double?>(sentimentScore),
      'sentimentMagnitude': serializer.toJson<double?>(sentimentMagnitude),
      'processingStatus': serializer.toJson<String>(processingStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'processedAt': serializer.toJson<DateTime?>(processedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'isPendingUpload': serializer.toJson<bool>(isPendingUpload),
      'isPendingDelete': serializer.toJson<bool>(isPendingDelete),
      'isSynced': serializer.toJson<bool>(isSynced),
      'syncRetryCount': serializer.toJson<int>(syncRetryCount),
      'lastSyncAttempt': serializer.toJson<DateTime?>(lastSyncAttempt),
      'localAudioPath': serializer.toJson<String?>(localAudioPath),
      'isAudioDownloaded': serializer.toJson<bool>(isAudioDownloaded),
    };
  }

  Vibe copyWith({
    String? id,
    String? userId,
    String? audioPath,
    String? fileName,
    int? duration,
    String? transcription,
    String? mood,
    Value<double?> sentimentScore = const Value.absent(),
    Value<double?> sentimentMagnitude = const Value.absent(),
    String? processingStatus,
    DateTime? createdAt,
    Value<DateTime?> processedAt = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    bool? isPendingUpload,
    bool? isPendingDelete,
    bool? isSynced,
    int? syncRetryCount,
    Value<DateTime?> lastSyncAttempt = const Value.absent(),
    Value<String?> localAudioPath = const Value.absent(),
    bool? isAudioDownloaded,
  }) => Vibe(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    audioPath: audioPath ?? this.audioPath,
    fileName: fileName ?? this.fileName,
    duration: duration ?? this.duration,
    transcription: transcription ?? this.transcription,
    mood: mood ?? this.mood,
    sentimentScore: sentimentScore.present
        ? sentimentScore.value
        : this.sentimentScore,
    sentimentMagnitude: sentimentMagnitude.present
        ? sentimentMagnitude.value
        : this.sentimentMagnitude,
    processingStatus: processingStatus ?? this.processingStatus,
    createdAt: createdAt ?? this.createdAt,
    processedAt: processedAt.present ? processedAt.value : this.processedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    isPendingUpload: isPendingUpload ?? this.isPendingUpload,
    isPendingDelete: isPendingDelete ?? this.isPendingDelete,
    isSynced: isSynced ?? this.isSynced,
    syncRetryCount: syncRetryCount ?? this.syncRetryCount,
    lastSyncAttempt: lastSyncAttempt.present
        ? lastSyncAttempt.value
        : this.lastSyncAttempt,
    localAudioPath: localAudioPath.present
        ? localAudioPath.value
        : this.localAudioPath,
    isAudioDownloaded: isAudioDownloaded ?? this.isAudioDownloaded,
  );
  Vibe copyWithCompanion(VibesCompanion data) {
    return Vibe(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      duration: data.duration.present ? data.duration.value : this.duration,
      transcription: data.transcription.present
          ? data.transcription.value
          : this.transcription,
      mood: data.mood.present ? data.mood.value : this.mood,
      sentimentScore: data.sentimentScore.present
          ? data.sentimentScore.value
          : this.sentimentScore,
      sentimentMagnitude: data.sentimentMagnitude.present
          ? data.sentimentMagnitude.value
          : this.sentimentMagnitude,
      processingStatus: data.processingStatus.present
          ? data.processingStatus.value
          : this.processingStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      processedAt: data.processedAt.present
          ? data.processedAt.value
          : this.processedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      isPendingUpload: data.isPendingUpload.present
          ? data.isPendingUpload.value
          : this.isPendingUpload,
      isPendingDelete: data.isPendingDelete.present
          ? data.isPendingDelete.value
          : this.isPendingDelete,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      syncRetryCount: data.syncRetryCount.present
          ? data.syncRetryCount.value
          : this.syncRetryCount,
      lastSyncAttempt: data.lastSyncAttempt.present
          ? data.lastSyncAttempt.value
          : this.lastSyncAttempt,
      localAudioPath: data.localAudioPath.present
          ? data.localAudioPath.value
          : this.localAudioPath,
      isAudioDownloaded: data.isAudioDownloaded.present
          ? data.isAudioDownloaded.value
          : this.isAudioDownloaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vibe(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('audioPath: $audioPath, ')
          ..write('fileName: $fileName, ')
          ..write('duration: $duration, ')
          ..write('transcription: $transcription, ')
          ..write('mood: $mood, ')
          ..write('sentimentScore: $sentimentScore, ')
          ..write('sentimentMagnitude: $sentimentMagnitude, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('processedAt: $processedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingUpload: $isPendingUpload, ')
          ..write('isPendingDelete: $isPendingDelete, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncRetryCount: $syncRetryCount, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('localAudioPath: $localAudioPath, ')
          ..write('isAudioDownloaded: $isAudioDownloaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    audioPath,
    fileName,
    duration,
    transcription,
    mood,
    sentimentScore,
    sentimentMagnitude,
    processingStatus,
    createdAt,
    processedAt,
    lastSyncedAt,
    isPendingUpload,
    isPendingDelete,
    isSynced,
    syncRetryCount,
    lastSyncAttempt,
    localAudioPath,
    isAudioDownloaded,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vibe &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.audioPath == this.audioPath &&
          other.fileName == this.fileName &&
          other.duration == this.duration &&
          other.transcription == this.transcription &&
          other.mood == this.mood &&
          other.sentimentScore == this.sentimentScore &&
          other.sentimentMagnitude == this.sentimentMagnitude &&
          other.processingStatus == this.processingStatus &&
          other.createdAt == this.createdAt &&
          other.processedAt == this.processedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.isPendingUpload == this.isPendingUpload &&
          other.isPendingDelete == this.isPendingDelete &&
          other.isSynced == this.isSynced &&
          other.syncRetryCount == this.syncRetryCount &&
          other.lastSyncAttempt == this.lastSyncAttempt &&
          other.localAudioPath == this.localAudioPath &&
          other.isAudioDownloaded == this.isAudioDownloaded);
}

class VibesCompanion extends UpdateCompanion<Vibe> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> audioPath;
  final Value<String> fileName;
  final Value<int> duration;
  final Value<String> transcription;
  final Value<String> mood;
  final Value<double?> sentimentScore;
  final Value<double?> sentimentMagnitude;
  final Value<String> processingStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime?> processedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<bool> isPendingUpload;
  final Value<bool> isPendingDelete;
  final Value<bool> isSynced;
  final Value<int> syncRetryCount;
  final Value<DateTime?> lastSyncAttempt;
  final Value<String?> localAudioPath;
  final Value<bool> isAudioDownloaded;
  final Value<int> rowid;
  const VibesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.duration = const Value.absent(),
    this.transcription = const Value.absent(),
    this.mood = const Value.absent(),
    this.sentimentScore = const Value.absent(),
    this.sentimentMagnitude = const Value.absent(),
    this.processingStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingUpload = const Value.absent(),
    this.isPendingDelete = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncRetryCount = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.localAudioPath = const Value.absent(),
    this.isAudioDownloaded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VibesCompanion.insert({
    required String id,
    required String userId,
    required String audioPath,
    required String fileName,
    required int duration,
    this.transcription = const Value.absent(),
    this.mood = const Value.absent(),
    this.sentimentScore = const Value.absent(),
    this.sentimentMagnitude = const Value.absent(),
    this.processingStatus = const Value.absent(),
    required DateTime createdAt,
    this.processedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.isPendingUpload = const Value.absent(),
    this.isPendingDelete = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.syncRetryCount = const Value.absent(),
    this.lastSyncAttempt = const Value.absent(),
    this.localAudioPath = const Value.absent(),
    this.isAudioDownloaded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       audioPath = Value(audioPath),
       fileName = Value(fileName),
       duration = Value(duration),
       createdAt = Value(createdAt);
  static Insertable<Vibe> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? audioPath,
    Expression<String>? fileName,
    Expression<int>? duration,
    Expression<String>? transcription,
    Expression<String>? mood,
    Expression<double>? sentimentScore,
    Expression<double>? sentimentMagnitude,
    Expression<String>? processingStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? processedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<bool>? isPendingUpload,
    Expression<bool>? isPendingDelete,
    Expression<bool>? isSynced,
    Expression<int>? syncRetryCount,
    Expression<DateTime>? lastSyncAttempt,
    Expression<String>? localAudioPath,
    Expression<bool>? isAudioDownloaded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (audioPath != null) 'audio_path': audioPath,
      if (fileName != null) 'file_name': fileName,
      if (duration != null) 'duration': duration,
      if (transcription != null) 'transcription': transcription,
      if (mood != null) 'mood': mood,
      if (sentimentScore != null) 'sentiment_score': sentimentScore,
      if (sentimentMagnitude != null) 'sentiment_magnitude': sentimentMagnitude,
      if (processingStatus != null) 'processing_status': processingStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (processedAt != null) 'processed_at': processedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (isPendingUpload != null) 'is_pending_upload': isPendingUpload,
      if (isPendingDelete != null) 'is_pending_delete': isPendingDelete,
      if (isSynced != null) 'is_synced': isSynced,
      if (syncRetryCount != null) 'sync_retry_count': syncRetryCount,
      if (lastSyncAttempt != null) 'last_sync_attempt': lastSyncAttempt,
      if (localAudioPath != null) 'local_audio_path': localAudioPath,
      if (isAudioDownloaded != null) 'is_audio_downloaded': isAudioDownloaded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VibesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? audioPath,
    Value<String>? fileName,
    Value<int>? duration,
    Value<String>? transcription,
    Value<String>? mood,
    Value<double?>? sentimentScore,
    Value<double?>? sentimentMagnitude,
    Value<String>? processingStatus,
    Value<DateTime>? createdAt,
    Value<DateTime?>? processedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<bool>? isPendingUpload,
    Value<bool>? isPendingDelete,
    Value<bool>? isSynced,
    Value<int>? syncRetryCount,
    Value<DateTime?>? lastSyncAttempt,
    Value<String?>? localAudioPath,
    Value<bool>? isAudioDownloaded,
    Value<int>? rowid,
  }) {
    return VibesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      audioPath: audioPath ?? this.audioPath,
      fileName: fileName ?? this.fileName,
      duration: duration ?? this.duration,
      transcription: transcription ?? this.transcription,
      mood: mood ?? this.mood,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      sentimentMagnitude: sentimentMagnitude ?? this.sentimentMagnitude,
      processingStatus: processingStatus ?? this.processingStatus,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isPendingUpload: isPendingUpload ?? this.isPendingUpload,
      isPendingDelete: isPendingDelete ?? this.isPendingDelete,
      isSynced: isSynced ?? this.isSynced,
      syncRetryCount: syncRetryCount ?? this.syncRetryCount,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      isAudioDownloaded: isAudioDownloaded ?? this.isAudioDownloaded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (transcription.present) {
      map['transcription'] = Variable<String>(transcription.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (sentimentScore.present) {
      map['sentiment_score'] = Variable<double>(sentimentScore.value);
    }
    if (sentimentMagnitude.present) {
      map['sentiment_magnitude'] = Variable<double>(sentimentMagnitude.value);
    }
    if (processingStatus.present) {
      map['processing_status'] = Variable<String>(processingStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<DateTime>(processedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (isPendingUpload.present) {
      map['is_pending_upload'] = Variable<bool>(isPendingUpload.value);
    }
    if (isPendingDelete.present) {
      map['is_pending_delete'] = Variable<bool>(isPendingDelete.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (syncRetryCount.present) {
      map['sync_retry_count'] = Variable<int>(syncRetryCount.value);
    }
    if (lastSyncAttempt.present) {
      map['last_sync_attempt'] = Variable<DateTime>(lastSyncAttempt.value);
    }
    if (localAudioPath.present) {
      map['local_audio_path'] = Variable<String>(localAudioPath.value);
    }
    if (isAudioDownloaded.present) {
      map['is_audio_downloaded'] = Variable<bool>(isAudioDownloaded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VibesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('audioPath: $audioPath, ')
          ..write('fileName: $fileName, ')
          ..write('duration: $duration, ')
          ..write('transcription: $transcription, ')
          ..write('mood: $mood, ')
          ..write('sentimentScore: $sentimentScore, ')
          ..write('sentimentMagnitude: $sentimentMagnitude, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('processedAt: $processedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('isPendingUpload: $isPendingUpload, ')
          ..write('isPendingDelete: $isPendingDelete, ')
          ..write('isSynced: $isSynced, ')
          ..write('syncRetryCount: $syncRetryCount, ')
          ..write('lastSyncAttempt: $lastSyncAttempt, ')
          ..write('localAudioPath: $localAudioPath, ')
          ..write('isAudioDownloaded: $isAudioDownloaded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxRetriesMeta = const VerificationMeta(
    'maxRetries',
  );
  @override
  late final GeneratedColumn<int> maxRetries = GeneratedColumn<int>(
    'max_retries',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operation,
    entityType,
    entityId,
    data,
    retryCount,
    maxRetries,
    status,
    errorMessage,
    createdAt,
    lastAttemptAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('max_retries')) {
      context.handle(
        _maxRetriesMeta,
        maxRetries.isAcceptableOrUnknown(data['max_retries']!, _maxRetriesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      maxRetries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_retries'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String operation;
  final String entityType;
  final String entityId;
  final String data;
  final int retryCount;
  final int maxRetries;
  final String status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final DateTime? completedAt;
  const SyncQueueData({
    required this.id,
    required this.operation,
    required this.entityType,
    required this.entityId,
    required this.data,
    required this.retryCount,
    required this.maxRetries,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    this.lastAttemptAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation'] = Variable<String>(operation);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['data'] = Variable<String>(data);
    map['retry_count'] = Variable<int>(retryCount);
    map['max_retries'] = Variable<int>(maxRetries);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      operation: Value(operation),
      entityType: Value(entityType),
      entityId: Value(entityId),
      data: Value(data),
      retryCount: Value(retryCount),
      maxRetries: Value(maxRetries),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      operation: serializer.fromJson<String>(json['operation']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      data: serializer.fromJson<String>(json['data']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      maxRetries: serializer.fromJson<int>(json['maxRetries']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operation': serializer.toJson<String>(operation),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'data': serializer.toJson<String>(data),
      'retryCount': serializer.toJson<int>(retryCount),
      'maxRetries': serializer.toJson<int>(maxRetries),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  SyncQueueData copyWith({
    int? id,
    String? operation,
    String? entityType,
    String? entityId,
    String? data,
    int? retryCount,
    int? maxRetries,
    String? status,
    Value<String?> errorMessage = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
  }) => SyncQueueData(
    id: id ?? this.id,
    operation: operation ?? this.operation,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    data: data ?? this.data,
    retryCount: retryCount ?? this.retryCount,
    maxRetries: maxRetries ?? this.maxRetries,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      operation: data.operation.present ? data.operation.value : this.operation,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      data: data.data.present ? data.data.value : this.data,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      maxRetries: data.maxRetries.present
          ? data.maxRetries.value
          : this.maxRetries,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('data: $data, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operation,
    entityType,
    entityId,
    data,
    retryCount,
    maxRetries,
    status,
    errorMessage,
    createdAt,
    lastAttemptAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.operation == this.operation &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.data == this.data &&
          other.retryCount == this.retryCount &&
          other.maxRetries == this.maxRetries &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.completedAt == this.completedAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> operation;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> data;
  final Value<int> retryCount;
  final Value<int> maxRetries;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> completedAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.operation = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.data = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String operation,
    required String entityType,
    required String entityId,
    required String data,
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
    this.lastAttemptAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  }) : operation = Value(operation),
       entityType = Value(entityType),
       entityId = Value(entityId),
       data = Value(data),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? operation,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? data,
    Expression<int>? retryCount,
    Expression<int>? maxRetries,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operation != null) 'operation': operation,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (data != null) 'data': data,
      if (retryCount != null) 'retry_count': retryCount,
      if (maxRetries != null) 'max_retries': maxRetries,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? operation,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? data,
    Value<int>? retryCount,
    Value<int>? maxRetries,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? completedAt,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (maxRetries.present) {
      map['max_retries'] = Variable<int>(maxRetries.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('data: $data, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $VibesTable vibes = $VibesTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [users, vibes, syncQueue];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String uid,
      Value<String?> email,
      Value<String?> fullName,
      Value<String?> photoUrl,
      Value<String> plan,
      Value<int> cloudVibeCount,
      Value<int> maxCloudVibes,
      Value<int> maxRecordingDurationMinutes,
      Value<String?> subscriptionType,
      Value<String> subscriptionStatus,
      Value<String> notificationPreferences,
      required DateTime createdAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> uid,
      Value<String?> email,
      Value<String?> fullName,
      Value<String?> photoUrl,
      Value<String> plan,
      Value<int> cloudVibeCount,
      Value<int> maxCloudVibes,
      Value<int> maxRecordingDurationMinutes,
      Value<String?> subscriptionType,
      Value<String> subscriptionStatus,
      Value<String> notificationPreferences,
      Value<DateTime> createdAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cloudVibeCount => $composableBuilder(
    column: $table.cloudVibeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxCloudVibes => $composableBuilder(
    column: $table.maxCloudVibes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxRecordingDurationMinutes => $composableBuilder(
    column: $table.maxRecordingDurationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subscriptionType => $composableBuilder(
    column: $table.subscriptionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subscriptionStatus => $composableBuilder(
    column: $table.subscriptionStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notificationPreferences => $composableBuilder(
    column: $table.notificationPreferences,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cloudVibeCount => $composableBuilder(
    column: $table.cloudVibeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxCloudVibes => $composableBuilder(
    column: $table.maxCloudVibes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxRecordingDurationMinutes => $composableBuilder(
    column: $table.maxRecordingDurationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subscriptionType => $composableBuilder(
    column: $table.subscriptionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subscriptionStatus => $composableBuilder(
    column: $table.subscriptionStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notificationPreferences => $composableBuilder(
    column: $table.notificationPreferences,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => column);

  GeneratedColumn<int> get cloudVibeCount => $composableBuilder(
    column: $table.cloudVibeCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxCloudVibes => $composableBuilder(
    column: $table.maxCloudVibes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxRecordingDurationMinutes => $composableBuilder(
    column: $table.maxRecordingDurationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subscriptionType => $composableBuilder(
    column: $table.subscriptionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subscriptionStatus => $composableBuilder(
    column: $table.subscriptionStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notificationPreferences => $composableBuilder(
    column: $table.notificationPreferences,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<int> cloudVibeCount = const Value.absent(),
                Value<int> maxCloudVibes = const Value.absent(),
                Value<int> maxRecordingDurationMinutes = const Value.absent(),
                Value<String?> subscriptionType = const Value.absent(),
                Value<String> subscriptionStatus = const Value.absent(),
                Value<String> notificationPreferences = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                uid: uid,
                email: email,
                fullName: fullName,
                photoUrl: photoUrl,
                plan: plan,
                cloudVibeCount: cloudVibeCount,
                maxCloudVibes: maxCloudVibes,
                maxRecordingDurationMinutes: maxRecordingDurationMinutes,
                subscriptionType: subscriptionType,
                subscriptionStatus: subscriptionStatus,
                notificationPreferences: notificationPreferences,
                createdAt: createdAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                Value<String?> email = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<int> cloudVibeCount = const Value.absent(),
                Value<int> maxCloudVibes = const Value.absent(),
                Value<int> maxRecordingDurationMinutes = const Value.absent(),
                Value<String?> subscriptionType = const Value.absent(),
                Value<String> subscriptionStatus = const Value.absent(),
                Value<String> notificationPreferences = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                uid: uid,
                email: email,
                fullName: fullName,
                photoUrl: photoUrl,
                plan: plan,
                cloudVibeCount: cloudVibeCount,
                maxCloudVibes: maxCloudVibes,
                maxRecordingDurationMinutes: maxRecordingDurationMinutes,
                subscriptionType: subscriptionType,
                subscriptionStatus: subscriptionStatus,
                notificationPreferences: notificationPreferences,
                createdAt: createdAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$VibesTableCreateCompanionBuilder =
    VibesCompanion Function({
      required String id,
      required String userId,
      required String audioPath,
      required String fileName,
      required int duration,
      Value<String> transcription,
      Value<String> mood,
      Value<double?> sentimentScore,
      Value<double?> sentimentMagnitude,
      Value<String> processingStatus,
      required DateTime createdAt,
      Value<DateTime?> processedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingUpload,
      Value<bool> isPendingDelete,
      Value<bool> isSynced,
      Value<int> syncRetryCount,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> localAudioPath,
      Value<bool> isAudioDownloaded,
      Value<int> rowid,
    });
typedef $$VibesTableUpdateCompanionBuilder =
    VibesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> audioPath,
      Value<String> fileName,
      Value<int> duration,
      Value<String> transcription,
      Value<String> mood,
      Value<double?> sentimentScore,
      Value<double?> sentimentMagnitude,
      Value<String> processingStatus,
      Value<DateTime> createdAt,
      Value<DateTime?> processedAt,
      Value<DateTime?> lastSyncedAt,
      Value<bool> isPendingUpload,
      Value<bool> isPendingDelete,
      Value<bool> isSynced,
      Value<int> syncRetryCount,
      Value<DateTime?> lastSyncAttempt,
      Value<String?> localAudioPath,
      Value<bool> isAudioDownloaded,
      Value<int> rowid,
    });

class $$VibesTableFilterComposer extends Composer<_$AppDatabase, $VibesTable> {
  $$VibesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sentimentScore => $composableBuilder(
    column: $table.sentimentScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sentimentMagnitude => $composableBuilder(
    column: $table.sentimentMagnitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingUpload => $composableBuilder(
    column: $table.isPendingUpload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPendingDelete => $composableBuilder(
    column: $table.isPendingDelete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncRetryCount => $composableBuilder(
    column: $table.syncRetryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localAudioPath => $composableBuilder(
    column: $table.localAudioPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAudioDownloaded => $composableBuilder(
    column: $table.isAudioDownloaded,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VibesTableOrderingComposer
    extends Composer<_$AppDatabase, $VibesTable> {
  $$VibesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioPath => $composableBuilder(
    column: $table.audioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sentimentScore => $composableBuilder(
    column: $table.sentimentScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sentimentMagnitude => $composableBuilder(
    column: $table.sentimentMagnitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingUpload => $composableBuilder(
    column: $table.isPendingUpload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPendingDelete => $composableBuilder(
    column: $table.isPendingDelete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncRetryCount => $composableBuilder(
    column: $table.syncRetryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localAudioPath => $composableBuilder(
    column: $table.localAudioPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAudioDownloaded => $composableBuilder(
    column: $table.isAudioDownloaded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VibesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VibesTable> {
  $$VibesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<double> get sentimentScore => $composableBuilder(
    column: $table.sentimentScore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sentimentMagnitude => $composableBuilder(
    column: $table.sentimentMagnitude,
    builder: (column) => column,
  );

  GeneratedColumn<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPendingUpload => $composableBuilder(
    column: $table.isPendingUpload,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPendingDelete => $composableBuilder(
    column: $table.isPendingDelete,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<int> get syncRetryCount => $composableBuilder(
    column: $table.syncRetryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAttempt => $composableBuilder(
    column: $table.lastSyncAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localAudioPath => $composableBuilder(
    column: $table.localAudioPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAudioDownloaded => $composableBuilder(
    column: $table.isAudioDownloaded,
    builder: (column) => column,
  );
}

class $$VibesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VibesTable,
          Vibe,
          $$VibesTableFilterComposer,
          $$VibesTableOrderingComposer,
          $$VibesTableAnnotationComposer,
          $$VibesTableCreateCompanionBuilder,
          $$VibesTableUpdateCompanionBuilder,
          (Vibe, BaseReferences<_$AppDatabase, $VibesTable, Vibe>),
          Vibe,
          PrefetchHooks Function()
        > {
  $$VibesTableTableManager(_$AppDatabase db, $VibesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VibesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VibesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VibesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> audioPath = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String> transcription = const Value.absent(),
                Value<String> mood = const Value.absent(),
                Value<double?> sentimentScore = const Value.absent(),
                Value<double?> sentimentMagnitude = const Value.absent(),
                Value<String> processingStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> processedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingUpload = const Value.absent(),
                Value<bool> isPendingDelete = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> syncRetryCount = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> localAudioPath = const Value.absent(),
                Value<bool> isAudioDownloaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VibesCompanion(
                id: id,
                userId: userId,
                audioPath: audioPath,
                fileName: fileName,
                duration: duration,
                transcription: transcription,
                mood: mood,
                sentimentScore: sentimentScore,
                sentimentMagnitude: sentimentMagnitude,
                processingStatus: processingStatus,
                createdAt: createdAt,
                processedAt: processedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingUpload: isPendingUpload,
                isPendingDelete: isPendingDelete,
                isSynced: isSynced,
                syncRetryCount: syncRetryCount,
                lastSyncAttempt: lastSyncAttempt,
                localAudioPath: localAudioPath,
                isAudioDownloaded: isAudioDownloaded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String audioPath,
                required String fileName,
                required int duration,
                Value<String> transcription = const Value.absent(),
                Value<String> mood = const Value.absent(),
                Value<double?> sentimentScore = const Value.absent(),
                Value<double?> sentimentMagnitude = const Value.absent(),
                Value<String> processingStatus = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> processedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> isPendingUpload = const Value.absent(),
                Value<bool> isPendingDelete = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> syncRetryCount = const Value.absent(),
                Value<DateTime?> lastSyncAttempt = const Value.absent(),
                Value<String?> localAudioPath = const Value.absent(),
                Value<bool> isAudioDownloaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VibesCompanion.insert(
                id: id,
                userId: userId,
                audioPath: audioPath,
                fileName: fileName,
                duration: duration,
                transcription: transcription,
                mood: mood,
                sentimentScore: sentimentScore,
                sentimentMagnitude: sentimentMagnitude,
                processingStatus: processingStatus,
                createdAt: createdAt,
                processedAt: processedAt,
                lastSyncedAt: lastSyncedAt,
                isPendingUpload: isPendingUpload,
                isPendingDelete: isPendingDelete,
                isSynced: isSynced,
                syncRetryCount: syncRetryCount,
                lastSyncAttempt: lastSyncAttempt,
                localAudioPath: localAudioPath,
                isAudioDownloaded: isAudioDownloaded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VibesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VibesTable,
      Vibe,
      $$VibesTableFilterComposer,
      $$VibesTableOrderingComposer,
      $$VibesTableAnnotationComposer,
      $$VibesTableCreateCompanionBuilder,
      $$VibesTableUpdateCompanionBuilder,
      (Vibe, BaseReferences<_$AppDatabase, $VibesTable, Vibe>),
      Vibe,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String operation,
      required String entityType,
      required String entityId,
      required String data,
      Value<int> retryCount,
      Value<int> maxRetries,
      Value<String> status,
      Value<String?> errorMessage,
      required DateTime createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> completedAt,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> operation,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> data,
      Value<int> retryCount,
      Value<int> maxRetries,
      Value<String> status,
      Value<String?> errorMessage,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> completedAt,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxRetries => $composableBuilder(
    column: $table.maxRetries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxRetries => $composableBuilder(
    column: $table.maxRetries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxRetries => $composableBuilder(
    column: $table.maxRetries,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> maxRetries = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                operation: operation,
                entityType: entityType,
                entityId: entityId,
                data: data,
                retryCount: retryCount,
                maxRetries: maxRetries,
                status: status,
                errorMessage: errorMessage,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String operation,
                required String entityType,
                required String entityId,
                required String data,
                Value<int> retryCount = const Value.absent(),
                Value<int> maxRetries = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                operation: operation,
                entityType: entityType,
                entityId: entityId,
                data: data,
                retryCount: retryCount,
                maxRetries: maxRetries,
                status: status,
                errorMessage: errorMessage,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$VibesTableTableManager get vibes =>
      $$VibesTableTableManager(_db, _db.vibes);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
