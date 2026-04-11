part of '../partners_screen.dart';

class _PendingRequestsSheet extends StatefulWidget {
  const _PendingRequestsSheet({required this.requests, required this.onAccept});

  final List<AppNotificationItem> requests;
  final Future<void> Function(AppNotificationItem request) onAccept;

  @override
  State<_PendingRequestsSheet> createState() => _PendingRequestsSheetState();
}

class _PendingRequestsSheetState extends State<_PendingRequestsSheet> {
  String? _acceptingRequestId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'طلبات ربط الحساب',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'وافق على الطلب المناسب لربط حساب الدخول بهذا الشريك.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (widget.requests.isEmpty)
              const EmptyStateView(
                title: 'لا توجد طلبات ربط',
                message: 'عند وصول طلبات جديدة ستظهر هنا.',
              )
            else
              ...widget.requests.map(
                (request) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(request.title),
                    subtitle: Text(
                      request.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: _acceptingRequestId == null
                          ? () => _accept(request)
                          : null,
                      child: _acceptingRequestId == request.id
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('مراجعة'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(AppNotificationItem request) async {
    setState(() => _acceptingRequestId = request.id);
    try {
      await widget.onAccept(request);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل الربط: $error')));
    } finally {
      if (mounted) {
        setState(() => _acceptingRequestId = null);
      }
    }
  }
}
