import 'package:aqarelmasryeen/core/widgets/app_loading_view.dart';
import 'package:aqarelmasryeen/core/widgets/load_failure_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.loadingLabel,
    this.errorTitle,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final String? loadingLabel;
  final String? errorTitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => AppLoadingView(
        label: loadingLabel,
        message: loadingLabel == null ? null : 'يتم تجهيز البيانات الآن.',
      ),
      error: (error, _) => LoadFailureView(
        title: errorTitle ?? 'تعذر تحميل البيانات',
        error: error,
        onRetry: onRetry,
      ),
    );
  }
}
