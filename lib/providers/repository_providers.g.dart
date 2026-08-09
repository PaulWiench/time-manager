// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recalculationServiceHash() =>
    r'55550e82ea63b9c88b7e807f7f659f581404eaad';

/// See also [recalculationService].
@ProviderFor(recalculationService)
final recalculationServiceProvider = Provider<RecalculationService>.internal(
  recalculationService,
  name: r'recalculationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recalculationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecalculationServiceRef = ProviderRef<RecalculationService>;
String _$workSessionRepositoryHash() =>
    r'b1b4662ad9dd7e29bfbd57fe0970095741aed2de';

/// See also [workSessionRepository].
@ProviderFor(workSessionRepository)
final workSessionRepositoryProvider = Provider<WorkSessionRepository>.internal(
  workSessionRepository,
  name: r'workSessionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$workSessionRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WorkSessionRepositoryRef = ProviderRef<WorkSessionRepository>;
String _$settingsRepositoryHash() =>
    r'121b693ec0f834f6f18f039b9bc71bfa99e5db24';

/// See also [settingsRepository].
@ProviderFor(settingsRepository)
final settingsRepositoryProvider = Provider<SettingsRepository>.internal(
  settingsRepository,
  name: r'settingsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SettingsRepositoryRef = ProviderRef<SettingsRepository>;
String _$leaveRepositoryHash() => r'44ae5207a8211f06bddfa6ee067173413fa2304f';

/// See also [leaveRepository].
@ProviderFor(leaveRepository)
final leaveRepositoryProvider = Provider<LeaveRepository>.internal(
  leaveRepository,
  name: r'leaveRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$leaveRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LeaveRepositoryRef = ProviderRef<LeaveRepository>;
String _$publicHolidayRepositoryHash() =>
    r'7c720341d567927982c71bab6128c244ac32ec4e';

/// See also [publicHolidayRepository].
@ProviderFor(publicHolidayRepository)
final publicHolidayRepositoryProvider =
    Provider<PublicHolidayRepository>.internal(
      publicHolidayRepository,
      name: r'publicHolidayRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$publicHolidayRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublicHolidayRepositoryRef = ProviderRef<PublicHolidayRepository>;
String _$vacationQuotaRepositoryHash() =>
    r'13282b4c08d64961008aa1c68d9e43ed229d7d4b';

/// See also [vacationQuotaRepository].
@ProviderFor(vacationQuotaRepository)
final vacationQuotaRepositoryProvider =
    Provider<VacationQuotaRepository>.internal(
      vacationQuotaRepository,
      name: r'vacationQuotaRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$vacationQuotaRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VacationQuotaRepositoryRef = ProviderRef<VacationQuotaRepository>;
String _$holidaySeedHash() => r'a10b98766147efb659efe6b372ba8931581e26f2';

/// Seeds this year's and next year's German public holidays on app start.
/// `seedYear` only inserts dates that don't already exist, so this is a
/// cheap no-op on every launch after the first — and covers the
/// December-into-January boundary so next year's holidays are already
/// present before it turns over, not just by the time someone opens the
/// Settings screen after New Year's.
///
/// Copied from [holidaySeed].
@ProviderFor(holidaySeed)
final holidaySeedProvider = FutureProvider<void>.internal(
  holidaySeed,
  name: r'holidaySeedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$holidaySeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HolidaySeedRef = FutureProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
