// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionsForDateHash() => r'b9af777ddc194ec8fc892d6a6e55fe9bc78578e0';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// All family providers below expect [date] already normalized to midnight
/// (see `domain/date_only.dart`) — callers passing a fresh `DateTime.now()`
/// each time would defeat provider caching.
///
/// Copied from [sessionsForDate].
@ProviderFor(sessionsForDate)
const sessionsForDateProvider = SessionsForDateFamily();

/// All family providers below expect [date] already normalized to midnight
/// (see `domain/date_only.dart`) — callers passing a fresh `DateTime.now()`
/// each time would defeat provider caching.
///
/// Copied from [sessionsForDate].
class SessionsForDateFamily extends Family<AsyncValue<List<WorkSession>>> {
  /// All family providers below expect [date] already normalized to midnight
  /// (see `domain/date_only.dart`) — callers passing a fresh `DateTime.now()`
  /// each time would defeat provider caching.
  ///
  /// Copied from [sessionsForDate].
  const SessionsForDateFamily();

  /// All family providers below expect [date] already normalized to midnight
  /// (see `domain/date_only.dart`) — callers passing a fresh `DateTime.now()`
  /// each time would defeat provider caching.
  ///
  /// Copied from [sessionsForDate].
  SessionsForDateProvider call(DateTime date) {
    return SessionsForDateProvider(date);
  }

  @override
  SessionsForDateProvider getProviderOverride(
    covariant SessionsForDateProvider provider,
  ) {
    return call(provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sessionsForDateProvider';
}

/// All family providers below expect [date] already normalized to midnight
/// (see `domain/date_only.dart`) — callers passing a fresh `DateTime.now()`
/// each time would defeat provider caching.
///
/// Copied from [sessionsForDate].
class SessionsForDateProvider
    extends AutoDisposeStreamProvider<List<WorkSession>> {
  /// All family providers below expect [date] already normalized to midnight
  /// (see `domain/date_only.dart`) — callers passing a fresh `DateTime.now()`
  /// each time would defeat provider caching.
  ///
  /// Copied from [sessionsForDate].
  SessionsForDateProvider(DateTime date)
    : this._internal(
        (ref) => sessionsForDate(ref as SessionsForDateRef, date),
        from: sessionsForDateProvider,
        name: r'sessionsForDateProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$sessionsForDateHash,
        dependencies: SessionsForDateFamily._dependencies,
        allTransitiveDependencies:
            SessionsForDateFamily._allTransitiveDependencies,
        date: date,
      );

  SessionsForDateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Override overrideWith(
    Stream<List<WorkSession>> Function(SessionsForDateRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SessionsForDateProvider._internal(
        (ref) => create(ref as SessionsForDateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<WorkSession>> createElement() {
    return _SessionsForDateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionsForDateProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SessionsForDateRef on AutoDisposeStreamProviderRef<List<WorkSession>> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _SessionsForDateProviderElement
    extends AutoDisposeStreamProviderElement<List<WorkSession>>
    with SessionsForDateRef {
  _SessionsForDateProviderElement(super.provider);

  @override
  DateTime get date => (origin as SessionsForDateProvider).date;
}

String _$dayEntryForDateHash() => r'fd5a62fa16c56039cb12d2eea72e35bc0d439f5d';

/// See also [dayEntryForDate].
@ProviderFor(dayEntryForDate)
const dayEntryForDateProvider = DayEntryForDateFamily();

/// See also [dayEntryForDate].
class DayEntryForDateFamily extends Family<AsyncValue<DayEntry?>> {
  /// See also [dayEntryForDate].
  const DayEntryForDateFamily();

  /// See also [dayEntryForDate].
  DayEntryForDateProvider call(DateTime date) {
    return DayEntryForDateProvider(date);
  }

  @override
  DayEntryForDateProvider getProviderOverride(
    covariant DayEntryForDateProvider provider,
  ) {
    return call(provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'dayEntryForDateProvider';
}

/// See also [dayEntryForDate].
class DayEntryForDateProvider extends AutoDisposeStreamProvider<DayEntry?> {
  /// See also [dayEntryForDate].
  DayEntryForDateProvider(DateTime date)
    : this._internal(
        (ref) => dayEntryForDate(ref as DayEntryForDateRef, date),
        from: dayEntryForDateProvider,
        name: r'dayEntryForDateProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$dayEntryForDateHash,
        dependencies: DayEntryForDateFamily._dependencies,
        allTransitiveDependencies:
            DayEntryForDateFamily._allTransitiveDependencies,
        date: date,
      );

  DayEntryForDateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Override overrideWith(
    Stream<DayEntry?> Function(DayEntryForDateRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DayEntryForDateProvider._internal(
        (ref) => create(ref as DayEntryForDateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<DayEntry?> createElement() {
    return _DayEntryForDateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DayEntryForDateProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DayEntryForDateRef on AutoDisposeStreamProviderRef<DayEntry?> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _DayEntryForDateProviderElement
    extends AutoDisposeStreamProviderElement<DayEntry?>
    with DayEntryForDateRef {
  _DayEntryForDateProviderElement(super.provider);

  @override
  DateTime get date => (origin as DayEntryForDateProvider).date;
}

String _$leaveForDateHash() => r'de6567bd392275bd4e37591161ddf5e866fa6c3f';

/// See also [leaveForDate].
@ProviderFor(leaveForDate)
const leaveForDateProvider = LeaveForDateFamily();

/// See also [leaveForDate].
class LeaveForDateFamily extends Family<AsyncValue<List<LeaveEntry>>> {
  /// See also [leaveForDate].
  const LeaveForDateFamily();

  /// See also [leaveForDate].
  LeaveForDateProvider call(DateTime date) {
    return LeaveForDateProvider(date);
  }

  @override
  LeaveForDateProvider getProviderOverride(
    covariant LeaveForDateProvider provider,
  ) {
    return call(provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'leaveForDateProvider';
}

/// See also [leaveForDate].
class LeaveForDateProvider extends AutoDisposeStreamProvider<List<LeaveEntry>> {
  /// See also [leaveForDate].
  LeaveForDateProvider(DateTime date)
    : this._internal(
        (ref) => leaveForDate(ref as LeaveForDateRef, date),
        from: leaveForDateProvider,
        name: r'leaveForDateProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$leaveForDateHash,
        dependencies: LeaveForDateFamily._dependencies,
        allTransitiveDependencies:
            LeaveForDateFamily._allTransitiveDependencies,
        date: date,
      );

  LeaveForDateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Override overrideWith(
    Stream<List<LeaveEntry>> Function(LeaveForDateRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LeaveForDateProvider._internal(
        (ref) => create(ref as LeaveForDateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<LeaveEntry>> createElement() {
    return _LeaveForDateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LeaveForDateProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LeaveForDateRef on AutoDisposeStreamProviderRef<List<LeaveEntry>> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _LeaveForDateProviderElement
    extends AutoDisposeStreamProviderElement<List<LeaveEntry>>
    with LeaveForDateRef {
  _LeaveForDateProviderElement(super.provider);

  @override
  DateTime get date => (origin as LeaveForDateProvider).date;
}

String _$breaksForDateHash() => r'0f395b91b66f0304a890eb25a792e367146452c7';

/// See also [breaksForDate].
@ProviderFor(breaksForDate)
const breaksForDateProvider = BreaksForDateFamily();

/// See also [breaksForDate].
class BreaksForDateFamily extends Family<AsyncValue<List<BreakEntry>>> {
  /// See also [breaksForDate].
  const BreaksForDateFamily();

  /// See also [breaksForDate].
  BreaksForDateProvider call(DateTime date) {
    return BreaksForDateProvider(date);
  }

  @override
  BreaksForDateProvider getProviderOverride(
    covariant BreaksForDateProvider provider,
  ) {
    return call(provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'breaksForDateProvider';
}

/// See also [breaksForDate].
class BreaksForDateProvider
    extends AutoDisposeStreamProvider<List<BreakEntry>> {
  /// See also [breaksForDate].
  BreaksForDateProvider(DateTime date)
    : this._internal(
        (ref) => breaksForDate(ref as BreaksForDateRef, date),
        from: breaksForDateProvider,
        name: r'breaksForDateProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$breaksForDateHash,
        dependencies: BreaksForDateFamily._dependencies,
        allTransitiveDependencies:
            BreaksForDateFamily._allTransitiveDependencies,
        date: date,
      );

  BreaksForDateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Override overrideWith(
    Stream<List<BreakEntry>> Function(BreaksForDateRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BreaksForDateProvider._internal(
        (ref) => create(ref as BreaksForDateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<BreakEntry>> createElement() {
    return _BreaksForDateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BreaksForDateProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BreaksForDateRef on AutoDisposeStreamProviderRef<List<BreakEntry>> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _BreaksForDateProviderElement
    extends AutoDisposeStreamProviderElement<List<BreakEntry>>
    with BreaksForDateRef {
  _BreaksForDateProviderElement(super.provider);

  @override
  DateTime get date => (origin as BreaksForDateProvider).date;
}

String _$dayEntriesInRangeHash() => r'a57bf2fa4abe02828606a2261de0f1b6f2b5948b';

/// Used by History's Month/Week rows to aggregate worked hours + balance
/// delta over a range without a per-day family provider each.
///
/// Copied from [dayEntriesInRange].
@ProviderFor(dayEntriesInRange)
const dayEntriesInRangeProvider = DayEntriesInRangeFamily();

/// Used by History's Month/Week rows to aggregate worked hours + balance
/// delta over a range without a per-day family provider each.
///
/// Copied from [dayEntriesInRange].
class DayEntriesInRangeFamily extends Family<AsyncValue<List<DayEntry>>> {
  /// Used by History's Month/Week rows to aggregate worked hours + balance
  /// delta over a range without a per-day family provider each.
  ///
  /// Copied from [dayEntriesInRange].
  const DayEntriesInRangeFamily();

  /// Used by History's Month/Week rows to aggregate worked hours + balance
  /// delta over a range without a per-day family provider each.
  ///
  /// Copied from [dayEntriesInRange].
  DayEntriesInRangeProvider call(DateTime start, DateTime endExclusive) {
    return DayEntriesInRangeProvider(start, endExclusive);
  }

  @override
  DayEntriesInRangeProvider getProviderOverride(
    covariant DayEntriesInRangeProvider provider,
  ) {
    return call(provider.start, provider.endExclusive);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'dayEntriesInRangeProvider';
}

/// Used by History's Month/Week rows to aggregate worked hours + balance
/// delta over a range without a per-day family provider each.
///
/// Copied from [dayEntriesInRange].
class DayEntriesInRangeProvider
    extends AutoDisposeFutureProvider<List<DayEntry>> {
  /// Used by History's Month/Week rows to aggregate worked hours + balance
  /// delta over a range without a per-day family provider each.
  ///
  /// Copied from [dayEntriesInRange].
  DayEntriesInRangeProvider(DateTime start, DateTime endExclusive)
    : this._internal(
        (ref) =>
            dayEntriesInRange(ref as DayEntriesInRangeRef, start, endExclusive),
        from: dayEntriesInRangeProvider,
        name: r'dayEntriesInRangeProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$dayEntriesInRangeHash,
        dependencies: DayEntriesInRangeFamily._dependencies,
        allTransitiveDependencies:
            DayEntriesInRangeFamily._allTransitiveDependencies,
        start: start,
        endExclusive: endExclusive,
      );

  DayEntriesInRangeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.start,
    required this.endExclusive,
  }) : super.internal();

  final DateTime start;
  final DateTime endExclusive;

  @override
  Override overrideWith(
    FutureOr<List<DayEntry>> Function(DayEntriesInRangeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DayEntriesInRangeProvider._internal(
        (ref) => create(ref as DayEntriesInRangeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        start: start,
        endExclusive: endExclusive,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<DayEntry>> createElement() {
    return _DayEntriesInRangeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DayEntriesInRangeProvider &&
        other.start == start &&
        other.endExclusive == endExclusive;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, start.hashCode);
    hash = _SystemHash.combine(hash, endExclusive.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DayEntriesInRangeRef on AutoDisposeFutureProviderRef<List<DayEntry>> {
  /// The parameter `start` of this provider.
  DateTime get start;

  /// The parameter `endExclusive` of this provider.
  DateTime get endExclusive;
}

class _DayEntriesInRangeProviderElement
    extends AutoDisposeFutureProviderElement<List<DayEntry>>
    with DayEntriesInRangeRef {
  _DayEntriesInRangeProviderElement(super.provider);

  @override
  DateTime get start => (origin as DayEntriesInRangeProvider).start;
  @override
  DateTime get endExclusive =>
      (origin as DayEntriesInRangeProvider).endExclusive;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
