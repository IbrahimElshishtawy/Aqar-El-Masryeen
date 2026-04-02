import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final properties = ref.watch(
      StreamProvider(
        (ref) => ref.watch(propertyRepositoryProvider).watchProperties(),
      ),
    );

    return AppShellScaffold(
      title: 'Properties',
      currentIndex: 1,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/properties/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add property'),
      ),
      child: properties.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateView(
              title: 'No properties yet',
              message:
                  'Create the first real-estate project to start tracking expenses, sales, collections, and partner settlements.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  title: Text(item.name),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${item.location}\n${item.status.label}'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/properties/${item.id}'),
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
