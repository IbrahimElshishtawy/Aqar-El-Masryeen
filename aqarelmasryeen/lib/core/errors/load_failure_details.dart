import 'package:aqarelmasryeen/core/errors/failure_mapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoadFailureDetails {
  const LoadFailureDetails({required this.title, required this.message});

  final String title;
  final String message;
}

LoadFailureDetails describeLoadFailure(
  Object error, {
  required String defaultTitle,
  String? notFoundTitle,
}) {
  if (error is FirebaseException && error.plugin == 'cloud_firestore') {
    final normalizedMessage = (error.message ?? '').toLowerCase();

    switch (error.code) {
      case 'permission-denied':
      case 'unauthenticated':
        return LoadFailureDetails(
          title: defaultTitle,
          message: 'ليس لديك صلاحية للوصول لهذه البيانات.',
        );
      case 'failed-precondition':
        if (normalizedMessage.contains('requires an index') &&
            normalizedMessage.contains('currently building')) {
          return LoadFailureDetails(
            title: defaultTitle,
            message: 'جارٍ تجهيز الفهرس في Firestore. حاول مرة أخرى بعد قليل.',
          );
        }
        if (normalizedMessage.contains('requires an index')) {
          return LoadFailureDetails(
            title: defaultTitle,
            message:
                'هذا الاستعلام يحتاج فهرسًا إضافيًا في Firestore. راجع ملف الفهارس ثم أعد المحاولة.',
          );
        }
        return LoadFailureDetails(
          title: defaultTitle,
          message: 'تعذر تنفيذ الطلب لأن إعداد Firestore غير مكتمل بعد.',
        );
      case 'unavailable':
        return LoadFailureDetails(
          title: defaultTitle,
          message:
              'خدمة Firestore غير متاحة الآن. تحقق من الاتصال ثم حاول مرة أخرى.',
        );
      case 'not-found':
        return LoadFailureDetails(
          title: notFoundTitle ?? defaultTitle,
          message: 'تعذر العثور على البيانات المطلوبة.',
        );
    }
  }

  final mapped = mapException(error);
  return LoadFailureDetails(title: defaultTitle, message: mapped.message);
}
