// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holiday_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$publicHolidaysForYearHash() =>
    r'259cac4a6bdb0838e9900872ba67be1f1f864a4d';

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

/// See also [publicHolidaysForYear].
@ProviderFor(publicHolidaysForYear)
const publicHolidaysForYearProvider = PublicHolidaysForYearFamily();

/// See also [publicHolidaysForYear].
class PublicHolidaysForYearFamily
    extends Family<AsyncValue<List<PublicHoliday>>> {
  /// See also [publicHolidaysForYear].
  const PublicHolidaysForYearFamily();

  /// See also [publicHolidaysForYear].
  PublicHolidaysForYearProvider call(int year) {
    return PublicHolidaysForYearProvider(year);
  }

  @override
  PublicHolidaysForYearProvider getProviderOverride(
    covariant PublicHolidaysForYearProvider provider,
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
  String? get name => r'publicHolidaysForYearProvider';
}

/// See also [publicHolidaysForYear].
class PublicHolidaysForYearProvider
    extends AutoDisposeStreamProvider<List<PublicHoliday>> {
  /// See also [publicHolidaysForYear].
  PublicHolidaysForYearProvider(int year)
    : this._internal(
        (ref) => publicHolidaysForYear(ref as PublicHolidaysForYearRef, year),
        from: publicHolidaysForYearProvider,
        name: r'publicHolidaysForYearProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$publicHolidaysForYearHash,
        dependencies: PublicHolidaysForYearFamily._dependencies,
        allTransitiveDependencies:
            PublicHolidaysForYearFamily._allTransitiveDependencies,
        year: year,
      );

  PublicHolidaysForYearProvider._internal(
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
    Stream<List<PublicHoliday>> Function(PublicHolidaysForYearRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PublicHolidaysForYearProvider._internal(
        (ref) => create(ref as PublicHolidaysForYearRef),
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
  AutoDisposeStreamProviderElement<List<PublicHoliday>> createElement() {
    return _PublicHolidaysForYearProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicHolidaysForYearProvider && other.year == year;
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
mixin PublicHolidaysForYearRef
    on AutoDisposeStreamProviderRef<List<PublicHoliday>> {
  /// The parameter `year` of this provider.
  int get year;
}

class _PublicHolidaysForYearProviderElement
    extends AutoDisposeStreamProviderElement<List<PublicHoliday>>
    with PublicHolidaysForYearRef {
  _PublicHolidaysForYearProviderElement(super.provider);

  @override
  int get year => (origin as PublicHolidaysForYearProvider).year;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
