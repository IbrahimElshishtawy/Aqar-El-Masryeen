import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/async_value_view.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/features/properties/presentation/properties_providers.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/properties_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesViewDataProvider);

    return AppShellScaffold(
      title: 'المشروعات',
      subtitle: 'ملخص الأداء المالي لكل مشروع',
      currentIndex: 1,
      actions: [
        IconButton(
          tooltip: 'إضافة مشروع',
          onPressed: () => context.push('${AppRoutes.properties}/new'),
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
      child: AsyncValueView(
        value: propertiesAsync,
        loadingLabel: 'جار تحميل المشروعات',
        errorTitle: 'تعذر تحميل المشاريع',
        onRetry: () => ref.invalidate(propertiesViewDataProvider),
        data: (viewData) => ListView(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 14),
          children: [
            if (viewData.summaries.isEmpty)
              EmptyStateView(
                title: 'لا توجد مشروعات بعد',
                message:
                    'ستظهر المشروعات هنا بعد إنشاء مشروع جديد أو ربط الحساب ببيانات موجودة.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        for (
                          var index = 0;
                          index < viewData.summaries.length;
                          index++
                        ) ...[
                          PropertySummaryCard(
                            summary: viewData.summaries[index],
                          ),
                          if (index != viewData.summaries.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  }

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: viewData.summaries.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.14,
                        ),
                    itemBuilder: (context, index) =>
                        PropertySummaryCard(summary: viewData.summaries[index]),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
