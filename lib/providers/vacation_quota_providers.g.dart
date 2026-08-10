// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vacation_quota_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$vacationQuotaForYearHash() =>
    r'a6faef65feb8264a759db5eff2e2a7d848e8eb54';

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
    extends AutoDisposeStreamProvider<VacationQuota?> {
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
    Stream<VacationQuota?> Function(VacationQuotaForYearRef provider) create,
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
  AutoDisposeStreamProviderElement<VacationQuota?> createElement() {
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
mixin VacationQuotaForYearRef on AutoDisposeStreamProviderRef<VacationQuota?> {
  /// The parameter `year` of this provider.
  int get year;
}

class _VacationQuotaForYearProviderElement
    extends AutoDisposeStreamProviderElement<VacationQuota?>
    with VacationQuotaForYearRef {
  _VacationQuotaForYearProviderElement(super.provider);

  @override
  int get year => (origin as VacationQuotaForYearProvider).year;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
