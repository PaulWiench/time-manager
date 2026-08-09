// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DayEntriesTable extends DayEntries
    with TableInfo<$DayEntriesTable, DayEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _netWorkedHoursMeta = const VerificationMeta(
    'netWorkedHours',
  );
  @override
  late final GeneratedColumn<double> netWorkedHours = GeneratedColumn<double>(
    'net_worked_hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _leaveHoursMeta = const VerificationMeta(
    'leaveHours',
  );
  @override
  late final GeneratedColumn<double> leaveHours = GeneratedColumn<double>(
    'leave_hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _targetHoursMeta = const VerificationMeta(
    'targetHours',
  );
  @override
  late final GeneratedColumn<double> targetHours = GeneratedColumn<double>(
    'target_hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _balanceDeltaMeta = const VerificationMeta(
    'balanceDelta',
  );
  @override
  late final GeneratedColumn<double> balanceDelta = GeneratedColumn<double>(
    'balance_delta',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _autoBreakOverriddenMeta =
      const VerificationMeta('autoBreakOverridden');
  @override
  late final GeneratedColumn<bool> autoBreakOverridden = GeneratedColumn<bool>(
    'auto_break_overridden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_break_overridden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    netWorkedHours,
    leaveHours,
    targetHours,
    balanceDelta,
    autoBreakOverridden,
    notes,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('net_worked_hours')) {
      context.handle(
        _netWorkedHoursMeta,
        netWorkedHours.isAcceptableOrUnknown(
          data['net_worked_hours']!,
          _netWorkedHoursMeta,
        ),
      );
    }
    if (data.containsKey('leave_hours')) {
      context.handle(
        _leaveHoursMeta,
        leaveHours.isAcceptableOrUnknown(data['leave_hours']!, _leaveHoursMeta),
      );
    }
    if (data.containsKey('target_hours')) {
      context.handle(
        _targetHoursMeta,
        targetHours.isAcceptableOrUnknown(
          data['target_hours']!,
          _targetHoursMeta,
        ),
      );
    }
    if (data.containsKey('balance_delta')) {
      context.handle(
        _balanceDeltaMeta,
        balanceDelta.isAcceptableOrUnknown(
          data['balance_delta']!,
          _balanceDeltaMeta,
        ),
      );
    }
    if (data.containsKey('auto_break_overridden')) {
      context.handle(
        _autoBreakOverriddenMeta,
        autoBreakOverridden.isAcceptableOrUnknown(
          data['auto_break_overridden']!,
          _autoBreakOverriddenMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DayEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayEntry(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      netWorkedHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}net_worked_hours'],
      )!,
      leaveHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}leave_hours'],
      )!,
      targetHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_hours'],
      )!,
      balanceDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance_delta'],
      )!,
      autoBreakOverridden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_break_overridden'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DayEntriesTable createAlias(String alias) {
    return $DayEntriesTable(attachedDatabase, alias);
  }
}

class DayEntry extends DataClass implements Insertable<DayEntry> {
  final DateTime date;
  final double netWorkedHours;
  final double leaveHours;
  final double targetHours;
  final double balanceDelta;
  final bool autoBreakOverridden;
  final String? notes;
  final DateTime updatedAt;
  const DayEntry({
    required this.date,
    required this.netWorkedHours,
    required this.leaveHours,
    required this.targetHours,
    required this.balanceDelta,
    required this.autoBreakOverridden,
    this.notes,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<DateTime>(date);
    map['net_worked_hours'] = Variable<double>(netWorkedHours);
    map['leave_hours'] = Variable<double>(leaveHours);
    map['target_hours'] = Variable<double>(targetHours);
    map['balance_delta'] = Variable<double>(balanceDelta);
    map['auto_break_overridden'] = Variable<bool>(autoBreakOverridden);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DayEntriesCompanion toCompanion(bool nullToAbsent) {
    return DayEntriesCompanion(
      date: Value(date),
      netWorkedHours: Value(netWorkedHours),
      leaveHours: Value(leaveHours),
      targetHours: Value(targetHours),
      balanceDelta: Value(balanceDelta),
      autoBreakOverridden: Value(autoBreakOverridden),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      updatedAt: Value(updatedAt),
    );
  }

  factory DayEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayEntry(
      date: serializer.fromJson<DateTime>(json['date']),
      netWorkedHours: serializer.fromJson<double>(json['netWorkedHours']),
      leaveHours: serializer.fromJson<double>(json['leaveHours']),
      targetHours: serializer.fromJson<double>(json['targetHours']),
      balanceDelta: serializer.fromJson<double>(json['balanceDelta']),
      autoBreakOverridden: serializer.fromJson<bool>(
        json['autoBreakOverridden'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<DateTime>(date),
      'netWorkedHours': serializer.toJson<double>(netWorkedHours),
      'leaveHours': serializer.toJson<double>(leaveHours),
      'targetHours': serializer.toJson<double>(targetHours),
      'balanceDelta': serializer.toJson<double>(balanceDelta),
      'autoBreakOverridden': serializer.toJson<bool>(autoBreakOverridden),
      'notes': serializer.toJson<String?>(notes),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DayEntry copyWith({
    DateTime? date,
    double? netWorkedHours,
    double? leaveHours,
    double? targetHours,
    double? balanceDelta,
    bool? autoBreakOverridden,
    Value<String?> notes = const Value.absent(),
    DateTime? updatedAt,
  }) => DayEntry(
    date: date ?? this.date,
    netWorkedHours: netWorkedHours ?? this.netWorkedHours,
    leaveHours: leaveHours ?? this.leaveHours,
    targetHours: targetHours ?? this.targetHours,
    balanceDelta: balanceDelta ?? this.balanceDelta,
    autoBreakOverridden: autoBreakOverridden ?? this.autoBreakOverridden,
    notes: notes.present ? notes.value : this.notes,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DayEntry copyWithCompanion(DayEntriesCompanion data) {
    return DayEntry(
      date: data.date.present ? data.date.value : this.date,
      netWorkedHours: data.netWorkedHours.present
          ? data.netWorkedHours.value
          : this.netWorkedHours,
      leaveHours: data.leaveHours.present
          ? data.leaveHours.value
          : this.leaveHours,
      targetHours: data.targetHours.present
          ? data.targetHours.value
          : this.targetHours,
      balanceDelta: data.balanceDelta.present
          ? data.balanceDelta.value
          : this.balanceDelta,
      autoBreakOverridden: data.autoBreakOverridden.present
          ? data.autoBreakOverridden.value
          : this.autoBreakOverridden,
      notes: data.notes.present ? data.notes.value : this.notes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayEntry(')
          ..write('date: $date, ')
          ..write('netWorkedHours: $netWorkedHours, ')
          ..write('leaveHours: $leaveHours, ')
          ..write('targetHours: $targetHours, ')
          ..write('balanceDelta: $balanceDelta, ')
          ..write('autoBreakOverridden: $autoBreakOverridden, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    date,
    netWorkedHours,
    leaveHours,
    targetHours,
    balanceDelta,
    autoBreakOverridden,
    notes,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayEntry &&
          other.date == this.date &&
          other.netWorkedHours == this.netWorkedHours &&
          other.leaveHours == this.leaveHours &&
          other.targetHours == this.targetHours &&
          other.balanceDelta == this.balanceDelta &&
          other.autoBreakOverridden == this.autoBreakOverridden &&
          other.notes == this.notes &&
          other.updatedAt == this.updatedAt);
}

class DayEntriesCompanion extends UpdateCompanion<DayEntry> {
  final Value<DateTime> date;
  final Value<double> netWorkedHours;
  final Value<double> leaveHours;
  final Value<double> targetHours;
  final Value<double> balanceDelta;
  final Value<bool> autoBreakOverridden;
  final Value<String?> notes;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DayEntriesCompanion({
    this.date = const Value.absent(),
    this.netWorkedHours = const Value.absent(),
    this.leaveHours = const Value.absent(),
    this.targetHours = const Value.absent(),
    this.balanceDelta = const Value.absent(),
    this.autoBreakOverridden = const Value.absent(),
    this.notes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayEntriesCompanion.insert({
    required DateTime date,
    this.netWorkedHours = const Value.absent(),
    this.leaveHours = const Value.absent(),
    this.targetHours = const Value.absent(),
    this.balanceDelta = const Value.absent(),
    this.autoBreakOverridden = const Value.absent(),
    this.notes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DayEntry> custom({
    Expression<DateTime>? date,
    Expression<double>? netWorkedHours,
    Expression<double>? leaveHours,
    Expression<double>? targetHours,
    Expression<double>? balanceDelta,
    Expression<bool>? autoBreakOverridden,
    Expression<String>? notes,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (netWorkedHours != null) 'net_worked_hours': netWorkedHours,
      if (leaveHours != null) 'leave_hours': leaveHours,
      if (targetHours != null) 'target_hours': targetHours,
      if (balanceDelta != null) 'balance_delta': balanceDelta,
      if (autoBreakOverridden != null)
        'auto_break_overridden': autoBreakOverridden,
      if (notes != null) 'notes': notes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayEntriesCompanion copyWith({
    Value<DateTime>? date,
    Value<double>? netWorkedHours,
    Value<double>? leaveHours,
    Value<double>? targetHours,
    Value<double>? balanceDelta,
    Value<bool>? autoBreakOverridden,
    Value<String?>? notes,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DayEntriesCompanion(
      date: date ?? this.date,
      netWorkedHours: netWorkedHours ?? this.netWorkedHours,
      leaveHours: leaveHours ?? this.leaveHours,
      targetHours: targetHours ?? this.targetHours,
      balanceDelta: balanceDelta ?? this.balanceDelta,
      autoBreakOverridden: autoBreakOverridden ?? this.autoBreakOverridden,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (netWorkedHours.present) {
      map['net_worked_hours'] = Variable<double>(netWorkedHours.value);
    }
    if (leaveHours.present) {
      map['leave_hours'] = Variable<double>(leaveHours.value);
    }
    if (targetHours.present) {
      map['target_hours'] = Variable<double>(targetHours.value);
    }
    if (balanceDelta.present) {
      map['balance_delta'] = Variable<double>(balanceDelta.value);
    }
    if (autoBreakOverridden.present) {
      map['auto_break_overridden'] = Variable<bool>(autoBreakOverridden.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
    return (StringBuffer('DayEntriesCompanion(')
          ..write('date: $date, ')
          ..write('netWorkedHours: $netWorkedHours, ')
          ..write('leaveHours: $leaveHours, ')
          ..write('targetHours: $targetHours, ')
          ..write('balanceDelta: $balanceDelta, ')
          ..write('autoBreakOverridden: $autoBreakOverridden, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkSessionsTable extends WorkSessions
    with TableInfo<$WorkSessionsTable, WorkSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES day_entries (date)',
    ),
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SessionStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SessionStatus>($WorkSessionsTable.$converterstatus);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    startTime,
    endTime,
    status,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      status: $WorkSessionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
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
  $WorkSessionsTable createAlias(String alias) {
    return $WorkSessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SessionStatus, String, String> $converterstatus =
      const EnumNameConverter<SessionStatus>(SessionStatus.values);
}

class WorkSession extends DataClass implements Insertable<WorkSession> {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime;
  final SessionStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WorkSession({
    required this.id,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    {
      map['status'] = Variable<String>(
        $WorkSessionsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WorkSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkSessionsCompanion(
      id: Value(id),
      date: Value(date),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkSession(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      status: $WorkSessionsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'status': serializer.toJson<String>(
        $WorkSessionsTable.$converterstatus.toJson(status),
      ),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WorkSession copyWith({
    String? id,
    DateTime? date,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    SessionStatus? status,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WorkSession(
    id: id ?? this.id,
    date: date ?? this.date,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WorkSession copyWithCompanion(WorkSessionsCompanion data) {
    return WorkSession(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkSession(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    startTime,
    endTime,
    status,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkSession &&
          other.id == this.id &&
          other.date == this.date &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorkSessionsCompanion extends UpdateCompanion<WorkSession> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<SessionStatus> status;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WorkSessionsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkSessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    required SessionStatus status,
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       startTime = Value(startTime),
       status = Value(status);
  static Insertable<WorkSession> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkSessionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<SessionStatus>? status,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WorkSessionsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $WorkSessionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
    return (StringBuffer('WorkSessionsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BreakEntriesTable extends BreakEntries
    with TableInfo<$BreakEntriesTable, BreakEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BreakEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES day_entries (date)',
    ),
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BreakType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BreakType>($BreakEntriesTable.$convertertype);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    startTime,
    endTime,
    type,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'break_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BreakEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BreakEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BreakEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      )!,
      type: $BreakEntriesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
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
  $BreakEntriesTable createAlias(String alias) {
    return $BreakEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BreakType, String, String> $convertertype =
      const EnumNameConverter<BreakType>(BreakType.values);
}

class BreakEntry extends DataClass implements Insertable<BreakEntry> {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final BreakType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BreakEntry({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    {
      map['type'] = Variable<String>(
        $BreakEntriesTable.$convertertype.toSql(type),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BreakEntriesCompanion toCompanion(bool nullToAbsent) {
    return BreakEntriesCompanion(
      id: Value(id),
      date: Value(date),
      startTime: Value(startTime),
      endTime: Value(endTime),
      type: Value(type),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BreakEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BreakEntry(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      type: $BreakEntriesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'type': serializer.toJson<String>(
        $BreakEntriesTable.$convertertype.toJson(type),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BreakEntry copyWith({
    String? id,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    BreakType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BreakEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BreakEntry copyWithCompanion(BreakEntriesCompanion data) {
    return BreakEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BreakEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, startTime, endTime, type, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BreakEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.type == this.type &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BreakEntriesCompanion extends UpdateCompanion<BreakEntry> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<BreakType> type;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BreakEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BreakEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required BreakType type,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       startTime = Value(startTime),
       endTime = Value(endTime),
       type = Value(type);
  static Insertable<BreakEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? type,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BreakEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<DateTime>? startTime,
    Value<DateTime>? endTime,
    Value<BreakType>? type,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BreakEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $BreakEntriesTable.$convertertype.toSql(type.value),
      );
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
    return (StringBuffer('BreakEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LeaveEntriesTable extends LeaveEntries
    with TableInfo<$LeaveEntriesTable, LeaveEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LeaveEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES day_entries (date)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LeaveType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LeaveType>($LeaveEntriesTable.$convertertype);
  static const VerificationMeta _hoursMeta = const VerificationMeta('hours');
  @override
  late final GeneratedColumn<double> hours = GeneratedColumn<double>(
    'hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    type,
    hours,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'leave_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LeaveEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('hours')) {
      context.handle(
        _hoursMeta,
        hours.isAcceptableOrUnknown(data['hours']!, _hoursMeta),
      );
    } else if (isInserting) {
      context.missing(_hoursMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LeaveEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LeaveEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      type: $LeaveEntriesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      hours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hours'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
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
  $LeaveEntriesTable createAlias(String alias) {
    return $LeaveEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LeaveType, String, String> $convertertype =
      const EnumNameConverter<LeaveType>(LeaveType.values);
}

class LeaveEntry extends DataClass implements Insertable<LeaveEntry> {
  final String id;
  final DateTime date;
  final LeaveType type;
  final double hours;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LeaveEntry({
    required this.id,
    required this.date,
    required this.type,
    required this.hours,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    {
      map['type'] = Variable<String>(
        $LeaveEntriesTable.$convertertype.toSql(type),
      );
    }
    map['hours'] = Variable<double>(hours);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LeaveEntriesCompanion toCompanion(bool nullToAbsent) {
    return LeaveEntriesCompanion(
      id: Value(id),
      date: Value(date),
      type: Value(type),
      hours: Value(hours),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LeaveEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LeaveEntry(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      type: $LeaveEntriesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      hours: serializer.fromJson<double>(json['hours']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'type': serializer.toJson<String>(
        $LeaveEntriesTable.$convertertype.toJson(type),
      ),
      'hours': serializer.toJson<double>(hours),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LeaveEntry copyWith({
    String? id,
    DateTime? date,
    LeaveType? type,
    double? hours,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LeaveEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    type: type ?? this.type,
    hours: hours ?? this.hours,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LeaveEntry copyWithCompanion(LeaveEntriesCompanion data) {
    return LeaveEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      hours: data.hours.present ? data.hours.value : this.hours,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LeaveEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('hours: $hours, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, type, hours, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LeaveEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.type == this.type &&
          other.hours == this.hours &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LeaveEntriesCompanion extends UpdateCompanion<LeaveEntry> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<LeaveType> type;
  final Value<double> hours;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LeaveEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.hours = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LeaveEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required LeaveType type,
    required double hours,
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       type = Value(type),
       hours = Value(hours);
  static Insertable<LeaveEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<String>? type,
    Expression<double>? hours,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (hours != null) 'hours': hours,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LeaveEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<LeaveType>? type,
    Value<double>? hours,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LeaveEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      hours: hours ?? this.hours,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $LeaveEntriesTable.$convertertype.toSql(type.value),
      );
    }
    if (hours.present) {
      map['hours'] = Variable<double>(hours.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
    return (StringBuffer('LeaveEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('hours: $hours, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PublicHolidaysTable extends PublicHolidays
    with TableInfo<$PublicHolidaysTable, PublicHoliday> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PublicHolidaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fractionMeta = const VerificationMeta(
    'fraction',
  );
  @override
  late final GeneratedColumn<double> fraction = GeneratedColumn<double>(
    'fraction',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<HolidaySource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<HolidaySource>($PublicHolidaysTable.$convertersource);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    name,
    fraction,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'public_holidays';
  @override
  VerificationContext validateIntegrity(
    Insertable<PublicHoliday> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('fraction')) {
      context.handle(
        _fractionMeta,
        fraction.isAcceptableOrUnknown(data['fraction']!, _fractionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  PublicHoliday map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PublicHoliday(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fraction: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fraction'],
      )!,
      source: $PublicHolidaysTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PublicHolidaysTable createAlias(String alias) {
    return $PublicHolidaysTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<HolidaySource, String, String> $convertersource =
      const EnumNameConverter<HolidaySource>(HolidaySource.values);
}

class PublicHoliday extends DataClass implements Insertable<PublicHoliday> {
  final DateTime date;
  final String name;
  final double fraction;
  final HolidaySource source;
  final DateTime createdAt;
  const PublicHoliday({
    required this.date,
    required this.name,
    required this.fraction,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<DateTime>(date);
    map['name'] = Variable<String>(name);
    map['fraction'] = Variable<double>(fraction);
    {
      map['source'] = Variable<String>(
        $PublicHolidaysTable.$convertersource.toSql(source),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PublicHolidaysCompanion toCompanion(bool nullToAbsent) {
    return PublicHolidaysCompanion(
      date: Value(date),
      name: Value(name),
      fraction: Value(fraction),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory PublicHoliday.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PublicHoliday(
      date: serializer.fromJson<DateTime>(json['date']),
      name: serializer.fromJson<String>(json['name']),
      fraction: serializer.fromJson<double>(json['fraction']),
      source: $PublicHolidaysTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<DateTime>(date),
      'name': serializer.toJson<String>(name),
      'fraction': serializer.toJson<double>(fraction),
      'source': serializer.toJson<String>(
        $PublicHolidaysTable.$convertersource.toJson(source),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PublicHoliday copyWith({
    DateTime? date,
    String? name,
    double? fraction,
    HolidaySource? source,
    DateTime? createdAt,
  }) => PublicHoliday(
    date: date ?? this.date,
    name: name ?? this.name,
    fraction: fraction ?? this.fraction,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  PublicHoliday copyWithCompanion(PublicHolidaysCompanion data) {
    return PublicHoliday(
      date: data.date.present ? data.date.value : this.date,
      name: data.name.present ? data.name.value : this.name,
      fraction: data.fraction.present ? data.fraction.value : this.fraction,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PublicHoliday(')
          ..write('date: $date, ')
          ..write('name: $name, ')
          ..write('fraction: $fraction, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, name, fraction, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PublicHoliday &&
          other.date == this.date &&
          other.name == this.name &&
          other.fraction == this.fraction &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class PublicHolidaysCompanion extends UpdateCompanion<PublicHoliday> {
  final Value<DateTime> date;
  final Value<String> name;
  final Value<double> fraction;
  final Value<HolidaySource> source;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PublicHolidaysCompanion({
    this.date = const Value.absent(),
    this.name = const Value.absent(),
    this.fraction = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PublicHolidaysCompanion.insert({
    required DateTime date,
    required String name,
    this.fraction = const Value.absent(),
    required HolidaySource source,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       name = Value(name),
       source = Value(source);
  static Insertable<PublicHoliday> custom({
    Expression<DateTime>? date,
    Expression<String>? name,
    Expression<double>? fraction,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (name != null) 'name': name,
      if (fraction != null) 'fraction': fraction,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PublicHolidaysCompanion copyWith({
    Value<DateTime>? date,
    Value<String>? name,
    Value<double>? fraction,
    Value<HolidaySource>? source,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PublicHolidaysCompanion(
      date: date ?? this.date,
      name: name ?? this.name,
      fraction: fraction ?? this.fraction,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fraction.present) {
      map['fraction'] = Variable<double>(fraction.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $PublicHolidaysTable.$convertersource.toSql(source.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PublicHolidaysCompanion(')
          ..write('date: $date, ')
          ..write('name: $name, ')
          ..write('fraction: $fraction, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BalanceSnapshotsTable extends BalanceSnapshots
    with TableInfo<$BalanceSnapshotsTable, BalanceSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BalanceSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [date, balance, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'balance_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<BalanceSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  BalanceSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BalanceSnapshot(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BalanceSnapshotsTable createAlias(String alias) {
    return $BalanceSnapshotsTable(attachedDatabase, alias);
  }
}

class BalanceSnapshot extends DataClass implements Insertable<BalanceSnapshot> {
  final DateTime date;
  final double balance;
  final DateTime updatedAt;
  const BalanceSnapshot({
    required this.date,
    required this.balance,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<DateTime>(date);
    map['balance'] = Variable<double>(balance);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BalanceSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return BalanceSnapshotsCompanion(
      date: Value(date),
      balance: Value(balance),
      updatedAt: Value(updatedAt),
    );
  }

  factory BalanceSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BalanceSnapshot(
      date: serializer.fromJson<DateTime>(json['date']),
      balance: serializer.fromJson<double>(json['balance']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<DateTime>(date),
      'balance': serializer.toJson<double>(balance),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BalanceSnapshot copyWith({
    DateTime? date,
    double? balance,
    DateTime? updatedAt,
  }) => BalanceSnapshot(
    date: date ?? this.date,
    balance: balance ?? this.balance,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BalanceSnapshot copyWithCompanion(BalanceSnapshotsCompanion data) {
    return BalanceSnapshot(
      date: data.date.present ? data.date.value : this.date,
      balance: data.balance.present ? data.balance.value : this.balance,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BalanceSnapshot(')
          ..write('date: $date, ')
          ..write('balance: $balance, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, balance, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BalanceSnapshot &&
          other.date == this.date &&
          other.balance == this.balance &&
          other.updatedAt == this.updatedAt);
}

class BalanceSnapshotsCompanion extends UpdateCompanion<BalanceSnapshot> {
  final Value<DateTime> date;
  final Value<double> balance;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BalanceSnapshotsCompanion({
    this.date = const Value.absent(),
    this.balance = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BalanceSnapshotsCompanion.insert({
    required DateTime date,
    required double balance,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       balance = Value(balance);
  static Insertable<BalanceSnapshot> custom({
    Expression<DateTime>? date,
    Expression<double>? balance,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (balance != null) 'balance': balance,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BalanceSnapshotsCompanion copyWith({
    Value<DateTime>? date,
    Value<double>? balance,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BalanceSnapshotsCompanion(
      date: date ?? this.date,
      balance: balance ?? this.balance,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
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
    return (StringBuffer('BalanceSnapshotsCompanion(')
          ..write('date: $date, ')
          ..write('balance: $balance, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VacationQuotasTable extends VacationQuotas
    with TableInfo<$VacationQuotasTable, VacationQuota> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VacationQuotasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalDaysMeta = const VerificationMeta(
    'totalDays',
  );
  @override
  late final GeneratedColumn<double> totalDays = GeneratedColumn<double>(
    'total_days',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _rolloverDaysMeta = const VerificationMeta(
    'rolloverDays',
  );
  @override
  late final GeneratedColumn<double> rolloverDays = GeneratedColumn<double>(
    'rollover_days',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rolloverDeadlineMeta = const VerificationMeta(
    'rolloverDeadline',
  );
  @override
  late final GeneratedColumn<DateTime> rolloverDeadline =
      GeneratedColumn<DateTime>(
        'rollover_deadline',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    year,
    totalDays,
    rolloverDays,
    rolloverDeadline,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vacation_quotas';
  @override
  VerificationContext validateIntegrity(
    Insertable<VacationQuota> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('total_days')) {
      context.handle(
        _totalDaysMeta,
        totalDays.isAcceptableOrUnknown(data['total_days']!, _totalDaysMeta),
      );
    }
    if (data.containsKey('rollover_days')) {
      context.handle(
        _rolloverDaysMeta,
        rolloverDays.isAcceptableOrUnknown(
          data['rollover_days']!,
          _rolloverDaysMeta,
        ),
      );
    }
    if (data.containsKey('rollover_deadline')) {
      context.handle(
        _rolloverDeadlineMeta,
        rolloverDeadline.isAcceptableOrUnknown(
          data['rollover_deadline']!,
          _rolloverDeadlineMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {year};
  @override
  VacationQuota map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VacationQuota(
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      totalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_days'],
      )!,
      rolloverDays: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rollover_days'],
      )!,
      rolloverDeadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}rollover_deadline'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VacationQuotasTable createAlias(String alias) {
    return $VacationQuotasTable(attachedDatabase, alias);
  }
}

class VacationQuota extends DataClass implements Insertable<VacationQuota> {
  final int year;
  final double totalDays;
  final double rolloverDays;
  final DateTime? rolloverDeadline;
  final DateTime updatedAt;
  const VacationQuota({
    required this.year,
    required this.totalDays,
    required this.rolloverDays,
    this.rolloverDeadline,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['year'] = Variable<int>(year);
    map['total_days'] = Variable<double>(totalDays);
    map['rollover_days'] = Variable<double>(rolloverDays);
    if (!nullToAbsent || rolloverDeadline != null) {
      map['rollover_deadline'] = Variable<DateTime>(rolloverDeadline);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VacationQuotasCompanion toCompanion(bool nullToAbsent) {
    return VacationQuotasCompanion(
      year: Value(year),
      totalDays: Value(totalDays),
      rolloverDays: Value(rolloverDays),
      rolloverDeadline: rolloverDeadline == null && nullToAbsent
          ? const Value.absent()
          : Value(rolloverDeadline),
      updatedAt: Value(updatedAt),
    );
  }

  factory VacationQuota.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VacationQuota(
      year: serializer.fromJson<int>(json['year']),
      totalDays: serializer.fromJson<double>(json['totalDays']),
      rolloverDays: serializer.fromJson<double>(json['rolloverDays']),
      rolloverDeadline: serializer.fromJson<DateTime?>(
        json['rolloverDeadline'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'year': serializer.toJson<int>(year),
      'totalDays': serializer.toJson<double>(totalDays),
      'rolloverDays': serializer.toJson<double>(rolloverDays),
      'rolloverDeadline': serializer.toJson<DateTime?>(rolloverDeadline),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VacationQuota copyWith({
    int? year,
    double? totalDays,
    double? rolloverDays,
    Value<DateTime?> rolloverDeadline = const Value.absent(),
    DateTime? updatedAt,
  }) => VacationQuota(
    year: year ?? this.year,
    totalDays: totalDays ?? this.totalDays,
    rolloverDays: rolloverDays ?? this.rolloverDays,
    rolloverDeadline: rolloverDeadline.present
        ? rolloverDeadline.value
        : this.rolloverDeadline,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VacationQuota copyWithCompanion(VacationQuotasCompanion data) {
    return VacationQuota(
      year: data.year.present ? data.year.value : this.year,
      totalDays: data.totalDays.present ? data.totalDays.value : this.totalDays,
      rolloverDays: data.rolloverDays.present
          ? data.rolloverDays.value
          : this.rolloverDays,
      rolloverDeadline: data.rolloverDeadline.present
          ? data.rolloverDeadline.value
          : this.rolloverDeadline,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VacationQuota(')
          ..write('year: $year, ')
          ..write('totalDays: $totalDays, ')
          ..write('rolloverDays: $rolloverDays, ')
          ..write('rolloverDeadline: $rolloverDeadline, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(year, totalDays, rolloverDays, rolloverDeadline, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VacationQuota &&
          other.year == this.year &&
          other.totalDays == this.totalDays &&
          other.rolloverDays == this.rolloverDays &&
          other.rolloverDeadline == this.rolloverDeadline &&
          other.updatedAt == this.updatedAt);
}

class VacationQuotasCompanion extends UpdateCompanion<VacationQuota> {
  final Value<int> year;
  final Value<double> totalDays;
  final Value<double> rolloverDays;
  final Value<DateTime?> rolloverDeadline;
  final Value<DateTime> updatedAt;
  const VacationQuotasCompanion({
    this.year = const Value.absent(),
    this.totalDays = const Value.absent(),
    this.rolloverDays = const Value.absent(),
    this.rolloverDeadline = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  VacationQuotasCompanion.insert({
    this.year = const Value.absent(),
    this.totalDays = const Value.absent(),
    this.rolloverDays = const Value.absent(),
    this.rolloverDeadline = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<VacationQuota> custom({
    Expression<int>? year,
    Expression<double>? totalDays,
    Expression<double>? rolloverDays,
    Expression<DateTime>? rolloverDeadline,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (year != null) 'year': year,
      if (totalDays != null) 'total_days': totalDays,
      if (rolloverDays != null) 'rollover_days': rolloverDays,
      if (rolloverDeadline != null) 'rollover_deadline': rolloverDeadline,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  VacationQuotasCompanion copyWith({
    Value<int>? year,
    Value<double>? totalDays,
    Value<double>? rolloverDays,
    Value<DateTime?>? rolloverDeadline,
    Value<DateTime>? updatedAt,
  }) {
    return VacationQuotasCompanion(
      year: year ?? this.year,
      totalDays: totalDays ?? this.totalDays,
      rolloverDays: rolloverDays ?? this.rolloverDays,
      rolloverDeadline: rolloverDeadline ?? this.rolloverDeadline,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (totalDays.present) {
      map['total_days'] = Variable<double>(totalDays.value);
    }
    if (rolloverDays.present) {
      map['rollover_days'] = Variable<double>(rolloverDays.value);
    }
    if (rolloverDeadline.present) {
      map['rollover_deadline'] = Variable<DateTime>(rolloverDeadline.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VacationQuotasCompanion(')
          ..write('year: $year, ')
          ..write('totalDays: $totalDays, ')
          ..write('rolloverDays: $rolloverDays, ')
          ..write('rolloverDeadline: $rolloverDeadline, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _effectiveFromMeta = const VerificationMeta(
    'effectiveFrom',
  );
  @override
  late final GeneratedColumn<DateTime> effectiveFrom =
      GeneratedColumn<DateTime>(
        'effective_from',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _weeklyHoursMeta = const VerificationMeta(
    'weeklyHours',
  );
  @override
  late final GeneratedColumn<double> weeklyHours = GeneratedColumn<double>(
    'weekly_hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(40),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<int>, String> workDays =
      GeneratedColumn<String>(
        'work_days',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('1,2,3,4,5'),
      ).withConverter<List<int>>($AppSettingsTable.$converterworkDays);
  static const VerificationMeta _minSessionMinutesMeta = const VerificationMeta(
    'minSessionMinutes',
  );
  @override
  late final GeneratedColumn<int> minSessionMinutes = GeneratedColumn<int>(
    'min_session_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _autoBreakEnabledMeta = const VerificationMeta(
    'autoBreakEnabled',
  );
  @override
  late final GeneratedColumn<bool> autoBreakEnabled = GeneratedColumn<bool>(
    'auto_break_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_break_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _restrictCheckinMeta = const VerificationMeta(
    'restrictCheckin',
  );
  @override
  late final GeneratedColumn<bool> restrictCheckin = GeneratedColumn<bool>(
    'restrict_checkin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("restrict_checkin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    effectiveFrom,
    weeklyHours,
    workDays,
    minSessionMinutes,
    autoBreakEnabled,
    restrictCheckin,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('effective_from')) {
      context.handle(
        _effectiveFromMeta,
        effectiveFrom.isAcceptableOrUnknown(
          data['effective_from']!,
          _effectiveFromMeta,
        ),
      );
    }
    if (data.containsKey('weekly_hours')) {
      context.handle(
        _weeklyHoursMeta,
        weeklyHours.isAcceptableOrUnknown(
          data['weekly_hours']!,
          _weeklyHoursMeta,
        ),
      );
    }
    if (data.containsKey('min_session_minutes')) {
      context.handle(
        _minSessionMinutesMeta,
        minSessionMinutes.isAcceptableOrUnknown(
          data['min_session_minutes']!,
          _minSessionMinutesMeta,
        ),
      );
    }
    if (data.containsKey('auto_break_enabled')) {
      context.handle(
        _autoBreakEnabledMeta,
        autoBreakEnabled.isAcceptableOrUnknown(
          data['auto_break_enabled']!,
          _autoBreakEnabledMeta,
        ),
      );
    }
    if (data.containsKey('restrict_checkin')) {
      context.handle(
        _restrictCheckinMeta,
        restrictCheckin.isAcceptableOrUnknown(
          data['restrict_checkin']!,
          _restrictCheckinMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      effectiveFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effective_from'],
      )!,
      weeklyHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weekly_hours'],
      )!,
      workDays: $AppSettingsTable.$converterworkDays.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}work_days'],
        )!,
      ),
      minSessionMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_session_minutes'],
      )!,
      autoBreakEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_break_enabled'],
      )!,
      restrictCheckin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}restrict_checkin'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<int>, String> $converterworkDays =
      const WeekdayListConverter();
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String id;
  final DateTime effectiveFrom;
  final double weeklyHours;

  /// ISO-8601 weekday numbers (1=Mon..7=Sun), default Mon-Fri.
  final List<int> workDays;
  final int minSessionMinutes;
  final bool autoBreakEnabled;
  final bool restrictCheckin;
  final DateTime createdAt;
  const AppSetting({
    required this.id,
    required this.effectiveFrom,
    required this.weeklyHours,
    required this.workDays,
    required this.minSessionMinutes,
    required this.autoBreakEnabled,
    required this.restrictCheckin,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['effective_from'] = Variable<DateTime>(effectiveFrom);
    map['weekly_hours'] = Variable<double>(weeklyHours);
    {
      map['work_days'] = Variable<String>(
        $AppSettingsTable.$converterworkDays.toSql(workDays),
      );
    }
    map['min_session_minutes'] = Variable<int>(minSessionMinutes);
    map['auto_break_enabled'] = Variable<bool>(autoBreakEnabled);
    map['restrict_checkin'] = Variable<bool>(restrictCheckin);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      effectiveFrom: Value(effectiveFrom),
      weeklyHours: Value(weeklyHours),
      workDays: Value(workDays),
      minSessionMinutes: Value(minSessionMinutes),
      autoBreakEnabled: Value(autoBreakEnabled),
      restrictCheckin: Value(restrictCheckin),
      createdAt: Value(createdAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<String>(json['id']),
      effectiveFrom: serializer.fromJson<DateTime>(json['effectiveFrom']),
      weeklyHours: serializer.fromJson<double>(json['weeklyHours']),
      workDays: serializer.fromJson<List<int>>(json['workDays']),
      minSessionMinutes: serializer.fromJson<int>(json['minSessionMinutes']),
      autoBreakEnabled: serializer.fromJson<bool>(json['autoBreakEnabled']),
      restrictCheckin: serializer.fromJson<bool>(json['restrictCheckin']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'effectiveFrom': serializer.toJson<DateTime>(effectiveFrom),
      'weeklyHours': serializer.toJson<double>(weeklyHours),
      'workDays': serializer.toJson<List<int>>(workDays),
      'minSessionMinutes': serializer.toJson<int>(minSessionMinutes),
      'autoBreakEnabled': serializer.toJson<bool>(autoBreakEnabled),
      'restrictCheckin': serializer.toJson<bool>(restrictCheckin),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AppSetting copyWith({
    String? id,
    DateTime? effectiveFrom,
    double? weeklyHours,
    List<int>? workDays,
    int? minSessionMinutes,
    bool? autoBreakEnabled,
    bool? restrictCheckin,
    DateTime? createdAt,
  }) => AppSetting(
    id: id ?? this.id,
    effectiveFrom: effectiveFrom ?? this.effectiveFrom,
    weeklyHours: weeklyHours ?? this.weeklyHours,
    workDays: workDays ?? this.workDays,
    minSessionMinutes: minSessionMinutes ?? this.minSessionMinutes,
    autoBreakEnabled: autoBreakEnabled ?? this.autoBreakEnabled,
    restrictCheckin: restrictCheckin ?? this.restrictCheckin,
    createdAt: createdAt ?? this.createdAt,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      weeklyHours: data.weeklyHours.present
          ? data.weeklyHours.value
          : this.weeklyHours,
      workDays: data.workDays.present ? data.workDays.value : this.workDays,
      minSessionMinutes: data.minSessionMinutes.present
          ? data.minSessionMinutes.value
          : this.minSessionMinutes,
      autoBreakEnabled: data.autoBreakEnabled.present
          ? data.autoBreakEnabled.value
          : this.autoBreakEnabled,
      restrictCheckin: data.restrictCheckin.present
          ? data.restrictCheckin.value
          : this.restrictCheckin,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('weeklyHours: $weeklyHours, ')
          ..write('workDays: $workDays, ')
          ..write('minSessionMinutes: $minSessionMinutes, ')
          ..write('autoBreakEnabled: $autoBreakEnabled, ')
          ..write('restrictCheckin: $restrictCheckin, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    effectiveFrom,
    weeklyHours,
    workDays,
    minSessionMinutes,
    autoBreakEnabled,
    restrictCheckin,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.effectiveFrom == this.effectiveFrom &&
          other.weeklyHours == this.weeklyHours &&
          other.workDays == this.workDays &&
          other.minSessionMinutes == this.minSessionMinutes &&
          other.autoBreakEnabled == this.autoBreakEnabled &&
          other.restrictCheckin == this.restrictCheckin &&
          other.createdAt == this.createdAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> id;
  final Value<DateTime> effectiveFrom;
  final Value<double> weeklyHours;
  final Value<List<int>> workDays;
  final Value<int> minSessionMinutes;
  final Value<bool> autoBreakEnabled;
  final Value<bool> restrictCheckin;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.weeklyHours = const Value.absent(),
    this.workDays = const Value.absent(),
    this.minSessionMinutes = const Value.absent(),
    this.autoBreakEnabled = const Value.absent(),
    this.restrictCheckin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.weeklyHours = const Value.absent(),
    this.workDays = const Value.absent(),
    this.minSessionMinutes = const Value.absent(),
    this.autoBreakEnabled = const Value.absent(),
    this.restrictCheckin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<String>? id,
    Expression<DateTime>? effectiveFrom,
    Expression<double>? weeklyHours,
    Expression<String>? workDays,
    Expression<int>? minSessionMinutes,
    Expression<bool>? autoBreakEnabled,
    Expression<bool>? restrictCheckin,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (weeklyHours != null) 'weekly_hours': weeklyHours,
      if (workDays != null) 'work_days': workDays,
      if (minSessionMinutes != null) 'min_session_minutes': minSessionMinutes,
      if (autoBreakEnabled != null) 'auto_break_enabled': autoBreakEnabled,
      if (restrictCheckin != null) 'restrict_checkin': restrictCheckin,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? effectiveFrom,
    Value<double>? weeklyHours,
    Value<List<int>>? workDays,
    Value<int>? minSessionMinutes,
    Value<bool>? autoBreakEnabled,
    Value<bool>? restrictCheckin,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      workDays: workDays ?? this.workDays,
      minSessionMinutes: minSessionMinutes ?? this.minSessionMinutes,
      autoBreakEnabled: autoBreakEnabled ?? this.autoBreakEnabled,
      restrictCheckin: restrictCheckin ?? this.restrictCheckin,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<DateTime>(effectiveFrom.value);
    }
    if (weeklyHours.present) {
      map['weekly_hours'] = Variable<double>(weeklyHours.value);
    }
    if (workDays.present) {
      map['work_days'] = Variable<String>(
        $AppSettingsTable.$converterworkDays.toSql(workDays.value),
      );
    }
    if (minSessionMinutes.present) {
      map['min_session_minutes'] = Variable<int>(minSessionMinutes.value);
    }
    if (autoBreakEnabled.present) {
      map['auto_break_enabled'] = Variable<bool>(autoBreakEnabled.value);
    }
    if (restrictCheckin.present) {
      map['restrict_checkin'] = Variable<bool>(restrictCheckin.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('weeklyHours: $weeklyHours, ')
          ..write('workDays: $workDays, ')
          ..write('minSessionMinutes: $minSessionMinutes, ')
          ..write('autoBreakEnabled: $autoBreakEnabled, ')
          ..write('restrictCheckin: $restrictCheckin, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogEntriesTable extends AuditLogEntries
    with TableInfo<$AuditLogEntriesTable, AuditLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _oldValueMeta = const VerificationMeta(
    'oldValue',
  );
  @override
  late final GeneratedColumn<String> oldValue = GeneratedColumn<String>(
    'old_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newValueMeta = const VerificationMeta(
    'newValue',
  );
  @override
  late final GeneratedColumn<String> newValue = GeneratedColumn<String>(
    'new_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    action,
    entityType,
    entityId,
    oldValue,
    newValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
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
    }
    if (data.containsKey('old_value')) {
      context.handle(
        _oldValueMeta,
        oldValue.isAcceptableOrUnknown(data['old_value']!, _oldValueMeta),
      );
    }
    if (data.containsKey('new_value')) {
      context.handle(
        _newValueMeta,
        newValue.isAcceptableOrUnknown(data['new_value']!, _newValueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      oldValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}old_value'],
      ),
      newValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_value'],
      ),
    );
  }

  @override
  $AuditLogEntriesTable createAlias(String alias) {
    return $AuditLogEntriesTable(attachedDatabase, alias);
  }
}

class AuditLogEntry extends DataClass implements Insertable<AuditLogEntry> {
  final String id;
  final DateTime timestamp;
  final String action;
  final String entityType;
  final String? entityId;

  /// JSON-encoded snapshot of the entity before/after the change.
  final String? oldValue;
  final String? newValue;
  const AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.entityType,
    this.entityId,
    this.oldValue,
    this.newValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['action'] = Variable<String>(action);
    map['entity_type'] = Variable<String>(entityType);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    if (!nullToAbsent || oldValue != null) {
      map['old_value'] = Variable<String>(oldValue);
    }
    if (!nullToAbsent || newValue != null) {
      map['new_value'] = Variable<String>(newValue);
    }
    return map;
  }

  AuditLogEntriesCompanion toCompanion(bool nullToAbsent) {
    return AuditLogEntriesCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      action: Value(action),
      entityType: Value(entityType),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      oldValue: oldValue == null && nullToAbsent
          ? const Value.absent()
          : Value(oldValue),
      newValue: newValue == null && nullToAbsent
          ? const Value.absent()
          : Value(newValue),
    );
  }

  factory AuditLogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogEntry(
      id: serializer.fromJson<String>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      action: serializer.fromJson<String>(json['action']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      oldValue: serializer.fromJson<String?>(json['oldValue']),
      newValue: serializer.fromJson<String?>(json['newValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'action': serializer.toJson<String>(action),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String?>(entityId),
      'oldValue': serializer.toJson<String?>(oldValue),
      'newValue': serializer.toJson<String?>(newValue),
    };
  }

  AuditLogEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? action,
    String? entityType,
    Value<String?> entityId = const Value.absent(),
    Value<String?> oldValue = const Value.absent(),
    Value<String?> newValue = const Value.absent(),
  }) => AuditLogEntry(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    action: action ?? this.action,
    entityType: entityType ?? this.entityType,
    entityId: entityId.present ? entityId.value : this.entityId,
    oldValue: oldValue.present ? oldValue.value : this.oldValue,
    newValue: newValue.present ? newValue.value : this.newValue,
  );
  AuditLogEntry copyWithCompanion(AuditLogEntriesCompanion data) {
    return AuditLogEntry(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      action: data.action.present ? data.action.value : this.action,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      oldValue: data.oldValue.present ? data.oldValue.value : this.oldValue,
      newValue: data.newValue.present ? data.newValue.value : this.newValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogEntry(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    action,
    entityType,
    entityId,
    oldValue,
    newValue,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogEntry &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.action == this.action &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.oldValue == this.oldValue &&
          other.newValue == this.newValue);
}

class AuditLogEntriesCompanion extends UpdateCompanion<AuditLogEntry> {
  final Value<String> id;
  final Value<DateTime> timestamp;
  final Value<String> action;
  final Value<String> entityType;
  final Value<String?> entityId;
  final Value<String?> oldValue;
  final Value<String?> newValue;
  final Value<int> rowid;
  const AuditLogEntriesCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.action = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    required String action,
    required String entityType,
    this.entityId = const Value.absent(),
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : action = Value(action),
       entityType = Value(entityType);
  static Insertable<AuditLogEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? action,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? oldValue,
    Expression<String>? newValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (action != null) 'action': action,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (oldValue != null) 'old_value': oldValue,
      if (newValue != null) 'new_value': newValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? timestamp,
    Value<String>? action,
    Value<String>? entityType,
    Value<String?>? entityId,
    Value<String?>? oldValue,
    Value<String?>? newValue,
    Value<int>? rowid,
  }) {
    return AuditLogEntriesCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (oldValue.present) {
      map['old_value'] = Variable<String>(oldValue.value);
    }
    if (newValue.present) {
      map['new_value'] = Variable<String>(newValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('action: $action, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DayEntriesTable dayEntries = $DayEntriesTable(this);
  late final $WorkSessionsTable workSessions = $WorkSessionsTable(this);
  late final $BreakEntriesTable breakEntries = $BreakEntriesTable(this);
  late final $LeaveEntriesTable leaveEntries = $LeaveEntriesTable(this);
  late final $PublicHolidaysTable publicHolidays = $PublicHolidaysTable(this);
  late final $BalanceSnapshotsTable balanceSnapshots = $BalanceSnapshotsTable(
    this,
  );
  late final $VacationQuotasTable vacationQuotas = $VacationQuotasTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $AuditLogEntriesTable auditLogEntries = $AuditLogEntriesTable(
    this,
  );
  late final WorkSessionDao workSessionDao = WorkSessionDao(
    this as AppDatabase,
  );
  late final BreakEntryDao breakEntryDao = BreakEntryDao(this as AppDatabase);
  late final LeaveEntryDao leaveEntryDao = LeaveEntryDao(this as AppDatabase);
  late final PublicHolidayDao publicHolidayDao = PublicHolidayDao(
    this as AppDatabase,
  );
  late final DayEntryDao dayEntryDao = DayEntryDao(this as AppDatabase);
  late final BalanceSnapshotDao balanceSnapshotDao = BalanceSnapshotDao(
    this as AppDatabase,
  );
  late final VacationQuotaDao vacationQuotaDao = VacationQuotaDao(
    this as AppDatabase,
  );
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final AuditLogDao auditLogDao = AuditLogDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dayEntries,
    workSessions,
    breakEntries,
    leaveEntries,
    publicHolidays,
    balanceSnapshots,
    vacationQuotas,
    appSettings,
    auditLogEntries,
  ];
}

typedef $$DayEntriesTableCreateCompanionBuilder =
    DayEntriesCompanion Function({
      required DateTime date,
      Value<double> netWorkedHours,
      Value<double> leaveHours,
      Value<double> targetHours,
      Value<double> balanceDelta,
      Value<bool> autoBreakOverridden,
      Value<String?> notes,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$DayEntriesTableUpdateCompanionBuilder =
    DayEntriesCompanion Function({
      Value<DateTime> date,
      Value<double> netWorkedHours,
      Value<double> leaveHours,
      Value<double> targetHours,
      Value<double> balanceDelta,
      Value<bool> autoBreakOverridden,
      Value<String?> notes,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$DayEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $DayEntriesTable, DayEntry> {
  $$DayEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkSessionsTable, List<WorkSession>>
  _workSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workSessions,
    aliasName: $_aliasNameGenerator(db.dayEntries.date, db.workSessions.date),
  );

  $$WorkSessionsTableProcessedTableManager get workSessionsRefs {
    final manager = $$WorkSessionsTableTableManager(
      $_db,
      $_db.workSessions,
    ).filter((f) => f.date.date.sqlEquals($_itemColumn<DateTime>('date')!));

    final cache = $_typedResult.readTableOrNull(_workSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BreakEntriesTable, List<BreakEntry>>
  _breakEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.breakEntries,
    aliasName: $_aliasNameGenerator(db.dayEntries.date, db.breakEntries.date),
  );

  $$BreakEntriesTableProcessedTableManager get breakEntriesRefs {
    final manager = $$BreakEntriesTableTableManager(
      $_db,
      $_db.breakEntries,
    ).filter((f) => f.date.date.sqlEquals($_itemColumn<DateTime>('date')!));

    final cache = $_typedResult.readTableOrNull(_breakEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LeaveEntriesTable, List<LeaveEntry>>
  _leaveEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.leaveEntries,
    aliasName: $_aliasNameGenerator(db.dayEntries.date, db.leaveEntries.date),
  );

  $$LeaveEntriesTableProcessedTableManager get leaveEntriesRefs {
    final manager = $$LeaveEntriesTableTableManager(
      $_db,
      $_db.leaveEntries,
    ).filter((f) => f.date.date.sqlEquals($_itemColumn<DateTime>('date')!));

    final cache = $_typedResult.readTableOrNull(_leaveEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DayEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DayEntriesTable> {
  $$DayEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get netWorkedHours => $composableBuilder(
    column: $table.netWorkedHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get leaveHours => $composableBuilder(
    column: $table.leaveHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetHours => $composableBuilder(
    column: $table.targetHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balanceDelta => $composableBuilder(
    column: $table.balanceDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoBreakOverridden => $composableBuilder(
    column: $table.autoBreakOverridden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> workSessionsRefs(
    Expression<bool> Function($$WorkSessionsTableFilterComposer f) f,
  ) {
    final $$WorkSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.workSessions,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkSessionsTableFilterComposer(
            $db: $db,
            $table: $db.workSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> breakEntriesRefs(
    Expression<bool> Function($$BreakEntriesTableFilterComposer f) f,
  ) {
    final $$BreakEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.breakEntries,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BreakEntriesTableFilterComposer(
            $db: $db,
            $table: $db.breakEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> leaveEntriesRefs(
    Expression<bool> Function($$LeaveEntriesTableFilterComposer f) f,
  ) {
    final $$LeaveEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.leaveEntries,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeaveEntriesTableFilterComposer(
            $db: $db,
            $table: $db.leaveEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DayEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DayEntriesTable> {
  $$DayEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get netWorkedHours => $composableBuilder(
    column: $table.netWorkedHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get leaveHours => $composableBuilder(
    column: $table.leaveHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetHours => $composableBuilder(
    column: $table.targetHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balanceDelta => $composableBuilder(
    column: $table.balanceDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoBreakOverridden => $composableBuilder(
    column: $table.autoBreakOverridden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayEntriesTable> {
  $$DayEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get netWorkedHours => $composableBuilder(
    column: $table.netWorkedHours,
    builder: (column) => column,
  );

  GeneratedColumn<double> get leaveHours => $composableBuilder(
    column: $table.leaveHours,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetHours => $composableBuilder(
    column: $table.targetHours,
    builder: (column) => column,
  );

  GeneratedColumn<double> get balanceDelta => $composableBuilder(
    column: $table.balanceDelta,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoBreakOverridden => $composableBuilder(
    column: $table.autoBreakOverridden,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> workSessionsRefs<T extends Object>(
    Expression<T> Function($$WorkSessionsTableAnnotationComposer a) f,
  ) {
    final $$WorkSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.workSessions,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.workSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> breakEntriesRefs<T extends Object>(
    Expression<T> Function($$BreakEntriesTableAnnotationComposer a) f,
  ) {
    final $$BreakEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.breakEntries,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BreakEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.breakEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> leaveEntriesRefs<T extends Object>(
    Expression<T> Function($$LeaveEntriesTableAnnotationComposer a) f,
  ) {
    final $$LeaveEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.leaveEntries,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LeaveEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.leaveEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DayEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayEntriesTable,
          DayEntry,
          $$DayEntriesTableFilterComposer,
          $$DayEntriesTableOrderingComposer,
          $$DayEntriesTableAnnotationComposer,
          $$DayEntriesTableCreateCompanionBuilder,
          $$DayEntriesTableUpdateCompanionBuilder,
          (DayEntry, $$DayEntriesTableReferences),
          DayEntry,
          PrefetchHooks Function({
            bool workSessionsRefs,
            bool breakEntriesRefs,
            bool leaveEntriesRefs,
          })
        > {
  $$DayEntriesTableTableManager(_$AppDatabase db, $DayEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> date = const Value.absent(),
                Value<double> netWorkedHours = const Value.absent(),
                Value<double> leaveHours = const Value.absent(),
                Value<double> targetHours = const Value.absent(),
                Value<double> balanceDelta = const Value.absent(),
                Value<bool> autoBreakOverridden = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayEntriesCompanion(
                date: date,
                netWorkedHours: netWorkedHours,
                leaveHours: leaveHours,
                targetHours: targetHours,
                balanceDelta: balanceDelta,
                autoBreakOverridden: autoBreakOverridden,
                notes: notes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime date,
                Value<double> netWorkedHours = const Value.absent(),
                Value<double> leaveHours = const Value.absent(),
                Value<double> targetHours = const Value.absent(),
                Value<double> balanceDelta = const Value.absent(),
                Value<bool> autoBreakOverridden = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayEntriesCompanion.insert(
                date: date,
                netWorkedHours: netWorkedHours,
                leaveHours: leaveHours,
                targetHours: targetHours,
                balanceDelta: balanceDelta,
                autoBreakOverridden: autoBreakOverridden,
                notes: notes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DayEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workSessionsRefs = false,
                breakEntriesRefs = false,
                leaveEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workSessionsRefs) db.workSessions,
                    if (breakEntriesRefs) db.breakEntries,
                    if (leaveEntriesRefs) db.leaveEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workSessionsRefs)
                        await $_getPrefetchedData<
                          DayEntry,
                          $DayEntriesTable,
                          WorkSession
                        >(
                          currentTable: table,
                          referencedTable: $$DayEntriesTableReferences
                              ._workSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DayEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).workSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.date == item.date,
                              ),
                          typedResults: items,
                        ),
                      if (breakEntriesRefs)
                        await $_getPrefetchedData<
                          DayEntry,
                          $DayEntriesTable,
                          BreakEntry
                        >(
                          currentTable: table,
                          referencedTable: $$DayEntriesTableReferences
                              ._breakEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DayEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).breakEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.date == item.date,
                              ),
                          typedResults: items,
                        ),
                      if (leaveEntriesRefs)
                        await $_getPrefetchedData<
                          DayEntry,
                          $DayEntriesTable,
                          LeaveEntry
                        >(
                          currentTable: table,
                          referencedTable: $$DayEntriesTableReferences
                              ._leaveEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DayEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).leaveEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.date == item.date,
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

typedef $$DayEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayEntriesTable,
      DayEntry,
      $$DayEntriesTableFilterComposer,
      $$DayEntriesTableOrderingComposer,
      $$DayEntriesTableAnnotationComposer,
      $$DayEntriesTableCreateCompanionBuilder,
      $$DayEntriesTableUpdateCompanionBuilder,
      (DayEntry, $$DayEntriesTableReferences),
      DayEntry,
      PrefetchHooks Function({
        bool workSessionsRefs,
        bool breakEntriesRefs,
        bool leaveEntriesRefs,
      })
    >;
typedef $$WorkSessionsTableCreateCompanionBuilder =
    WorkSessionsCompanion Function({
      Value<String> id,
      required DateTime date,
      required DateTime startTime,
      Value<DateTime?> endTime,
      required SessionStatus status,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$WorkSessionsTableUpdateCompanionBuilder =
    WorkSessionsCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<SessionStatus> status,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$WorkSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkSessionsTable, WorkSession> {
  $$WorkSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DayEntriesTable _dateTable(_$AppDatabase db) =>
      db.dayEntries.createAlias(
        $_aliasNameGenerator(db.workSessions.date, db.dayEntries.date),
      );

  $$DayEntriesTableProcessedTableManager get date {
    final $_column = $_itemColumn<DateTime>('date')!;

    final manager = $$DayEntriesTableTableManager(
      $_db,
      $_db.dayEntries,
    ).filter((f) => f.date.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkSessionsTable> {
  $$WorkSessionsTableFilterComposer({
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

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionStatus, SessionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
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

  $$DayEntriesTableFilterComposer get date {
    final $$DayEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.dayEntries,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayEntriesTableFilterComposer(
            $db: $db,
            $table: $db.dayEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkSessionsTable> {
  $$WorkSessionsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
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

  $$DayEntriesTableOrderingComposer get date {
    final $$DayEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.dayEntries,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.dayEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkSessionsTable> {
  $$WorkSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DayEntriesTableAnnotationComposer get date {
    final $$DayEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.dayEntries,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.dayEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkSessionsTable,
          WorkSession,
          $$WorkSessionsTableFilterComposer,
          $$WorkSessionsTableOrderingComposer,
          $$WorkSessionsTableAnnotationComposer,
          $$WorkSessionsTableCreateCompanionBuilder,
          $$WorkSessionsTableUpdateCompanionBuilder,
          (WorkSession, $$WorkSessionsTableReferences),
          WorkSession,
          PrefetchHooks Function({bool date})
        > {
  $$WorkSessionsTableTableManager(_$AppDatabase db, $WorkSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<SessionStatus> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkSessionsCompanion(
                id: id,
                date: date,
                startTime: startTime,
                endTime: endTime,
                status: status,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required DateTime date,
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                required SessionStatus status,
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkSessionsCompanion.insert(
                id: id,
                date: date,
                startTime: startTime,
                endTime: endTime,
                status: status,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WorkSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({date = false}) {
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
                    if (date) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.date,
                                referencedTable: $$WorkSessionsTableReferences
                                    ._dateTable(db),
                                referencedColumn: $$WorkSessionsTableReferences
                                    ._dateTable(db)
                                    .date,
                              )
                              as T;
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

typedef $$WorkSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkSessionsTable,
      WorkSession,
      $$WorkSessionsTableFilterComposer,
      $$WorkSessionsTableOrderingComposer,
      $$WorkSessionsTableAnnotationComposer,
      $$WorkSessionsTableCreateCompanionBuilder,
      $$WorkSessionsTableUpdateCompanionBuilder,
      (WorkSession, $$WorkSessionsTableReferences),
      WorkSession,
      PrefetchHooks Function({bool date})
    >;
typedef $$BreakEntriesTableCreateCompanionBuilder =
    BreakEntriesCompanion Function({
      Value<String> id,
      required DateTime date,
      required DateTime startTime,
      required DateTime endTime,
      required BreakType type,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BreakEntriesTableUpdateCompanionBuilder =
    BreakEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<DateTime> startTime,
      Value<DateTime> endTime,
      Value<BreakType> type,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BreakEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $BreakEntriesTable, BreakEntry> {
  $$BreakEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DayEntriesTable _dateTable(_$AppDatabase db) =>
      db.dayEntries.createAlias(
        $_aliasNameGenerator(db.breakEntries.date, db.dayEntries.date),
      );

  $$DayEntriesTableProcessedTableManager get date {
    final $_column = $_itemColumn<DateTime>('date')!;

    final manager = $$DayEntriesTableTableManager(
      $_db,
      $_db.dayEntries,
    ).filter((f) => f.date.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BreakEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BreakEntriesTable> {
  $$BreakEntriesTableFilterComposer({
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

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BreakType, BreakType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DayEntriesTableFilterComposer get date {
    final $$DayEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.dayEntries,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayEntriesTableFilterComposer(
            $db: $db,
            $table: $db.dayEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BreakEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BreakEntriesTable> {
  $$BreakEntriesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
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

  $$DayEntriesTableOrderingComposer get date {
    final $$DayEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.dayEntries,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.dayEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BreakEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BreakEntriesTable> {
  $$BreakEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BreakType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DayEntriesTableAnnotationComposer get date {
    final $$DayEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.dayEntries,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.dayEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BreakEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BreakEntriesTable,
          BreakEntry,
          $$BreakEntriesTableFilterComposer,
          $$BreakEntriesTableOrderingComposer,
          $$BreakEntriesTableAnnotationComposer,
          $$BreakEntriesTableCreateCompanionBuilder,
          $$BreakEntriesTableUpdateCompanionBuilder,
          (BreakEntry, $$BreakEntriesTableReferences),
          BreakEntry,
          PrefetchHooks Function({bool date})
        > {
  $$BreakEntriesTableTableManager(_$AppDatabase db, $BreakEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BreakEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BreakEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BreakEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime> endTime = const Value.absent(),
                Value<BreakType> type = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BreakEntriesCompanion(
                id: id,
                date: date,
                startTime: startTime,
                endTime: endTime,
                type: type,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required DateTime date,
                required DateTime startTime,
                required DateTime endTime,
                required BreakType type,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BreakEntriesCompanion.insert(
                id: id,
                date: date,
                startTime: startTime,
                endTime: endTime,
                type: type,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BreakEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({date = false}) {
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
                    if (date) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.date,
                                referencedTable: $$BreakEntriesTableReferences
                                    ._dateTable(db),
                                referencedColumn: $$BreakEntriesTableReferences
                                    ._dateTable(db)
                                    .date,
                              )
                              as T;
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

typedef $$BreakEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BreakEntriesTable,
      BreakEntry,
      $$BreakEntriesTableFilterComposer,
      $$BreakEntriesTableOrderingComposer,
      $$BreakEntriesTableAnnotationComposer,
      $$BreakEntriesTableCreateCompanionBuilder,
      $$BreakEntriesTableUpdateCompanionBuilder,
      (BreakEntry, $$BreakEntriesTableReferences),
      BreakEntry,
      PrefetchHooks Function({bool date})
    >;
typedef $$LeaveEntriesTableCreateCompanionBuilder =
    LeaveEntriesCompanion Function({
      Value<String> id,
      required DateTime date,
      required LeaveType type,
      required double hours,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LeaveEntriesTableUpdateCompanionBuilder =
    LeaveEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<LeaveType> type,
      Value<double> hours,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LeaveEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LeaveEntriesTable, LeaveEntry> {
  $$LeaveEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DayEntriesTable _dateTable(_$AppDatabase db) =>
      db.dayEntries.createAlias(
        $_aliasNameGenerator(db.leaveEntries.date, db.dayEntries.date),
      );

  $$DayEntriesTableProcessedTableManager get date {
    final $_column = $_itemColumn<DateTime>('date')!;

    final manager = $$DayEntriesTableTableManager(
      $_db,
      $_db.dayEntries,
    ).filter((f) => f.date.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LeaveEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LeaveEntriesTable> {
  $$LeaveEntriesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<LeaveType, LeaveType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
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

  $$DayEntriesTableFilterComposer get date {
    final $$DayEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.dayEntries,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayEntriesTableFilterComposer(
            $db: $db,
            $table: $db.dayEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LeaveEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LeaveEntriesTable> {
  $$LeaveEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
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

  $$DayEntriesTableOrderingComposer get date {
    final $$DayEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.dayEntries,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.dayEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LeaveEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LeaveEntriesTable> {
  $$LeaveEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LeaveType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get hours =>
      $composableBuilder(column: $table.hours, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DayEntriesTableAnnotationComposer get date {
    final $$DayEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.date,
      referencedTable: $db.dayEntries,
      getReferencedColumn: (t) => t.date,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.dayEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LeaveEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LeaveEntriesTable,
          LeaveEntry,
          $$LeaveEntriesTableFilterComposer,
          $$LeaveEntriesTableOrderingComposer,
          $$LeaveEntriesTableAnnotationComposer,
          $$LeaveEntriesTableCreateCompanionBuilder,
          $$LeaveEntriesTableUpdateCompanionBuilder,
          (LeaveEntry, $$LeaveEntriesTableReferences),
          LeaveEntry,
          PrefetchHooks Function({bool date})
        > {
  $$LeaveEntriesTableTableManager(_$AppDatabase db, $LeaveEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LeaveEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LeaveEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LeaveEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<LeaveType> type = const Value.absent(),
                Value<double> hours = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LeaveEntriesCompanion(
                id: id,
                date: date,
                type: type,
                hours: hours,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required DateTime date,
                required LeaveType type,
                required double hours,
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LeaveEntriesCompanion.insert(
                id: id,
                date: date,
                type: type,
                hours: hours,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LeaveEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({date = false}) {
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
                    if (date) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.date,
                                referencedTable: $$LeaveEntriesTableReferences
                                    ._dateTable(db),
                                referencedColumn: $$LeaveEntriesTableReferences
                                    ._dateTable(db)
                                    .date,
                              )
                              as T;
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

typedef $$LeaveEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LeaveEntriesTable,
      LeaveEntry,
      $$LeaveEntriesTableFilterComposer,
      $$LeaveEntriesTableOrderingComposer,
      $$LeaveEntriesTableAnnotationComposer,
      $$LeaveEntriesTableCreateCompanionBuilder,
      $$LeaveEntriesTableUpdateCompanionBuilder,
      (LeaveEntry, $$LeaveEntriesTableReferences),
      LeaveEntry,
      PrefetchHooks Function({bool date})
    >;
typedef $$PublicHolidaysTableCreateCompanionBuilder =
    PublicHolidaysCompanion Function({
      required DateTime date,
      required String name,
      Value<double> fraction,
      required HolidaySource source,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$PublicHolidaysTableUpdateCompanionBuilder =
    PublicHolidaysCompanion Function({
      Value<DateTime> date,
      Value<String> name,
      Value<double> fraction,
      Value<HolidaySource> source,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PublicHolidaysTableFilterComposer
    extends Composer<_$AppDatabase, $PublicHolidaysTable> {
  $$PublicHolidaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fraction => $composableBuilder(
    column: $table.fraction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HolidaySource, HolidaySource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PublicHolidaysTableOrderingComposer
    extends Composer<_$AppDatabase, $PublicHolidaysTable> {
  $$PublicHolidaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fraction => $composableBuilder(
    column: $table.fraction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PublicHolidaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $PublicHolidaysTable> {
  $$PublicHolidaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get fraction =>
      $composableBuilder(column: $table.fraction, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HolidaySource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PublicHolidaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PublicHolidaysTable,
          PublicHoliday,
          $$PublicHolidaysTableFilterComposer,
          $$PublicHolidaysTableOrderingComposer,
          $$PublicHolidaysTableAnnotationComposer,
          $$PublicHolidaysTableCreateCompanionBuilder,
          $$PublicHolidaysTableUpdateCompanionBuilder,
          (
            PublicHoliday,
            BaseReferences<_$AppDatabase, $PublicHolidaysTable, PublicHoliday>,
          ),
          PublicHoliday,
          PrefetchHooks Function()
        > {
  $$PublicHolidaysTableTableManager(
    _$AppDatabase db,
    $PublicHolidaysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PublicHolidaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PublicHolidaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PublicHolidaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> date = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> fraction = const Value.absent(),
                Value<HolidaySource> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PublicHolidaysCompanion(
                date: date,
                name: name,
                fraction: fraction,
                source: source,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime date,
                required String name,
                Value<double> fraction = const Value.absent(),
                required HolidaySource source,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PublicHolidaysCompanion.insert(
                date: date,
                name: name,
                fraction: fraction,
                source: source,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PublicHolidaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PublicHolidaysTable,
      PublicHoliday,
      $$PublicHolidaysTableFilterComposer,
      $$PublicHolidaysTableOrderingComposer,
      $$PublicHolidaysTableAnnotationComposer,
      $$PublicHolidaysTableCreateCompanionBuilder,
      $$PublicHolidaysTableUpdateCompanionBuilder,
      (
        PublicHoliday,
        BaseReferences<_$AppDatabase, $PublicHolidaysTable, PublicHoliday>,
      ),
      PublicHoliday,
      PrefetchHooks Function()
    >;
typedef $$BalanceSnapshotsTableCreateCompanionBuilder =
    BalanceSnapshotsCompanion Function({
      required DateTime date,
      required double balance,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BalanceSnapshotsTableUpdateCompanionBuilder =
    BalanceSnapshotsCompanion Function({
      Value<DateTime> date,
      Value<double> balance,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BalanceSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $BalanceSnapshotsTable> {
  $$BalanceSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BalanceSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $BalanceSnapshotsTable> {
  $$BalanceSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BalanceSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BalanceSnapshotsTable> {
  $$BalanceSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BalanceSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BalanceSnapshotsTable,
          BalanceSnapshot,
          $$BalanceSnapshotsTableFilterComposer,
          $$BalanceSnapshotsTableOrderingComposer,
          $$BalanceSnapshotsTableAnnotationComposer,
          $$BalanceSnapshotsTableCreateCompanionBuilder,
          $$BalanceSnapshotsTableUpdateCompanionBuilder,
          (
            BalanceSnapshot,
            BaseReferences<
              _$AppDatabase,
              $BalanceSnapshotsTable,
              BalanceSnapshot
            >,
          ),
          BalanceSnapshot,
          PrefetchHooks Function()
        > {
  $$BalanceSnapshotsTableTableManager(
    _$AppDatabase db,
    $BalanceSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BalanceSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BalanceSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BalanceSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> date = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalanceSnapshotsCompanion(
                date: date,
                balance: balance,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime date,
                required double balance,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalanceSnapshotsCompanion.insert(
                date: date,
                balance: balance,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BalanceSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BalanceSnapshotsTable,
      BalanceSnapshot,
      $$BalanceSnapshotsTableFilterComposer,
      $$BalanceSnapshotsTableOrderingComposer,
      $$BalanceSnapshotsTableAnnotationComposer,
      $$BalanceSnapshotsTableCreateCompanionBuilder,
      $$BalanceSnapshotsTableUpdateCompanionBuilder,
      (
        BalanceSnapshot,
        BaseReferences<_$AppDatabase, $BalanceSnapshotsTable, BalanceSnapshot>,
      ),
      BalanceSnapshot,
      PrefetchHooks Function()
    >;
typedef $$VacationQuotasTableCreateCompanionBuilder =
    VacationQuotasCompanion Function({
      Value<int> year,
      Value<double> totalDays,
      Value<double> rolloverDays,
      Value<DateTime?> rolloverDeadline,
      Value<DateTime> updatedAt,
    });
typedef $$VacationQuotasTableUpdateCompanionBuilder =
    VacationQuotasCompanion Function({
      Value<int> year,
      Value<double> totalDays,
      Value<double> rolloverDays,
      Value<DateTime?> rolloverDeadline,
      Value<DateTime> updatedAt,
    });

class $$VacationQuotasTableFilterComposer
    extends Composer<_$AppDatabase, $VacationQuotasTable> {
  $$VacationQuotasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDays => $composableBuilder(
    column: $table.totalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rolloverDays => $composableBuilder(
    column: $table.rolloverDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get rolloverDeadline => $composableBuilder(
    column: $table.rolloverDeadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VacationQuotasTableOrderingComposer
    extends Composer<_$AppDatabase, $VacationQuotasTable> {
  $$VacationQuotasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDays => $composableBuilder(
    column: $table.totalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rolloverDays => $composableBuilder(
    column: $table.rolloverDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get rolloverDeadline => $composableBuilder(
    column: $table.rolloverDeadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VacationQuotasTableAnnotationComposer
    extends Composer<_$AppDatabase, $VacationQuotasTable> {
  $$VacationQuotasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<double> get totalDays =>
      $composableBuilder(column: $table.totalDays, builder: (column) => column);

  GeneratedColumn<double> get rolloverDays => $composableBuilder(
    column: $table.rolloverDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get rolloverDeadline => $composableBuilder(
    column: $table.rolloverDeadline,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VacationQuotasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VacationQuotasTable,
          VacationQuota,
          $$VacationQuotasTableFilterComposer,
          $$VacationQuotasTableOrderingComposer,
          $$VacationQuotasTableAnnotationComposer,
          $$VacationQuotasTableCreateCompanionBuilder,
          $$VacationQuotasTableUpdateCompanionBuilder,
          (
            VacationQuota,
            BaseReferences<_$AppDatabase, $VacationQuotasTable, VacationQuota>,
          ),
          VacationQuota,
          PrefetchHooks Function()
        > {
  $$VacationQuotasTableTableManager(
    _$AppDatabase db,
    $VacationQuotasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VacationQuotasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VacationQuotasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VacationQuotasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> year = const Value.absent(),
                Value<double> totalDays = const Value.absent(),
                Value<double> rolloverDays = const Value.absent(),
                Value<DateTime?> rolloverDeadline = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => VacationQuotasCompanion(
                year: year,
                totalDays: totalDays,
                rolloverDays: rolloverDays,
                rolloverDeadline: rolloverDeadline,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> year = const Value.absent(),
                Value<double> totalDays = const Value.absent(),
                Value<double> rolloverDays = const Value.absent(),
                Value<DateTime?> rolloverDeadline = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => VacationQuotasCompanion.insert(
                year: year,
                totalDays: totalDays,
                rolloverDays: rolloverDays,
                rolloverDeadline: rolloverDeadline,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VacationQuotasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VacationQuotasTable,
      VacationQuota,
      $$VacationQuotasTableFilterComposer,
      $$VacationQuotasTableOrderingComposer,
      $$VacationQuotasTableAnnotationComposer,
      $$VacationQuotasTableCreateCompanionBuilder,
      $$VacationQuotasTableUpdateCompanionBuilder,
      (
        VacationQuota,
        BaseReferences<_$AppDatabase, $VacationQuotasTable, VacationQuota>,
      ),
      VacationQuota,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> id,
      Value<DateTime> effectiveFrom,
      Value<double> weeklyHours,
      Value<List<int>> workDays,
      Value<int> minSessionMinutes,
      Value<bool> autoBreakEnabled,
      Value<bool> restrictCheckin,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> id,
      Value<DateTime> effectiveFrom,
      Value<double> weeklyHours,
      Value<List<int>> workDays,
      Value<int> minSessionMinutes,
      Value<bool> autoBreakEnabled,
      Value<bool> restrictCheckin,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<DateTime> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weeklyHours => $composableBuilder(
    column: $table.weeklyHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<int>, List<int>, String> get workDays =>
      $composableBuilder(
        column: $table.workDays,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get minSessionMinutes => $composableBuilder(
    column: $table.minSessionMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoBreakEnabled => $composableBuilder(
    column: $table.autoBreakEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get restrictCheckin => $composableBuilder(
    column: $table.restrictCheckin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weeklyHours => $composableBuilder(
    column: $table.weeklyHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workDays => $composableBuilder(
    column: $table.workDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minSessionMinutes => $composableBuilder(
    column: $table.minSessionMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoBreakEnabled => $composableBuilder(
    column: $table.autoBreakEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get restrictCheckin => $composableBuilder(
    column: $table.restrictCheckin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weeklyHours => $composableBuilder(
    column: $table.weeklyHours,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<int>, String> get workDays =>
      $composableBuilder(column: $table.workDays, builder: (column) => column);

  GeneratedColumn<int> get minSessionMinutes => $composableBuilder(
    column: $table.minSessionMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoBreakEnabled => $composableBuilder(
    column: $table.autoBreakEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get restrictCheckin => $composableBuilder(
    column: $table.restrictCheckin,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> effectiveFrom = const Value.absent(),
                Value<double> weeklyHours = const Value.absent(),
                Value<List<int>> workDays = const Value.absent(),
                Value<int> minSessionMinutes = const Value.absent(),
                Value<bool> autoBreakEnabled = const Value.absent(),
                Value<bool> restrictCheckin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                effectiveFrom: effectiveFrom,
                weeklyHours: weeklyHours,
                workDays: workDays,
                minSessionMinutes: minSessionMinutes,
                autoBreakEnabled: autoBreakEnabled,
                restrictCheckin: restrictCheckin,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> effectiveFrom = const Value.absent(),
                Value<double> weeklyHours = const Value.absent(),
                Value<List<int>> workDays = const Value.absent(),
                Value<int> minSessionMinutes = const Value.absent(),
                Value<bool> autoBreakEnabled = const Value.absent(),
                Value<bool> restrictCheckin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                effectiveFrom: effectiveFrom,
                weeklyHours: weeklyHours,
                workDays: workDays,
                minSessionMinutes: minSessionMinutes,
                autoBreakEnabled: autoBreakEnabled,
                restrictCheckin: restrictCheckin,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$AuditLogEntriesTableCreateCompanionBuilder =
    AuditLogEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> timestamp,
      required String action,
      required String entityType,
      Value<String?> entityId,
      Value<String?> oldValue,
      Value<String?> newValue,
      Value<int> rowid,
    });
typedef $$AuditLogEntriesTableUpdateCompanionBuilder =
    AuditLogEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> timestamp,
      Value<String> action,
      Value<String> entityType,
      Value<String?> entityId,
      Value<String?> oldValue,
      Value<String?> newValue,
      Value<int> rowid,
    });

class $$AuditLogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogEntriesTable> {
  $$AuditLogEntriesTableFilterComposer({
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

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
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

  ColumnFilters<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogEntriesTable> {
  $$AuditLogEntriesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
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

  ColumnOrderings<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogEntriesTable> {
  $$AuditLogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get oldValue =>
      $composableBuilder(column: $table.oldValue, builder: (column) => column);

  GeneratedColumn<String> get newValue =>
      $composableBuilder(column: $table.newValue, builder: (column) => column);
}

class $$AuditLogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogEntriesTable,
          AuditLogEntry,
          $$AuditLogEntriesTableFilterComposer,
          $$AuditLogEntriesTableOrderingComposer,
          $$AuditLogEntriesTableAnnotationComposer,
          $$AuditLogEntriesTableCreateCompanionBuilder,
          $$AuditLogEntriesTableUpdateCompanionBuilder,
          (
            AuditLogEntry,
            BaseReferences<_$AppDatabase, $AuditLogEntriesTable, AuditLogEntry>,
          ),
          AuditLogEntry,
          PrefetchHooks Function()
        > {
  $$AuditLogEntriesTableTableManager(
    _$AppDatabase db,
    $AuditLogEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogEntriesCompanion(
                id: id,
                timestamp: timestamp,
                action: action,
                entityType: entityType,
                entityId: entityId,
                oldValue: oldValue,
                newValue: newValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                required String action,
                required String entityType,
                Value<String?> entityId = const Value.absent(),
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogEntriesCompanion.insert(
                id: id,
                timestamp: timestamp,
                action: action,
                entityType: entityType,
                entityId: entityId,
                oldValue: oldValue,
                newValue: newValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogEntriesTable,
      AuditLogEntry,
      $$AuditLogEntriesTableFilterComposer,
      $$AuditLogEntriesTableOrderingComposer,
      $$AuditLogEntriesTableAnnotationComposer,
      $$AuditLogEntriesTableCreateCompanionBuilder,
      $$AuditLogEntriesTableUpdateCompanionBuilder,
      (
        AuditLogEntry,
        BaseReferences<_$AppDatabase, $AuditLogEntriesTable, AuditLogEntry>,
      ),
      AuditLogEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DayEntriesTableTableManager get dayEntries =>
      $$DayEntriesTableTableManager(_db, _db.dayEntries);
  $$WorkSessionsTableTableManager get workSessions =>
      $$WorkSessionsTableTableManager(_db, _db.workSessions);
  $$BreakEntriesTableTableManager get breakEntries =>
      $$BreakEntriesTableTableManager(_db, _db.breakEntries);
  $$LeaveEntriesTableTableManager get leaveEntries =>
      $$LeaveEntriesTableTableManager(_db, _db.leaveEntries);
  $$PublicHolidaysTableTableManager get publicHolidays =>
      $$PublicHolidaysTableTableManager(_db, _db.publicHolidays);
  $$BalanceSnapshotsTableTableManager get balanceSnapshots =>
      $$BalanceSnapshotsTableTableManager(_db, _db.balanceSnapshots);
  $$VacationQuotasTableTableManager get vacationQuotas =>
      $$VacationQuotasTableTableManager(_db, _db.vacationQuotas);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$AuditLogEntriesTableTableManager get auditLogEntries =>
      $$AuditLogEntriesTableTableManager(_db, _db.auditLogEntries);
}
