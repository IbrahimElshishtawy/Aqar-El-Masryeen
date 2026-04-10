import 'package:aqarelmasryeen/core/errors/load_failure_details.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:flutter/material.dart';

class LoadFailureView extends StatelessWidget {
  const LoadFailureView({
    super.key,
    required this.title,
    required this.error,
    this.notFoundTitle,
    this.onRetry,
    this.retryLabel,
  });

  final String title;
  final Object error;
  final String? notFoundTitle;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final details = describeLoadFailure(
      error,
      defaultTitle: title,
      notFoundTitle: notFoundTitle,
    );

    return EmptyStateView(
      title: details.title,
      message: details.message,
      actionLabel: onRetry == null ? null : (retryLabel ?? 'إعادة المحاولة'),
      onAction: onRetry,
    );
  }
}
