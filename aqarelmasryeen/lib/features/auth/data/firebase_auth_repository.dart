import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
import 'package:aqarelmasryeen/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:aqarelmasryeen/features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import 'package:aqarelmasryeen/features/auth/data/datasources/user_profile_remote_data_source.dart';
import 'package:aqarelmasryeen/features/auth/data/mock_auth_repository.dart';
import 'package:aqarelmasryeen/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:aqarelmasryeen/features/auth/domain/auth_repository.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:aqarelmasryeen/features/auth/data/repositories/firebase_auth_repository_impl.dart';

final firebaseAuthRemoteDataSourceProvider =
    Provider<FirebaseAuthRemoteDataSource>((ref) {
      return FirebaseAuthRemoteDataSource(ref.watch(firebaseAuthProvider));
    });

final userProfileRemoteDataSourceProvider =
    Provider<UserProfileRemoteDataSource>((ref) {
      return UserProfileRemoteDataSource(ref.watch(firestoreProvider));
    });

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource(
    ref.watch(localCacheServiceProvider),
    ref.watch(secureStorageProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockAuthRepository(
      MockWorkspaceStore.instance,
      ref.watch(authLocalDataSourceProvider),
    );
  }

  return FirebaseAuthRepository(
    ref.watch(firebaseAuthRemoteDataSourceProvider),
    ref.watch(userProfileRemoteDataSourceProvider),
    ref.watch(authLocalDataSourceProvider),
    ref.watch(activityRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
    ref.watch(secureStorageProvider),
    ref.watch(deviceInfoServiceProvider),
    ref.watch(analyticsProvider),
    ref.watch(crashlyticsProvider),
  );
});
