// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$latestSettingsHash() => r'467609f68b076fffc4f003a9dec555d7f04d29db';

/// See also [latestSettings].
@ProviderFor(latestSettings)
final latestSettingsProvider = StreamProvider<AppSetting?>.internal(
  latestSettings,
  name: r'latestSettingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$latestSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LatestSettingsRef = StreamProviderRef<AppSetting?>;
String _$effectiveSettingsForHash() =>
    r'a53268cd8227a0eddb98254cf9ace33923f38070';

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

/// [date] should be normalized via `domain/date_only.dart`'s `dateOnly`.
///
/// Copied from [effectiveSettingsFor].
@ProviderFor(effectiveSettingsFor)
const effectiveSettingsForProvider = EffectiveSettingsForFamily();

/// [date] should be normalized via `domain/date_only.dart`'s `dateOnly`.
///
/// Copied from [effectiveSettingsFor].
class EffectiveSettingsForFamily extends Family<AsyncValue<AppSetting?>> {
  /// [date] should be normalized via `domain/date_only.dart`'s `dateOnly`.
  ///
  /// Copied from [effectiveSettingsFor].
  const EffectiveSettingsForFamily();

  /// [date] should be normalized via `domain/date_only.dart`'s `dateOnly`.
  ///
  /// Copied from [effectiveSettingsFor].
  EffectiveSettingsForProvider call(DateTime date) {
    return EffectiveSettingsForProvider(date);
  }

  @override
  EffectiveSettingsForProvider getProviderOverride(
    covariant EffectiveSettingsForProvider provider,
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
  String? get name => r'effectiveSettingsForProvider';
}

/// [date] should be normalized via `domain/date_only.dart`'s `dateOnly`.
///
/// Copied from [effectiveSettingsFor].
class EffectiveSettingsForProvider
    extends AutoDisposeFutureProvider<AppSetting?> {
  /// [date] should be normalized via `domain/date_only.dart`'s `dateOnly`.
  ///
  /// Copied from [effectiveSettingsFor].
  EffectiveSettingsForProvider(DateTime date)
    : this._internal(
        (ref) => effectiveSettingsFor(ref as EffectiveSettingsForRef, date),
        from: effectiveSettingsForProvider,
        name: r'effectiveSettingsForProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$effectiveSettingsForHash,
        dependencies: EffectiveSettingsForFamily._dependencies,
        allTransitiveDependencies:
            EffectiveSettingsForFamily._allTransitiveDependencies,
        date: date,
      );

  EffectiveSettingsForProvider._internal(
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
    FutureOr<AppSetting?> Function(EffectiveSettingsForRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EffectiveSettingsForProvider._internal(
        (ref) => create(ref as EffectiveSettingsForRef),
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
  AutoDisposeFutureProviderElement<AppSetting?> createElement() {
    return _EffectiveSettingsForProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EffectiveSettingsForProvider && other.date == date;
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
mixin EffectiveSettingsForRef on AutoDisposeFutureProviderRef<AppSetting?> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _EffectiveSettingsForProviderElement
    extends AutoDisposeFutureProviderElement<AppSetting?>
    with EffectiveSettingsForRef {
  _EffectiveSettingsForProviderElement(super.provider);

  @override
  DateTime get date => (origin as EffectiveSettingsForProvider).date;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
