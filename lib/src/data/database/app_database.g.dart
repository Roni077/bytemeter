// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DataPlansTableTable extends DataPlansTable
    with TableInfo<$DataPlansTableTable, DataPlanEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DataPlansTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hashedSubscriberIdMeta =
      const VerificationMeta('hashedSubscriberId');
  @override
  late final GeneratedColumn<String> hashedSubscriberId =
      GeneratedColumn<String>(
        'hashed_subscriber_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _encryptedSubscriberIdMeta =
      const VerificationMeta('encryptedSubscriberId');
  @override
  late final GeneratedColumn<String> encryptedSubscriberId =
      GeneratedColumn<String>(
        'encrypted_subscriber_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _simSlotIndexMeta = const VerificationMeta(
    'simSlotIndex',
  );
  @override
  late final GeneratedColumn<int> simSlotIndex = GeneratedColumn<int>(
    'sim_slot_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _carrierNameMeta = const VerificationMeta(
    'carrierName',
  );
  @override
  late final GeneratedColumn<String> carrierName = GeneratedColumn<String>(
    'carrier_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _quotaBytesMeta = const VerificationMeta(
    'quotaBytes',
  );
  @override
  late final GeneratedColumn<int> quotaBytes = GeneratedColumn<int>(
    'quota_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _billingCycleStartDayMeta =
      const VerificationMeta('billingCycleStartDay');
  @override
  late final GeneratedColumn<int> billingCycleStartDay = GeneratedColumn<int>(
    'billing_cycle_start_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TimeIntervalType, String>
  cycleInterval =
      GeneratedColumn<String>(
        'cycle_interval',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('monthly'),
      ).withConverter<TimeIntervalType>(
        $DataPlansTableTable.$convertercycleInterval,
      );
  static const VerificationMeta _customIntervalDaysMeta =
      const VerificationMeta('customIntervalDays');
  @override
  late final GeneratedColumn<int> customIntervalDays = GeneratedColumn<int>(
    'custom_interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _rolloverEnabledMeta = const VerificationMeta(
    'rolloverEnabled',
  );
  @override
  late final GeneratedColumn<bool> rolloverEnabled = GeneratedColumn<bool>(
    'rollover_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rollover_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<int>, String> excludedUids =
      GeneratedColumn<String>(
        'excluded_uids',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<int>>($DataPlansTableTable.$converterexcludedUids);
  static const VerificationMeta _cardColorIndexMeta = const VerificationMeta(
    'cardColorIndex',
  );
  @override
  late final GeneratedColumn<int> cardColorIndex = GeneratedColumn<int>(
    'card_color_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _customNoteMeta = const VerificationMeta(
    'customNote',
  );
  @override
  late final GeneratedColumn<String> customNote = GeneratedColumn<String>(
    'custom_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    hashedSubscriberId,
    encryptedSubscriberId,
    simSlotIndex,
    carrierName,
    quotaBytes,
    billingCycleStartDay,
    cycleInterval,
    customIntervalDays,
    rolloverEnabled,
    excludedUids,
    cardColorIndex,
    customNote,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'data_plans_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<DataPlanEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hashed_subscriber_id')) {
      context.handle(
        _hashedSubscriberIdMeta,
        hashedSubscriberId.isAcceptableOrUnknown(
          data['hashed_subscriber_id']!,
          _hashedSubscriberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hashedSubscriberIdMeta);
    }
    if (data.containsKey('encrypted_subscriber_id')) {
      context.handle(
        _encryptedSubscriberIdMeta,
        encryptedSubscriberId.isAcceptableOrUnknown(
          data['encrypted_subscriber_id']!,
          _encryptedSubscriberIdMeta,
        ),
      );
    }
    if (data.containsKey('sim_slot_index')) {
      context.handle(
        _simSlotIndexMeta,
        simSlotIndex.isAcceptableOrUnknown(
          data['sim_slot_index']!,
          _simSlotIndexMeta,
        ),
      );
    }
    if (data.containsKey('carrier_name')) {
      context.handle(
        _carrierNameMeta,
        carrierName.isAcceptableOrUnknown(
          data['carrier_name']!,
          _carrierNameMeta,
        ),
      );
    }
    if (data.containsKey('quota_bytes')) {
      context.handle(
        _quotaBytesMeta,
        quotaBytes.isAcceptableOrUnknown(data['quota_bytes']!, _quotaBytesMeta),
      );
    }
    if (data.containsKey('billing_cycle_start_day')) {
      context.handle(
        _billingCycleStartDayMeta,
        billingCycleStartDay.isAcceptableOrUnknown(
          data['billing_cycle_start_day']!,
          _billingCycleStartDayMeta,
        ),
      );
    }
    if (data.containsKey('custom_interval_days')) {
      context.handle(
        _customIntervalDaysMeta,
        customIntervalDays.isAcceptableOrUnknown(
          data['custom_interval_days']!,
          _customIntervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('rollover_enabled')) {
      context.handle(
        _rolloverEnabledMeta,
        rolloverEnabled.isAcceptableOrUnknown(
          data['rollover_enabled']!,
          _rolloverEnabledMeta,
        ),
      );
    }
    if (data.containsKey('card_color_index')) {
      context.handle(
        _cardColorIndexMeta,
        cardColorIndex.isAcceptableOrUnknown(
          data['card_color_index']!,
          _cardColorIndexMeta,
        ),
      );
    }
    if (data.containsKey('custom_note')) {
      context.handle(
        _customNoteMeta,
        customNote.isAcceptableOrUnknown(data['custom_note']!, _customNoteMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hashedSubscriberId};
  @override
  DataPlanEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DataPlanEntity(
      hashedSubscriberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hashed_subscriber_id'],
      )!,
      encryptedSubscriberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_subscriber_id'],
      ),
      simSlotIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sim_slot_index'],
      )!,
      carrierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}carrier_name'],
      )!,
      quotaBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quota_bytes'],
      )!,
      billingCycleStartDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}billing_cycle_start_day'],
      )!,
      cycleInterval: $DataPlansTableTable.$convertercycleInterval.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cycle_interval'],
        )!,
      ),
      customIntervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}custom_interval_days'],
      )!,
      rolloverEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rollover_enabled'],
      )!,
      excludedUids: $DataPlansTableTable.$converterexcludedUids.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}excluded_uids'],
        )!,
      ),
      cardColorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_color_index'],
      )!,
      customNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DataPlansTableTable createAlias(String alias) {
    return $DataPlansTableTable(attachedDatabase, alias);
  }

  static TypeConverter<TimeIntervalType, String> $convertercycleInterval =
      const TimeIntervalTypeConverter();
  static TypeConverter<List<int>, String> $converterexcludedUids =
      const IntListConverter();
}

class DataPlanEntity extends DataClass implements Insertable<DataPlanEntity> {
  final String hashedSubscriberId;
  final String? encryptedSubscriberId;
  final int simSlotIndex;
  final String carrierName;
  final int quotaBytes;
  final int billingCycleStartDay;
  final TimeIntervalType cycleInterval;
  final int customIntervalDays;
  final bool rolloverEnabled;
  final List<int> excludedUids;
  final int cardColorIndex;
  final String customNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DataPlanEntity({
    required this.hashedSubscriberId,
    this.encryptedSubscriberId,
    required this.simSlotIndex,
    required this.carrierName,
    required this.quotaBytes,
    required this.billingCycleStartDay,
    required this.cycleInterval,
    required this.customIntervalDays,
    required this.rolloverEnabled,
    required this.excludedUids,
    required this.cardColorIndex,
    required this.customNote,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hashed_subscriber_id'] = Variable<String>(hashedSubscriberId);
    if (!nullToAbsent || encryptedSubscriberId != null) {
      map['encrypted_subscriber_id'] = Variable<String>(encryptedSubscriberId);
    }
    map['sim_slot_index'] = Variable<int>(simSlotIndex);
    map['carrier_name'] = Variable<String>(carrierName);
    map['quota_bytes'] = Variable<int>(quotaBytes);
    map['billing_cycle_start_day'] = Variable<int>(billingCycleStartDay);
    {
      map['cycle_interval'] = Variable<String>(
        $DataPlansTableTable.$convertercycleInterval.toSql(cycleInterval),
      );
    }
    map['custom_interval_days'] = Variable<int>(customIntervalDays);
    map['rollover_enabled'] = Variable<bool>(rolloverEnabled);
    {
      map['excluded_uids'] = Variable<String>(
        $DataPlansTableTable.$converterexcludedUids.toSql(excludedUids),
      );
    }
    map['card_color_index'] = Variable<int>(cardColorIndex);
    map['custom_note'] = Variable<String>(customNote);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DataPlansTableCompanion toCompanion(bool nullToAbsent) {
    return DataPlansTableCompanion(
      hashedSubscriberId: Value(hashedSubscriberId),
      encryptedSubscriberId: encryptedSubscriberId == null && nullToAbsent
          ? const Value.absent()
          : Value(encryptedSubscriberId),
      simSlotIndex: Value(simSlotIndex),
      carrierName: Value(carrierName),
      quotaBytes: Value(quotaBytes),
      billingCycleStartDay: Value(billingCycleStartDay),
      cycleInterval: Value(cycleInterval),
      customIntervalDays: Value(customIntervalDays),
      rolloverEnabled: Value(rolloverEnabled),
      excludedUids: Value(excludedUids),
      cardColorIndex: Value(cardColorIndex),
      customNote: Value(customNote),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DataPlanEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DataPlanEntity(
      hashedSubscriberId: serializer.fromJson<String>(
        json['hashedSubscriberId'],
      ),
      encryptedSubscriberId: serializer.fromJson<String?>(
        json['encryptedSubscriberId'],
      ),
      simSlotIndex: serializer.fromJson<int>(json['simSlotIndex']),
      carrierName: serializer.fromJson<String>(json['carrierName']),
      quotaBytes: serializer.fromJson<int>(json['quotaBytes']),
      billingCycleStartDay: serializer.fromJson<int>(
        json['billingCycleStartDay'],
      ),
      cycleInterval: serializer.fromJson<TimeIntervalType>(
        json['cycleInterval'],
      ),
      customIntervalDays: serializer.fromJson<int>(json['customIntervalDays']),
      rolloverEnabled: serializer.fromJson<bool>(json['rolloverEnabled']),
      excludedUids: serializer.fromJson<List<int>>(json['excludedUids']),
      cardColorIndex: serializer.fromJson<int>(json['cardColorIndex']),
      customNote: serializer.fromJson<String>(json['customNote']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hashedSubscriberId': serializer.toJson<String>(hashedSubscriberId),
      'encryptedSubscriberId': serializer.toJson<String?>(
        encryptedSubscriberId,
      ),
      'simSlotIndex': serializer.toJson<int>(simSlotIndex),
      'carrierName': serializer.toJson<String>(carrierName),
      'quotaBytes': serializer.toJson<int>(quotaBytes),
      'billingCycleStartDay': serializer.toJson<int>(billingCycleStartDay),
      'cycleInterval': serializer.toJson<TimeIntervalType>(cycleInterval),
      'customIntervalDays': serializer.toJson<int>(customIntervalDays),
      'rolloverEnabled': serializer.toJson<bool>(rolloverEnabled),
      'excludedUids': serializer.toJson<List<int>>(excludedUids),
      'cardColorIndex': serializer.toJson<int>(cardColorIndex),
      'customNote': serializer.toJson<String>(customNote),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DataPlanEntity copyWith({
    String? hashedSubscriberId,
    Value<String?> encryptedSubscriberId = const Value.absent(),
    int? simSlotIndex,
    String? carrierName,
    int? quotaBytes,
    int? billingCycleStartDay,
    TimeIntervalType? cycleInterval,
    int? customIntervalDays,
    bool? rolloverEnabled,
    List<int>? excludedUids,
    int? cardColorIndex,
    String? customNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DataPlanEntity(
    hashedSubscriberId: hashedSubscriberId ?? this.hashedSubscriberId,
    encryptedSubscriberId: encryptedSubscriberId.present
        ? encryptedSubscriberId.value
        : this.encryptedSubscriberId,
    simSlotIndex: simSlotIndex ?? this.simSlotIndex,
    carrierName: carrierName ?? this.carrierName,
    quotaBytes: quotaBytes ?? this.quotaBytes,
    billingCycleStartDay: billingCycleStartDay ?? this.billingCycleStartDay,
    cycleInterval: cycleInterval ?? this.cycleInterval,
    customIntervalDays: customIntervalDays ?? this.customIntervalDays,
    rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
    excludedUids: excludedUids ?? this.excludedUids,
    cardColorIndex: cardColorIndex ?? this.cardColorIndex,
    customNote: customNote ?? this.customNote,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DataPlanEntity copyWithCompanion(DataPlansTableCompanion data) {
    return DataPlanEntity(
      hashedSubscriberId: data.hashedSubscriberId.present
          ? data.hashedSubscriberId.value
          : this.hashedSubscriberId,
      encryptedSubscriberId: data.encryptedSubscriberId.present
          ? data.encryptedSubscriberId.value
          : this.encryptedSubscriberId,
      simSlotIndex: data.simSlotIndex.present
          ? data.simSlotIndex.value
          : this.simSlotIndex,
      carrierName: data.carrierName.present
          ? data.carrierName.value
          : this.carrierName,
      quotaBytes: data.quotaBytes.present
          ? data.quotaBytes.value
          : this.quotaBytes,
      billingCycleStartDay: data.billingCycleStartDay.present
          ? data.billingCycleStartDay.value
          : this.billingCycleStartDay,
      cycleInterval: data.cycleInterval.present
          ? data.cycleInterval.value
          : this.cycleInterval,
      customIntervalDays: data.customIntervalDays.present
          ? data.customIntervalDays.value
          : this.customIntervalDays,
      rolloverEnabled: data.rolloverEnabled.present
          ? data.rolloverEnabled.value
          : this.rolloverEnabled,
      excludedUids: data.excludedUids.present
          ? data.excludedUids.value
          : this.excludedUids,
      cardColorIndex: data.cardColorIndex.present
          ? data.cardColorIndex.value
          : this.cardColorIndex,
      customNote: data.customNote.present
          ? data.customNote.value
          : this.customNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DataPlanEntity(')
          ..write('hashedSubscriberId: $hashedSubscriberId, ')
          ..write('encryptedSubscriberId: $encryptedSubscriberId, ')
          ..write('simSlotIndex: $simSlotIndex, ')
          ..write('carrierName: $carrierName, ')
          ..write('quotaBytes: $quotaBytes, ')
          ..write('billingCycleStartDay: $billingCycleStartDay, ')
          ..write('cycleInterval: $cycleInterval, ')
          ..write('customIntervalDays: $customIntervalDays, ')
          ..write('rolloverEnabled: $rolloverEnabled, ')
          ..write('excludedUids: $excludedUids, ')
          ..write('cardColorIndex: $cardColorIndex, ')
          ..write('customNote: $customNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    hashedSubscriberId,
    encryptedSubscriberId,
    simSlotIndex,
    carrierName,
    quotaBytes,
    billingCycleStartDay,
    cycleInterval,
    customIntervalDays,
    rolloverEnabled,
    excludedUids,
    cardColorIndex,
    customNote,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DataPlanEntity &&
          other.hashedSubscriberId == this.hashedSubscriberId &&
          other.encryptedSubscriberId == this.encryptedSubscriberId &&
          other.simSlotIndex == this.simSlotIndex &&
          other.carrierName == this.carrierName &&
          other.quotaBytes == this.quotaBytes &&
          other.billingCycleStartDay == this.billingCycleStartDay &&
          other.cycleInterval == this.cycleInterval &&
          other.customIntervalDays == this.customIntervalDays &&
          other.rolloverEnabled == this.rolloverEnabled &&
          other.excludedUids == this.excludedUids &&
          other.cardColorIndex == this.cardColorIndex &&
          other.customNote == this.customNote &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DataPlansTableCompanion extends UpdateCompanion<DataPlanEntity> {
  final Value<String> hashedSubscriberId;
  final Value<String?> encryptedSubscriberId;
  final Value<int> simSlotIndex;
  final Value<String> carrierName;
  final Value<int> quotaBytes;
  final Value<int> billingCycleStartDay;
  final Value<TimeIntervalType> cycleInterval;
  final Value<int> customIntervalDays;
  final Value<bool> rolloverEnabled;
  final Value<List<int>> excludedUids;
  final Value<int> cardColorIndex;
  final Value<String> customNote;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DataPlansTableCompanion({
    this.hashedSubscriberId = const Value.absent(),
    this.encryptedSubscriberId = const Value.absent(),
    this.simSlotIndex = const Value.absent(),
    this.carrierName = const Value.absent(),
    this.quotaBytes = const Value.absent(),
    this.billingCycleStartDay = const Value.absent(),
    this.cycleInterval = const Value.absent(),
    this.customIntervalDays = const Value.absent(),
    this.rolloverEnabled = const Value.absent(),
    this.excludedUids = const Value.absent(),
    this.cardColorIndex = const Value.absent(),
    this.customNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DataPlansTableCompanion.insert({
    required String hashedSubscriberId,
    this.encryptedSubscriberId = const Value.absent(),
    this.simSlotIndex = const Value.absent(),
    this.carrierName = const Value.absent(),
    this.quotaBytes = const Value.absent(),
    this.billingCycleStartDay = const Value.absent(),
    this.cycleInterval = const Value.absent(),
    this.customIntervalDays = const Value.absent(),
    this.rolloverEnabled = const Value.absent(),
    this.excludedUids = const Value.absent(),
    this.cardColorIndex = const Value.absent(),
    this.customNote = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : hashedSubscriberId = Value(hashedSubscriberId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DataPlanEntity> custom({
    Expression<String>? hashedSubscriberId,
    Expression<String>? encryptedSubscriberId,
    Expression<int>? simSlotIndex,
    Expression<String>? carrierName,
    Expression<int>? quotaBytes,
    Expression<int>? billingCycleStartDay,
    Expression<String>? cycleInterval,
    Expression<int>? customIntervalDays,
    Expression<bool>? rolloverEnabled,
    Expression<String>? excludedUids,
    Expression<int>? cardColorIndex,
    Expression<String>? customNote,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (hashedSubscriberId != null)
        'hashed_subscriber_id': hashedSubscriberId,
      if (encryptedSubscriberId != null)
        'encrypted_subscriber_id': encryptedSubscriberId,
      if (simSlotIndex != null) 'sim_slot_index': simSlotIndex,
      if (carrierName != null) 'carrier_name': carrierName,
      if (quotaBytes != null) 'quota_bytes': quotaBytes,
      if (billingCycleStartDay != null)
        'billing_cycle_start_day': billingCycleStartDay,
      if (cycleInterval != null) 'cycle_interval': cycleInterval,
      if (customIntervalDays != null)
        'custom_interval_days': customIntervalDays,
      if (rolloverEnabled != null) 'rollover_enabled': rolloverEnabled,
      if (excludedUids != null) 'excluded_uids': excludedUids,
      if (cardColorIndex != null) 'card_color_index': cardColorIndex,
      if (customNote != null) 'custom_note': customNote,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DataPlansTableCompanion copyWith({
    Value<String>? hashedSubscriberId,
    Value<String?>? encryptedSubscriberId,
    Value<int>? simSlotIndex,
    Value<String>? carrierName,
    Value<int>? quotaBytes,
    Value<int>? billingCycleStartDay,
    Value<TimeIntervalType>? cycleInterval,
    Value<int>? customIntervalDays,
    Value<bool>? rolloverEnabled,
    Value<List<int>>? excludedUids,
    Value<int>? cardColorIndex,
    Value<String>? customNote,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DataPlansTableCompanion(
      hashedSubscriberId: hashedSubscriberId ?? this.hashedSubscriberId,
      encryptedSubscriberId:
          encryptedSubscriberId ?? this.encryptedSubscriberId,
      simSlotIndex: simSlotIndex ?? this.simSlotIndex,
      carrierName: carrierName ?? this.carrierName,
      quotaBytes: quotaBytes ?? this.quotaBytes,
      billingCycleStartDay: billingCycleStartDay ?? this.billingCycleStartDay,
      cycleInterval: cycleInterval ?? this.cycleInterval,
      customIntervalDays: customIntervalDays ?? this.customIntervalDays,
      rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
      excludedUids: excludedUids ?? this.excludedUids,
      cardColorIndex: cardColorIndex ?? this.cardColorIndex,
      customNote: customNote ?? this.customNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hashedSubscriberId.present) {
      map['hashed_subscriber_id'] = Variable<String>(hashedSubscriberId.value);
    }
    if (encryptedSubscriberId.present) {
      map['encrypted_subscriber_id'] = Variable<String>(
        encryptedSubscriberId.value,
      );
    }
    if (simSlotIndex.present) {
      map['sim_slot_index'] = Variable<int>(simSlotIndex.value);
    }
    if (carrierName.present) {
      map['carrier_name'] = Variable<String>(carrierName.value);
    }
    if (quotaBytes.present) {
      map['quota_bytes'] = Variable<int>(quotaBytes.value);
    }
    if (billingCycleStartDay.present) {
      map['billing_cycle_start_day'] = Variable<int>(
        billingCycleStartDay.value,
      );
    }
    if (cycleInterval.present) {
      map['cycle_interval'] = Variable<String>(
        $DataPlansTableTable.$convertercycleInterval.toSql(cycleInterval.value),
      );
    }
    if (customIntervalDays.present) {
      map['custom_interval_days'] = Variable<int>(customIntervalDays.value);
    }
    if (rolloverEnabled.present) {
      map['rollover_enabled'] = Variable<bool>(rolloverEnabled.value);
    }
    if (excludedUids.present) {
      map['excluded_uids'] = Variable<String>(
        $DataPlansTableTable.$converterexcludedUids.toSql(excludedUids.value),
      );
    }
    if (cardColorIndex.present) {
      map['card_color_index'] = Variable<int>(cardColorIndex.value);
    }
    if (customNote.present) {
      map['custom_note'] = Variable<String>(customNote.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DataPlansTableCompanion(')
          ..write('hashedSubscriberId: $hashedSubscriberId, ')
          ..write('encryptedSubscriberId: $encryptedSubscriberId, ')
          ..write('simSlotIndex: $simSlotIndex, ')
          ..write('carrierName: $carrierName, ')
          ..write('quotaBytes: $quotaBytes, ')
          ..write('billingCycleStartDay: $billingCycleStartDay, ')
          ..write('cycleInterval: $cycleInterval, ')
          ..write('customIntervalDays: $customIntervalDays, ')
          ..write('rolloverEnabled: $rolloverEnabled, ')
          ..write('excludedUids: $excludedUids, ')
          ..write('cardColorIndex: $cardColorIndex, ')
          ..write('customNote: $customNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExtraPacksTableTable extends ExtraPacksTable
    with TableInfo<$ExtraPacksTableTable, ExtraPackEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtraPacksTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _planHashedSubscriberIdMeta =
      const VerificationMeta('planHashedSubscriberId');
  @override
  late final GeneratedColumn<String>
  planHashedSubscriberId = GeneratedColumn<String>(
    'plan_hashed_subscriber_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES data_plans_table (hashed_subscriber_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _extraBytesMeta = const VerificationMeta(
    'extraBytes',
  );
  @override
  late final GeneratedColumn<int> extraBytes = GeneratedColumn<int>(
    'extra_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedBytesMeta = const VerificationMeta(
    'usedBytes',
  );
  @override
  late final GeneratedColumn<int> usedBytes = GeneratedColumn<int>(
    'used_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
    'expiry_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isExpiredMeta = const VerificationMeta(
    'isExpired',
  );
  @override
  late final GeneratedColumn<bool> isExpired = GeneratedColumn<bool>(
    'is_expired',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_expired" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planHashedSubscriberId,
    extraBytes,
    usedBytes,
    startDate,
    expiryDate,
    isExpired,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'extra_packs_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExtraPackEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_hashed_subscriber_id')) {
      context.handle(
        _planHashedSubscriberIdMeta,
        planHashedSubscriberId.isAcceptableOrUnknown(
          data['plan_hashed_subscriber_id']!,
          _planHashedSubscriberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_planHashedSubscriberIdMeta);
    }
    if (data.containsKey('extra_bytes')) {
      context.handle(
        _extraBytesMeta,
        extraBytes.isAcceptableOrUnknown(data['extra_bytes']!, _extraBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_extraBytesMeta);
    }
    if (data.containsKey('used_bytes')) {
      context.handle(
        _usedBytesMeta,
        usedBytes.isAcceptableOrUnknown(data['used_bytes']!, _usedBytesMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    } else if (isInserting) {
      context.missing(_expiryDateMeta);
    }
    if (data.containsKey('is_expired')) {
      context.handle(
        _isExpiredMeta,
        isExpired.isAcceptableOrUnknown(data['is_expired']!, _isExpiredMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExtraPackEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtraPackEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planHashedSubscriberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_hashed_subscriber_id'],
      )!,
      extraBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extra_bytes'],
      )!,
      usedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used_bytes'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry_date'],
      )!,
      isExpired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_expired'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $ExtraPacksTableTable createAlias(String alias) {
    return $ExtraPacksTableTable(attachedDatabase, alias);
  }
}

class ExtraPackEntity extends DataClass implements Insertable<ExtraPackEntity> {
  final int id;
  final String planHashedSubscriberId;
  final int extraBytes;
  final int usedBytes;
  final DateTime startDate;
  final DateTime expiryDate;
  final bool isExpired;
  final String note;
  const ExtraPackEntity({
    required this.id,
    required this.planHashedSubscriberId,
    required this.extraBytes,
    required this.usedBytes,
    required this.startDate,
    required this.expiryDate,
    required this.isExpired,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_hashed_subscriber_id'] = Variable<String>(planHashedSubscriberId);
    map['extra_bytes'] = Variable<int>(extraBytes);
    map['used_bytes'] = Variable<int>(usedBytes);
    map['start_date'] = Variable<DateTime>(startDate);
    map['expiry_date'] = Variable<DateTime>(expiryDate);
    map['is_expired'] = Variable<bool>(isExpired);
    map['note'] = Variable<String>(note);
    return map;
  }

  ExtraPacksTableCompanion toCompanion(bool nullToAbsent) {
    return ExtraPacksTableCompanion(
      id: Value(id),
      planHashedSubscriberId: Value(planHashedSubscriberId),
      extraBytes: Value(extraBytes),
      usedBytes: Value(usedBytes),
      startDate: Value(startDate),
      expiryDate: Value(expiryDate),
      isExpired: Value(isExpired),
      note: Value(note),
    );
  }

  factory ExtraPackEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtraPackEntity(
      id: serializer.fromJson<int>(json['id']),
      planHashedSubscriberId: serializer.fromJson<String>(
        json['planHashedSubscriberId'],
      ),
      extraBytes: serializer.fromJson<int>(json['extraBytes']),
      usedBytes: serializer.fromJson<int>(json['usedBytes']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      expiryDate: serializer.fromJson<DateTime>(json['expiryDate']),
      isExpired: serializer.fromJson<bool>(json['isExpired']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planHashedSubscriberId': serializer.toJson<String>(
        planHashedSubscriberId,
      ),
      'extraBytes': serializer.toJson<int>(extraBytes),
      'usedBytes': serializer.toJson<int>(usedBytes),
      'startDate': serializer.toJson<DateTime>(startDate),
      'expiryDate': serializer.toJson<DateTime>(expiryDate),
      'isExpired': serializer.toJson<bool>(isExpired),
      'note': serializer.toJson<String>(note),
    };
  }

  ExtraPackEntity copyWith({
    int? id,
    String? planHashedSubscriberId,
    int? extraBytes,
    int? usedBytes,
    DateTime? startDate,
    DateTime? expiryDate,
    bool? isExpired,
    String? note,
  }) => ExtraPackEntity(
    id: id ?? this.id,
    planHashedSubscriberId:
        planHashedSubscriberId ?? this.planHashedSubscriberId,
    extraBytes: extraBytes ?? this.extraBytes,
    usedBytes: usedBytes ?? this.usedBytes,
    startDate: startDate ?? this.startDate,
    expiryDate: expiryDate ?? this.expiryDate,
    isExpired: isExpired ?? this.isExpired,
    note: note ?? this.note,
  );
  ExtraPackEntity copyWithCompanion(ExtraPacksTableCompanion data) {
    return ExtraPackEntity(
      id: data.id.present ? data.id.value : this.id,
      planHashedSubscriberId: data.planHashedSubscriberId.present
          ? data.planHashedSubscriberId.value
          : this.planHashedSubscriberId,
      extraBytes: data.extraBytes.present
          ? data.extraBytes.value
          : this.extraBytes,
      usedBytes: data.usedBytes.present ? data.usedBytes.value : this.usedBytes,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      isExpired: data.isExpired.present ? data.isExpired.value : this.isExpired,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtraPackEntity(')
          ..write('id: $id, ')
          ..write('planHashedSubscriberId: $planHashedSubscriberId, ')
          ..write('extraBytes: $extraBytes, ')
          ..write('usedBytes: $usedBytes, ')
          ..write('startDate: $startDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('isExpired: $isExpired, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planHashedSubscriberId,
    extraBytes,
    usedBytes,
    startDate,
    expiryDate,
    isExpired,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtraPackEntity &&
          other.id == this.id &&
          other.planHashedSubscriberId == this.planHashedSubscriberId &&
          other.extraBytes == this.extraBytes &&
          other.usedBytes == this.usedBytes &&
          other.startDate == this.startDate &&
          other.expiryDate == this.expiryDate &&
          other.isExpired == this.isExpired &&
          other.note == this.note);
}

class ExtraPacksTableCompanion extends UpdateCompanion<ExtraPackEntity> {
  final Value<int> id;
  final Value<String> planHashedSubscriberId;
  final Value<int> extraBytes;
  final Value<int> usedBytes;
  final Value<DateTime> startDate;
  final Value<DateTime> expiryDate;
  final Value<bool> isExpired;
  final Value<String> note;
  const ExtraPacksTableCompanion({
    this.id = const Value.absent(),
    this.planHashedSubscriberId = const Value.absent(),
    this.extraBytes = const Value.absent(),
    this.usedBytes = const Value.absent(),
    this.startDate = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.isExpired = const Value.absent(),
    this.note = const Value.absent(),
  });
  ExtraPacksTableCompanion.insert({
    this.id = const Value.absent(),
    required String planHashedSubscriberId,
    required int extraBytes,
    this.usedBytes = const Value.absent(),
    required DateTime startDate,
    required DateTime expiryDate,
    this.isExpired = const Value.absent(),
    this.note = const Value.absent(),
  }) : planHashedSubscriberId = Value(planHashedSubscriberId),
       extraBytes = Value(extraBytes),
       startDate = Value(startDate),
       expiryDate = Value(expiryDate);
  static Insertable<ExtraPackEntity> custom({
    Expression<int>? id,
    Expression<String>? planHashedSubscriberId,
    Expression<int>? extraBytes,
    Expression<int>? usedBytes,
    Expression<DateTime>? startDate,
    Expression<DateTime>? expiryDate,
    Expression<bool>? isExpired,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planHashedSubscriberId != null)
        'plan_hashed_subscriber_id': planHashedSubscriberId,
      if (extraBytes != null) 'extra_bytes': extraBytes,
      if (usedBytes != null) 'used_bytes': usedBytes,
      if (startDate != null) 'start_date': startDate,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (isExpired != null) 'is_expired': isExpired,
      if (note != null) 'note': note,
    });
  }

  ExtraPacksTableCompanion copyWith({
    Value<int>? id,
    Value<String>? planHashedSubscriberId,
    Value<int>? extraBytes,
    Value<int>? usedBytes,
    Value<DateTime>? startDate,
    Value<DateTime>? expiryDate,
    Value<bool>? isExpired,
    Value<String>? note,
  }) {
    return ExtraPacksTableCompanion(
      id: id ?? this.id,
      planHashedSubscriberId:
          planHashedSubscriberId ?? this.planHashedSubscriberId,
      extraBytes: extraBytes ?? this.extraBytes,
      usedBytes: usedBytes ?? this.usedBytes,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isExpired: isExpired ?? this.isExpired,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planHashedSubscriberId.present) {
      map['plan_hashed_subscriber_id'] = Variable<String>(
        planHashedSubscriberId.value,
      );
    }
    if (extraBytes.present) {
      map['extra_bytes'] = Variable<int>(extraBytes.value);
    }
    if (usedBytes.present) {
      map['used_bytes'] = Variable<int>(usedBytes.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (isExpired.present) {
      map['is_expired'] = Variable<bool>(isExpired.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtraPacksTableCompanion(')
          ..write('id: $id, ')
          ..write('planHashedSubscriberId: $planHashedSubscriberId, ')
          ..write('extraBytes: $extraBytes, ')
          ..write('usedBytes: $usedBytes, ')
          ..write('startDate: $startDate, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('isExpired: $isExpired, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DataPlansTableTable dataPlansTable = $DataPlansTableTable(this);
  late final $ExtraPacksTableTable extraPacksTable = $ExtraPacksTableTable(
    this,
  );
  late final DataPlansDao dataPlansDao = DataPlansDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dataPlansTable,
    extraPacksTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'data_plans_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('extra_packs_table', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DataPlansTableTableCreateCompanionBuilder =
    DataPlansTableCompanion Function({
      required String hashedSubscriberId,
      Value<String?> encryptedSubscriberId,
      Value<int> simSlotIndex,
      Value<String> carrierName,
      Value<int> quotaBytes,
      Value<int> billingCycleStartDay,
      Value<TimeIntervalType> cycleInterval,
      Value<int> customIntervalDays,
      Value<bool> rolloverEnabled,
      Value<List<int>> excludedUids,
      Value<int> cardColorIndex,
      Value<String> customNote,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DataPlansTableTableUpdateCompanionBuilder =
    DataPlansTableCompanion Function({
      Value<String> hashedSubscriberId,
      Value<String?> encryptedSubscriberId,
      Value<int> simSlotIndex,
      Value<String> carrierName,
      Value<int> quotaBytes,
      Value<int> billingCycleStartDay,
      Value<TimeIntervalType> cycleInterval,
      Value<int> customIntervalDays,
      Value<bool> rolloverEnabled,
      Value<List<int>> excludedUids,
      Value<int> cardColorIndex,
      Value<String> customNote,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$DataPlansTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $DataPlansTableTable, DataPlanEntity> {
  $$DataPlansTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ExtraPacksTableTable, List<ExtraPackEntity>>
  _extraPacksTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.extraPacksTable,
    aliasName: 'data_plans_table__hashed_subscriber_id__extra_packs_table__plan_hashed_subscriber_id',
  );

  $$ExtraPacksTableTableProcessedTableManager get extraPacksTableRefs {
    final manager =
        $$ExtraPacksTableTableTableManager($_db, $_db.extraPacksTable).filter(
          (f) => f.planHashedSubscriberId.hashedSubscriberId.sqlEquals(
            $_itemColumn<String>('hashed_subscriber_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _extraPacksTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DataPlansTableTableFilterComposer
    extends Composer<_$AppDatabase, $DataPlansTableTable> {
  $$DataPlansTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get hashedSubscriberId => $composableBuilder(
    column: $table.hashedSubscriberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedSubscriberId => $composableBuilder(
    column: $table.encryptedSubscriberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get simSlotIndex => $composableBuilder(
    column: $table.simSlotIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get carrierName => $composableBuilder(
    column: $table.carrierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quotaBytes => $composableBuilder(
    column: $table.quotaBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get billingCycleStartDay => $composableBuilder(
    column: $table.billingCycleStartDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TimeIntervalType, TimeIntervalType, String>
  get cycleInterval => $composableBuilder(
    column: $table.cycleInterval,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get customIntervalDays => $composableBuilder(
    column: $table.customIntervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rolloverEnabled => $composableBuilder(
    column: $table.rolloverEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<int>, List<int>, String>
  get excludedUids => $composableBuilder(
    column: $table.excludedUids,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get cardColorIndex => $composableBuilder(
    column: $table.cardColorIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customNote => $composableBuilder(
    column: $table.customNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> extraPacksTableRefs(
    Expression<bool> Function($$ExtraPacksTableTableFilterComposer f) f,
  ) {
    final $$ExtraPacksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.hashedSubscriberId,
      referencedTable: $db.extraPacksTable,
      getReferencedColumn: (t) => t.planHashedSubscriberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtraPacksTableTableFilterComposer(
            $db: $db,
            $table: $db.extraPacksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DataPlansTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DataPlansTableTable> {
  $$DataPlansTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get hashedSubscriberId => $composableBuilder(
    column: $table.hashedSubscriberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedSubscriberId => $composableBuilder(
    column: $table.encryptedSubscriberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get simSlotIndex => $composableBuilder(
    column: $table.simSlotIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get carrierName => $composableBuilder(
    column: $table.carrierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quotaBytes => $composableBuilder(
    column: $table.quotaBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get billingCycleStartDay => $composableBuilder(
    column: $table.billingCycleStartDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cycleInterval => $composableBuilder(
    column: $table.cycleInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get customIntervalDays => $composableBuilder(
    column: $table.customIntervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rolloverEnabled => $composableBuilder(
    column: $table.rolloverEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get excludedUids => $composableBuilder(
    column: $table.excludedUids,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardColorIndex => $composableBuilder(
    column: $table.cardColorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customNote => $composableBuilder(
    column: $table.customNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DataPlansTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DataPlansTableTable> {
  $$DataPlansTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get hashedSubscriberId => $composableBuilder(
    column: $table.hashedSubscriberId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get encryptedSubscriberId => $composableBuilder(
    column: $table.encryptedSubscriberId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get simSlotIndex => $composableBuilder(
    column: $table.simSlotIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get carrierName => $composableBuilder(
    column: $table.carrierName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quotaBytes => $composableBuilder(
    column: $table.quotaBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get billingCycleStartDay => $composableBuilder(
    column: $table.billingCycleStartDay,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TimeIntervalType, String>
  get cycleInterval => $composableBuilder(
    column: $table.cycleInterval,
    builder: (column) => column,
  );

  GeneratedColumn<int> get customIntervalDays => $composableBuilder(
    column: $table.customIntervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get rolloverEnabled => $composableBuilder(
    column: $table.rolloverEnabled,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<int>, String> get excludedUids =>
      $composableBuilder(
        column: $table.excludedUids,
        builder: (column) => column,
      );

  GeneratedColumn<int> get cardColorIndex => $composableBuilder(
    column: $table.cardColorIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customNote => $composableBuilder(
    column: $table.customNote,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> extraPacksTableRefs<T extends Object>(
    Expression<T> Function($$ExtraPacksTableTableAnnotationComposer a) f,
  ) {
    final $$ExtraPacksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.hashedSubscriberId,
      referencedTable: $db.extraPacksTable,
      getReferencedColumn: (t) => t.planHashedSubscriberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExtraPacksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.extraPacksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DataPlansTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DataPlansTableTable,
          DataPlanEntity,
          $$DataPlansTableTableFilterComposer,
          $$DataPlansTableTableOrderingComposer,
          $$DataPlansTableTableAnnotationComposer,
          $$DataPlansTableTableCreateCompanionBuilder,
          $$DataPlansTableTableUpdateCompanionBuilder,
          (DataPlanEntity, $$DataPlansTableTableReferences),
          DataPlanEntity,
          PrefetchHooks Function({bool extraPacksTableRefs})
        > {
  $$DataPlansTableTableTableManager(
    _$AppDatabase db,
    $DataPlansTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DataPlansTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DataPlansTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DataPlansTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> hashedSubscriberId = const Value.absent(),
                Value<String?> encryptedSubscriberId = const Value.absent(),
                Value<int> simSlotIndex = const Value.absent(),
                Value<String> carrierName = const Value.absent(),
                Value<int> quotaBytes = const Value.absent(),
                Value<int> billingCycleStartDay = const Value.absent(),
                Value<TimeIntervalType> cycleInterval = const Value.absent(),
                Value<int> customIntervalDays = const Value.absent(),
                Value<bool> rolloverEnabled = const Value.absent(),
                Value<List<int>> excludedUids = const Value.absent(),
                Value<int> cardColorIndex = const Value.absent(),
                Value<String> customNote = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DataPlansTableCompanion(
                hashedSubscriberId: hashedSubscriberId,
                encryptedSubscriberId: encryptedSubscriberId,
                simSlotIndex: simSlotIndex,
                carrierName: carrierName,
                quotaBytes: quotaBytes,
                billingCycleStartDay: billingCycleStartDay,
                cycleInterval: cycleInterval,
                customIntervalDays: customIntervalDays,
                rolloverEnabled: rolloverEnabled,
                excludedUids: excludedUids,
                cardColorIndex: cardColorIndex,
                customNote: customNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String hashedSubscriberId,
                Value<String?> encryptedSubscriberId = const Value.absent(),
                Value<int> simSlotIndex = const Value.absent(),
                Value<String> carrierName = const Value.absent(),
                Value<int> quotaBytes = const Value.absent(),
                Value<int> billingCycleStartDay = const Value.absent(),
                Value<TimeIntervalType> cycleInterval = const Value.absent(),
                Value<int> customIntervalDays = const Value.absent(),
                Value<bool> rolloverEnabled = const Value.absent(),
                Value<List<int>> excludedUids = const Value.absent(),
                Value<int> cardColorIndex = const Value.absent(),
                Value<String> customNote = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DataPlansTableCompanion.insert(
                hashedSubscriberId: hashedSubscriberId,
                encryptedSubscriberId: encryptedSubscriberId,
                simSlotIndex: simSlotIndex,
                carrierName: carrierName,
                quotaBytes: quotaBytes,
                billingCycleStartDay: billingCycleStartDay,
                cycleInterval: cycleInterval,
                customIntervalDays: customIntervalDays,
                rolloverEnabled: rolloverEnabled,
                excludedUids: excludedUids,
                cardColorIndex: cardColorIndex,
                customNote: customNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DataPlansTableTable, DataPlanEntity>(table),
                  $$DataPlansTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({extraPacksTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (extraPacksTableRefs) db.extraPacksTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (extraPacksTableRefs)
                    await $_getPrefetchedData<
                      DataPlanEntity,
                      $DataPlansTableTable,
                      ExtraPackEntity
                    >(
                      currentTable: table,
                      referencedTable: $$DataPlansTableTableReferences
                          ._extraPacksTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DataPlansTableTableReferences(
                            db,
                            table,
                            p0,
                          ).extraPacksTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) =>
                                e.planHashedSubscriberId ==
                                item.hashedSubscriberId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DataPlansTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DataPlansTableTable,
      DataPlanEntity,
      $$DataPlansTableTableFilterComposer,
      $$DataPlansTableTableOrderingComposer,
      $$DataPlansTableTableAnnotationComposer,
      $$DataPlansTableTableCreateCompanionBuilder,
      $$DataPlansTableTableUpdateCompanionBuilder,
      (DataPlanEntity, $$DataPlansTableTableReferences),
      DataPlanEntity,
      PrefetchHooks Function({bool extraPacksTableRefs})
    >;
typedef $$ExtraPacksTableTableCreateCompanionBuilder =
    ExtraPacksTableCompanion Function({
      Value<int> id,
      required String planHashedSubscriberId,
      required int extraBytes,
      Value<int> usedBytes,
      required DateTime startDate,
      required DateTime expiryDate,
      Value<bool> isExpired,
      Value<String> note,
    });
typedef $$ExtraPacksTableTableUpdateCompanionBuilder =
    ExtraPacksTableCompanion Function({
      Value<int> id,
      Value<String> planHashedSubscriberId,
      Value<int> extraBytes,
      Value<int> usedBytes,
      Value<DateTime> startDate,
      Value<DateTime> expiryDate,
      Value<bool> isExpired,
      Value<String> note,
    });

final class $$ExtraPacksTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $ExtraPacksTableTable, ExtraPackEntity> {
  $$ExtraPacksTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DataPlansTableTable _planHashedSubscriberIdTable(_$AppDatabase db) =>
      db.dataPlansTable.createAlias(
        'extra_packs_table__plan_hashed_subscriber_id__data_plans_table__hashed_subscriber_id',
      );

  $$DataPlansTableTableProcessedTableManager get planHashedSubscriberId {
    final $_column = $_itemColumn<String>('plan_hashed_subscriber_id')!;

    final manager = $$DataPlansTableTableTableManager(
      $_db,
      $_db.dataPlansTable,
    ).filter((f) => f.hashedSubscriberId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _planHashedSubscriberIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExtraPacksTableTableFilterComposer
    extends Composer<_$AppDatabase, $ExtraPacksTableTable> {
  $$ExtraPacksTableTableFilterComposer({
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

  ColumnFilters<int> get extraBytes => $composableBuilder(
    column: $table.extraBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usedBytes => $composableBuilder(
    column: $table.usedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExpired => $composableBuilder(
    column: $table.isExpired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$DataPlansTableTableFilterComposer get planHashedSubscriberId {
    final $$DataPlansTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planHashedSubscriberId,
      referencedTable: $db.dataPlansTable,
      getReferencedColumn: (t) => t.hashedSubscriberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DataPlansTableTableFilterComposer(
            $db: $db,
            $table: $db.dataPlansTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtraPacksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ExtraPacksTableTable> {
  $$ExtraPacksTableTableOrderingComposer({
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

  ColumnOrderings<int> get extraBytes => $composableBuilder(
    column: $table.extraBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usedBytes => $composableBuilder(
    column: $table.usedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExpired => $composableBuilder(
    column: $table.isExpired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$DataPlansTableTableOrderingComposer get planHashedSubscriberId {
    final $$DataPlansTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planHashedSubscriberId,
      referencedTable: $db.dataPlansTable,
      getReferencedColumn: (t) => t.hashedSubscriberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DataPlansTableTableOrderingComposer(
            $db: $db,
            $table: $db.dataPlansTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtraPacksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExtraPacksTableTable> {
  $$ExtraPacksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get extraBytes => $composableBuilder(
    column: $table.extraBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usedBytes =>
      $composableBuilder(column: $table.usedBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isExpired =>
      $composableBuilder(column: $table.isExpired, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$DataPlansTableTableAnnotationComposer get planHashedSubscriberId {
    final $$DataPlansTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planHashedSubscriberId,
      referencedTable: $db.dataPlansTable,
      getReferencedColumn: (t) => t.hashedSubscriberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DataPlansTableTableAnnotationComposer(
            $db: $db,
            $table: $db.dataPlansTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExtraPacksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExtraPacksTableTable,
          ExtraPackEntity,
          $$ExtraPacksTableTableFilterComposer,
          $$ExtraPacksTableTableOrderingComposer,
          $$ExtraPacksTableTableAnnotationComposer,
          $$ExtraPacksTableTableCreateCompanionBuilder,
          $$ExtraPacksTableTableUpdateCompanionBuilder,
          (ExtraPackEntity, $$ExtraPacksTableTableReferences),
          ExtraPackEntity,
          PrefetchHooks Function({bool planHashedSubscriberId})
        > {
  $$ExtraPacksTableTableTableManager(
    _$AppDatabase db,
    $ExtraPacksTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExtraPacksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExtraPacksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExtraPacksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> planHashedSubscriberId = const Value.absent(),
                Value<int> extraBytes = const Value.absent(),
                Value<int> usedBytes = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> expiryDate = const Value.absent(),
                Value<bool> isExpired = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => ExtraPacksTableCompanion(
                id: id,
                planHashedSubscriberId: planHashedSubscriberId,
                extraBytes: extraBytes,
                usedBytes: usedBytes,
                startDate: startDate,
                expiryDate: expiryDate,
                isExpired: isExpired,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String planHashedSubscriberId,
                required int extraBytes,
                Value<int> usedBytes = const Value.absent(),
                required DateTime startDate,
                required DateTime expiryDate,
                Value<bool> isExpired = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => ExtraPacksTableCompanion.insert(
                id: id,
                planHashedSubscriberId: planHashedSubscriberId,
                extraBytes: extraBytes,
                usedBytes: usedBytes,
                startDate: startDate,
                expiryDate: expiryDate,
                isExpired: isExpired,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExtraPacksTableTable, ExtraPackEntity>(table),
                  $$ExtraPacksTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planHashedSubscriberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (planHashedSubscriberId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.planHashedSubscriberId,
                        referencedTable: $$ExtraPacksTableTableReferences
                            ._planHashedSubscriberIdTable(db),
                        referencedColumn: $$ExtraPacksTableTableReferences
                            ._planHashedSubscriberIdTable(db)
                            .hashedSubscriberId,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExtraPacksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExtraPacksTableTable,
      ExtraPackEntity,
      $$ExtraPacksTableTableFilterComposer,
      $$ExtraPacksTableTableOrderingComposer,
      $$ExtraPacksTableTableAnnotationComposer,
      $$ExtraPacksTableTableCreateCompanionBuilder,
      $$ExtraPacksTableTableUpdateCompanionBuilder,
      (ExtraPackEntity, $$ExtraPacksTableTableReferences),
      ExtraPackEntity,
      PrefetchHooks Function({bool planHashedSubscriberId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DataPlansTableTableTableManager get dataPlansTable =>
      $$DataPlansTableTableTableManager(_db, _db.dataPlansTable);
  $$ExtraPacksTableTableTableManager get extraPacksTable =>
      $$ExtraPacksTableTableTableManager(_db, _db.extraPacksTable);
}
