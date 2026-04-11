part of '../expenses_ledger_screen.dart';

class _SelectionSheet<T> extends StatelessWidget {
  const _SelectionSheet({
    required this.title,
    required this.items,
    required this.labelBuilder,
    required this.onSelected,
  });

  final String title;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(labelBuilder(item)),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () => onSelected(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseDisplayRow {
  const _ExpenseDisplayRow({
    required this.expense,
    required this.isCurrentUser,
  });

  final ExpenseRecord expense;
  final bool isCurrentUser;
}
