import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final userNotificationsProvider = StreamProvider.autoDispose((ref) async* {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    yield const [];
    return;
  }
  yield* ref.watch(notificationRepositoryProvider).watchNotifications(session.firebaseUser.uid);
});

class NotificationsCenterScreen extends ConsumerWidget {
  const NotificationsCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(userNotificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No alerts yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    item.isRead
                        ? Icons.mark_email_read_outlined
                        : Icons.notifications_active_outlined,
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.body),
                  onTap: () async {
                    await ref.read(notificationRepositoryProvider).markRead(item.id);
                    if (context.mounted) context.go(item.route);
                  },
                ),
              );
            },
          );
        },
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
