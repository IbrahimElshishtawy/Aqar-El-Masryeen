import 'dart:async';

import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/constants/secure_storage_keys.dart';
import 'package:aqarelmasryeen/features/auth/data/firebase_auth_repository.dart';
import 'package:aqarelmasryeen/features/auth/domain/app_session.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _sessionLockAuthProvider = StreamProvider<AppSession?>((ref) {
  return ref.watch(authRepositoryProvider).watchSession();
});

class SessionLockState extends Equatable {
  const SessionLockState({
    required this.isInitialized,
    required this.isLocked,
    required this.appLockEnabled,
    required this.trustedDeviceEnabled,
    required this.biometricEnabled,
    required this.inactivityTimeoutSeconds,
    required this.lastActivityAt,
    this.lastBackgroundAt,
  });

  factory SessionLockState.initial() => SessionLockState(
    isInitialized: false,
    isLocked: false,
    appLockEnabled: false,
    trustedDeviceEnabled: false,
    biometricEnabled: false,
    inactivityTimeoutSeconds: AppConfig.defaultInactivityTimeoutSeconds,
    lastActivityAt: DateTime.now(),
  );

  final bool isInitialized;
  final bool isLocked;
  final bool appLockEnabled;
  final bool trustedDeviceEnabled;
  final bool biometricEnabled;
  final int inactivityTimeoutSeconds;
  final DateTime lastActivityAt;
  final DateTime? lastBackgroundAt;

  bool get shouldPresentUnlock =>
      isInitialized && isLocked && trustedDeviceEnabled;

  SessionLockState copyWith({
    bool? isInitialized,
    bool? isLocked,
    bool? appLockEnabled,
    bool? trustedDeviceEnabled,
    bool? biometricEnabled,
    int? inactivityTimeoutSeconds,
    DateTime? lastActivityAt,
    DateTime? lastBackgroundAt,
  }) {
    return SessionLockState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLocked: isLocked ?? this.isLocked,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      trustedDeviceEnabled: trustedDeviceEnabled ?? this.trustedDeviceEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      inactivityTimeoutSeconds:
          inactivityTimeoutSeconds ?? this.inactivityTimeoutSeconds,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      lastBackgroundAt: lastBackgroundAt ?? this.lastBackgroundAt,
    );
  }

  @override
  List<Object?> get props => [
    isInitialized,
    isLocked,
    appLockEnabled,
    trustedDeviceEnabled,
    biometricEnabled,
    inactivityTimeoutSeconds,
    lastActivityAt,
    lastBackgroundAt,
  ];
}

class SessionLockController extends Notifier<SessionLockState> {
  Timer? _inactivityTimer;
  bool _didWireSessionListener = false;

  @override
  SessionLockState build() {
    ref.onDispose(() => _inactivityTimer?.cancel());
    if (!_didWireSessionListener) {
      _didWireSessionListener = true;
      ref.listen(_sessionLockAuthProvider, (previous, next) {
        next.whenData((session) {
          unawaited(_syncFromSession(session));
        });
      });
    }
    return SessionLockState.initial();
  }

  Future<void> ensureInitialized() async {
    if (state.isInitialized) return;

    final storage = ref.read(secureStorageProvider);
    try {
      final appLockEnabled =
          await storage.readBool(SecureStorageKeys.appLockEnabled) ?? false;
      final trustedDeviceEnabled =
          await storage.readBool(SecureStorageKeys.trustedDeviceEnabled) ??
          false;
      final biometricEnabled =
          await storage.readBool(SecureStorageKeys.biometricEnabled) ?? false;
      final inactivityTimeoutSeconds =
          await storage.readInt(SecureStorageKeys.inactivityTimeoutSeconds) ??
          AppConfig.defaultInactivityTimeoutSeconds;
      final lastActivityAt =
          await storage.readDateTime(SecureStorageKeys.lastActivityAt) ??
          DateTime.now();
      final lastBackgroundAt = await storage.readDateTime(
        SecureStorageKeys.lastBackgroundAt,
      );
      final storedLockState =
          await storage.readBool(SecureStorageKeys.isLocked) ?? false;

      state = SessionLockState(
        isInitialized: true,
        isLocked: storedLockState,
        appLockEnabled: appLockEnabled,
        trustedDeviceEnabled: trustedDeviceEnabled,
        biometricEnabled: biometricEnabled,
        inactivityTimeoutSeconds: inactivityTimeoutSeconds,
        lastActivityAt: lastActivityAt,
        lastBackgroundAt: lastBackgroundAt,
      );
    } catch (error, stackTrace) {
      debugPrint('SessionLockController initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 6);
      state = SessionLockState.initial().copyWith(isInitialized: true);
    }

    try {
      await _syncFromSession(ref.read(_sessionLockAuthProvider).valueOrNull);
    } catch (error, stackTrace) {
      debugPrint('SessionLockController session sync failed: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 6);
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> _syncFromSession(AppSession? session) async {
    final storage = ref.read(secureStorageProvider);

    if (session == null) {
      _inactivityTimer?.cancel();
      state = SessionLockState.initial().copyWith(isInitialized: true);
      await storage.delete(SecureStorageKeys.isLocked);
      return;
    }

    final profile = session.profile;
    final now = DateTime.now();
    if (profile == null) {
      state = state.copyWith(
        isInitialized: true,
        isLocked: false,
        appLockEnabled: false,
        trustedDeviceEnabled: false,
        biometricEnabled: false,
        inactivityTimeoutSeconds: AppConfig.defaultInactivityTimeoutSeconds,
      );
      _inactivityTimer?.cancel();
      await storage.clearSessionData();
      return;
    }

    final appLockEnabled = profile.appLockEnabled;
    final trustedDeviceEnabled = profile.trustedDeviceEnabled;
    final biometricEnabled = profile.biometricEnabled;
    final inactivityTimeoutSeconds = profile.inactivityTimeoutSeconds;

    bool shouldLock = state.isLocked;
    if (appLockEnabled && trustedDeviceEnabled) {
      final lastBackgroundAt = state.lastBackgroundAt;
      final elapsedInBackground = lastBackgroundAt == null
          ? 0
          : now.difference(lastBackgroundAt).inSeconds;
      final elapsedSinceActivity = now
          .difference(state.lastActivityAt)
          .inSeconds;
      shouldLock =
          shouldLock ||
          elapsedInBackground >= inactivityTimeoutSeconds ||
          elapsedSinceActivity >= inactivityTimeoutSeconds;
    } else {
      shouldLock = false;
    }

    state = state.copyWith(
      isInitialized: true,
      isLocked: shouldLock,
      appLockEnabled: appLockEnabled,
      trustedDeviceEnabled: trustedDeviceEnabled,
      biometricEnabled: biometricEnabled,
      inactivityTimeoutSeconds: inactivityTimeoutSeconds,
    );

    await storage.persistSecurityPreferences(
      trustedDeviceEnabled: trustedDeviceEnabled,
      biometricEnabled: biometricEnabled,
      appLockEnabled: appLockEnabled,
      inactivityTimeoutSeconds: inactivityTimeoutSeconds,
    );
    await storage.writeBool(SecureStorageKeys.isLocked, shouldLock);

    if (shouldLock || !appLockEnabled || !trustedDeviceEnabled) {
      _inactivityTimer?.cancel();
    } else {
      _scheduleInactivityTimer();
    }
  }

  Future<void> recordActivity() async {
    if (!state.isInitialized || !state.appLockEnabled || state.isLocked) {
      return;
    }

    final now = DateTime.now();
    state = state.copyWith(lastActivityAt: now);
    await ref
        .read(secureStorageProvider)
        .writeDateTime(SecureStorageKeys.lastActivityAt, now);
    _scheduleInactivityTimer();
  }

  Future<void> handlePause() async {
    if (!state.isInitialized) return;
    final now = DateTime.now();
    state = state.copyWith(lastBackgroundAt: now);
    await ref
        .read(secureStorageProvider)
        .writeDateTime(SecureStorageKeys.lastBackgroundAt, now);
    _inactivityTimer?.cancel();
  }

  Future<void> handleResume() async {
    if (!state.isInitialized) {
      await ensureInitialized();
      return;
    }

    final now = DateTime.now();
    final elapsed = state.lastBackgroundAt == null
        ? 0
        : now.difference(state.lastBackgroundAt!).inSeconds;
    final shouldLock =
        state.appLockEnabled &&
        state.trustedDeviceEnabled &&
        (state.isLocked || elapsed >= state.inactivityTimeoutSeconds);

    state = state.copyWith(isLocked: shouldLock, lastBackgroundAt: null);

    final storage = ref.read(secureStorageProvider);
    await storage.writeBool(SecureStorageKeys.isLocked, shouldLock);
    await storage.delete(SecureStorageKeys.lastBackgroundAt);

    if (shouldLock) {
      _inactivityTimer?.cancel();
      return;
    }
    await recordActivity();
  }

  Future<void> forceLock() async {
    state = state.copyWith(isLocked: true);
    _inactivityTimer?.cancel();
    await ref
        .read(secureStorageProvider)
        .writeBool(SecureStorageKeys.isLocked, true);
  }

  Future<void> unlock() async {
    final now = DateTime.now();
    state = state.copyWith(
      isLocked: false,
      lastActivityAt: now,
      lastBackgroundAt: null,
    );

    final storage = ref.read(secureStorageProvider);
    await storage.writeBool(SecureStorageKeys.isLocked, false);
    await storage.writeDateTime(SecureStorageKeys.lastActivityAt, now);
    await storage.delete(SecureStorageKeys.lastBackgroundAt);
    _scheduleInactivityTimer();
  }

  Future<void> clearForLogout() async {
    _inactivityTimer?.cancel();
    state = SessionLockState.initial().copyWith(isInitialized: true);
    await ref.read(secureStorageProvider).clearSessionData();
  }

  void _scheduleInactivityTimer() {
    _inactivityTimer?.cancel();
    if (!state.appLockEnabled || !state.trustedDeviceEnabled) {
      return;
    }
    _inactivityTimer = Timer(
      Duration(seconds: state.inactivityTimeoutSeconds),
      () => unawaited(forceLock()),
    );
  }
}

final sessionLockControllerProvider =
    NotifierProvider<SessionLockController, SessionLockState>(
      SessionLockController.new,
    );
