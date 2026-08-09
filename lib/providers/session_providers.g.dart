// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeSessionHash() => r'0caf8c603e12dc2d65b306b3e64d1fafeedea4bd';

/// The currently active session (if any), derived from today's sessions.
/// A session that crosses midnight is still "today's" until the midnight
/// cutoff logic resolves it — see `domain/midnight_cutoff.dart`.
///
/// Copied from [activeSession].
@ProviderFor(activeSession)
final activeSessionProvider = AutoDisposeStreamProvider<WorkSession?>.internal(
  activeSession,
  name: r'activeSessionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeSessionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveSessionRef = AutoDisposeStreamProviderRef<WorkSession?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
