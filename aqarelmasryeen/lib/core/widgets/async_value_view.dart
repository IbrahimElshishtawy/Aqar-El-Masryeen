import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.loadingLabel,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final String? loadingLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (loadingLabel != null) ...[
              const SizedBox(height: 12),
              Text(loadingLabel!),
            ],
          ],
        ),
      ),
      error: (error, _) => EmptyStateView(
        title: 'Something went wrong',
        message: error.toString(),
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
      ),
    );
  }
}
