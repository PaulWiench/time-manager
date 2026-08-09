// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$balanceSnapshotsInRangeHash() =>
    r'd16cdb005d054b589f56f0357bdb39b81f17f596';

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

/// See also [balanceSnapshotsInRange].
@ProviderFor(balanceSnapshotsInRange)
const balanceSnapshotsInRangeProvider = BalanceSnapshotsInRangeFamily();

/// See also [balanceSnapshotsInRange].
class BalanceSnapshotsInRangeFamily
    extends Family<AsyncValue<List<BalanceSnapshot>>> {
  /// See also [balanceSnapshotsInRange].
  const BalanceSnapshotsInRangeFamily();

  /// See also [balanceSnapshotsInRange].
  BalanceSnapshotsInRangeProvider call(DateTime start, DateTime endExclusive) {
    return BalanceSnapshotsInRangeProvider(start, endExclusive);
  }

  @override
  BalanceSnapshotsInRangeProvider getProviderOverride(
    covariant BalanceSnapshotsInRangeProvider provider,
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
  String? get name => r'balanceSnapshotsInRangeProvider';
}

/// See also [balanceSnapshotsInRange].
class BalanceSnapshotsInRangeProvider
    extends AutoDisposeFutureProvider<List<BalanceSnapshot>> {
  /// See also [balanceSnapshotsInRange].
  BalanceSnapshotsInRangeProvider(DateTime start, DateTime endExclusive)
    : this._internal(
        (ref) => balanceSnapshotsInRange(
          ref as BalanceSnapshotsInRangeRef,
          start,
          endExclusive,
        ),
        from: balanceSnapshotsInRangeProvider,
        name: r'balanceSnapshotsInRangeProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$balanceSnapshotsInRangeHash,
        dependencies: BalanceSnapshotsInRangeFamily._dependencies,
        allTransitiveDependencies:
            BalanceSnapshotsInRangeFamily._allTransitiveDependencies,
        start: start,
        endExclusive: endExclusive,
      );

  BalanceSnapshotsInRangeProvider._internal(
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
    FutureOr<List<BalanceSnapshot>> Function(
      BalanceSnapshotsInRangeRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BalanceSnapshotsInRangeProvider._internal(
        (ref) => create(ref as BalanceSnapshotsInRangeRef),
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
  AutoDisposeFutureProviderElement<List<BalanceSnapshot>> createElement() {
    return _BalanceSnapshotsInRangeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BalanceSnapshotsInRangeProvider &&
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
mixin BalanceSnapshotsInRangeRef
    on AutoDisposeFutureProviderRef<List<BalanceSnapshot>> {
  /// The parameter `start` of this provider.
  DateTime get start;

  /// The parameter `endExclusive` of this provider.
  DateTime get endExclusive;
}

class _BalanceSnapshotsInRangeProviderElement
    extends AutoDisposeFutureProviderElement<List<BalanceSnapshot>>
    with BalanceSnapshotsInRangeRef {
  _BalanceSnapshotsInRangeProviderElement(super.provider);

  @override
  DateTime get start => (origin as BalanceSnapshotsInRangeProvider).start;
  @override
  DateTime get endExclusive =>
      (origin as BalanceSnapshotsInRangeProvider).endExclusive;
}

String _$workSessionsInRangeHash() =>
    r'1ad6885569657c07e7cdd605a0c97186c39aa581';

/// See also [workSessionsInRange].
@ProviderFor(workSessionsInRange)
const workSessionsInRangeProvider = WorkSessionsInRangeFamily();

/// See also [workSessionsInRange].
class WorkSessionsInRangeFamily extends Family<AsyncValue<List<WorkSession>>> {
  /// See also [workSessionsInRange].
  const WorkSessionsInRangeFamily();

  /// See also [workSessionsInRange].
  WorkSessionsInRangeProvider call(DateTime start, DateTime endExclusive) {
    return WorkSessionsInRangeProvider(start, endExclusive);
  }

  @override
  WorkSessionsInRangeProvider getProviderOverride(
    covariant WorkSessionsInRangeProvider provider,
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
  String? get name => r'workSessionsInRangeProvider';
}

/// See also [workSessionsInRange].
class WorkSessionsInRangeProvider
    extends AutoDisposeFutureProvider<List<WorkSession>> {
  /// See also [workSessionsInRange].
  WorkSessionsInRangeProvider(DateTime start, DateTime endExclusive)
    : this._internal(
        (ref) => workSessionsInRange(
          ref as WorkSessionsInRangeRef,
          start,
          endExclusive,
        ),
        from: workSessionsInRangeProvider,
        name: r'workSessionsInRangeProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$workSessionsInRangeHash,
        dependencies: WorkSessionsInRangeFamily._dependencies,
        allTransitiveDependencies:
            WorkSessionsInRangeFamily._allTransitiveDependencies,
        start: start,
        endExclusive: endExclusive,
      );

  WorkSessionsInRangeProvider._internal(
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
    FutureOr<List<WorkSession>> Function(WorkSessionsInRangeRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WorkSessionsInRangeProvider._internal(
        (ref) => create(ref as WorkSessionsInRangeRef),
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
  AutoDisposeFutureProviderElement<List<WorkSession>> createElement() {
    return _WorkSessionsInRangeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkSessionsInRangeProvider &&
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
mixin WorkSessionsInRangeRef
    on AutoDisposeFutureProviderRef<List<WorkSession>> {
  /// The parameter `start` of this provider.
  DateTime get start;

  /// The parameter `endExclusive` of this provider.
  DateTime get endExclusive;
}

class _WorkSessionsInRangeProviderElement
    extends AutoDisposeFutureProviderElement<List<WorkSession>>
    with WorkSessionsInRangeRef {
  _WorkSessionsInRangeProviderElement(super.provider);

  @override
  DateTime get start => (origin as WorkSessionsInRangeProvider).start;
  @override
  DateTime get endExclusive =>
      (origin as WorkSessionsInRangeProvider).endExclusive;
}

String _$leaveForYearHash() => r'dd73395da0f43f61d6a7d7e63fef929be1197546';

/// See also [leaveForYear].
@ProviderFor(leaveForYear)
const leaveForYearProvider = LeaveForYearFamily();

/// See also [leaveForYear].
class LeaveForYearFamily extends Family<AsyncValue<List<LeaveEntry>>> {
  /// See also [leaveForYear].
  const LeaveForYearFamily();

  /// See also [leaveForYear].
  LeaveForYearProvider call(int year) {
    return LeaveForYearProvider(year);
  }

  @override
  LeaveForYearProvider getProviderOverride(
    covariant LeaveForYearProvider provider,
  ) {
    return call(provider.year);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'leaveForYearProvider';
}

/// See also [leaveForYear].
class LeaveForYearProvider extends AutoDisposeFutureProvider<List<LeaveEntry>> {
  /// See also [leaveForYear].
  LeaveForYearProvider(int year)
    : this._internal(
        (ref) => leaveForYear(ref as LeaveForYearRef, year),
        from: leaveForYearProvider,
        name: r'leaveForYearProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$leaveForYearHash,
        dependencies: LeaveForYearFamily._dependencies,
        allTransitiveDependencies:
            LeaveForYearFamily._allTransitiveDependencies,
        year: year,
      );

  LeaveForYearProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
  }) : super.internal();

  final int year;

  @override
  Override overrideWith(
    FutureOr<List<LeaveEntry>> Function(LeaveForYearRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LeaveForYearProvider._internal(
        (ref) => create(ref as LeaveForYearRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<LeaveEntry>> createElement() {
    return _LeaveForYearProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LeaveForYearProvider && other.year == year;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LeaveForYearRef on AutoDisposeFutureProviderRef<List<LeaveEntry>> {
  /// The parameter `year` of this provider.
  int get year;
}

class _LeaveForYearProviderElement
    extends AutoDisposeFutureProviderElement<List<LeaveEntry>>
    with LeaveForYearRef {
  _LeaveForYearProviderElement(super.provider);

  @override
  int get year => (origin as LeaveForYearProvider).year;
}

String _$vacationQuotaForYearHash() =>
    r'c0dbd348dac77f5be2b5b6f7ea27ef5c4f782a74';

/// See also [vacationQuotaForYear].
@ProviderFor(vacationQuotaForYear)
const vacationQuotaForYearProvider = VacationQuotaForYearFamily();

/// See also [vacationQuotaForYear].
class VacationQuotaForYearFamily extends Family<AsyncValue<VacationQuota?>> {
  /// See also [vacationQuotaForYear].
  const VacationQuotaForYearFamily();

  /// See also [vacationQuotaForYear].
  VacationQuotaForYearProvider call(int year) {
    return VacationQuotaForYearProvider(year);
  }

  @override
  VacationQuotaForYearProvider getProviderOverride(
    covariant VacationQuotaForYearProvider provider,
  ) {
    return call(provider.year);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'vacationQuotaForYearProvider';
}

/// See also [vacationQuotaForYear].
class VacationQuotaForYearProvider
    extends AutoDisposeFutureProvider<VacationQuota?> {
  /// See also [vacationQuotaForYear].
  VacationQuotaForYearProvider(int year)
    : this._internal(
        (ref) => vacationQuotaForYear(ref as VacationQuotaForYearRef, year),
        from: vacationQuotaForYearProvider,
        name: r'vacationQuotaForYearProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$vacationQuotaForYearHash,
        dependencies: VacationQuotaForYearFamily._dependencies,
        allTransitiveDependencies:
            VacationQuotaForYearFamily._allTransitiveDependencies,
        year: year,
      );

  VacationQuotaForYearProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
  }) : super.internal();

  final int year;

  @override
  Override overrideWith(
    FutureOr<VacationQuota?> Function(VacationQuotaForYearRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VacationQuotaForYearProvider._internal(
        (ref) => create(ref as VacationQuotaForYearRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<VacationQuota?> createElement() {
    return _VacationQuotaForYearProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VacationQuotaForYearProvider && other.year == year;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VacationQuotaForYearRef on AutoDisposeFutureProviderRef<VacationQuota?> {
  /// The parameter `year` of this provider.
  int get year;
}

class _VacationQuotaForYearProviderElement
    extends AutoDisposeFutureProviderElement<VacationQuota?>
    with VacationQuotaForYearRef {
  _VacationQuotaForYearProviderElement(super.provider);

  @override
  int get year => (origin as VacationQuotaForYearProvider).year;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
