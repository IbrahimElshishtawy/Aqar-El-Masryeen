import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionLockState {
  const SessionLockState({
    required this.isLocked,
    required this.lastActivityAt,
  });

  final bool isLocked;
  final DateTime lastActivityAt;

  SessionLockState copyWith({bool? isLocked, DateTime? lastActivityAt}) {
    return SessionLockState(
      isLocked: isLocked ?? this.isLocked,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }
}

class SessionLockController extends Notifier<SessionLockState> {
  @override
  SessionLockState build() {
    return SessionLockState(isLocked: false, lastActivityAt: DateTime.now());
  }

  void recordActivity() {
    state = state.copyWith(lastActivityAt: DateTime.now());
  }

  void handlePause() {
    state = state.copyWith(lastActivityAt: DateTime.now());
  }

  void handleResume({required bool shouldLock}) {
    final elapsed = DateTime.now().difference(state.lastActivityAt);
    if (shouldLock && elapsed.inMinutes >= AppConfig.sessionTimeoutMinutes) {
      state = state.copyWith(isLocked: true);
      return;
    }
    state = state.copyWith(lastActivityAt: DateTime.now());
  }

  void unlock() {
    state = SessionLockState(isLocked: false, lastActivityAt: DateTime.now());
  }

  void forceLock() {
    state = state.copyWith(isLocked: true);
  }
}

final sessionLockControllerProvider =
    NotifierProvider<SessionLockController, SessionLockState>(
      SessionLockController.new,
    );
