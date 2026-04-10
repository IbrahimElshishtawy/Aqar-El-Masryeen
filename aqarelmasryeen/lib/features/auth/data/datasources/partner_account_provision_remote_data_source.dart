import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PartnerAccountProvisionRemoteDataSource {
  PartnerAccountProvisionRemoteDataSource(this._functions);

  final FirebaseFunctions _functions;

  Future<AppUser> provisionPartnerAccount({
    required String fullName,
    required String email,
    required String password,
    String? createdBy,
    String? createdByName,
    String? workspaceId,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('provisionPartnerAccount')
          .call(<String, dynamic>{
            'fullName': fullName,
            'email': email,
            'password': password,
            'createdBy': createdBy,
            'createdByName': createdByName,
            'workspaceId': workspaceId,
          });

      final payload = Map<String, dynamic>.from(result.data as Map);
      final userMap = Map<String, dynamic>.from(
        payload['user'] as Map? ?? const <String, dynamic>{},
      );
      final uid = userMap['uid'] as String? ?? '';
      if (uid.trim().isEmpty) {
        throw const AppException(
          'تم إنشاء الحساب لكن تعذر قراءة بياناته من Cloud Functions.',
          code: 'partner_account_missing_payload',
        );
      }
      return AppUser.fromMap(uid, userMap);
    } on FirebaseFunctionsException catch (error) {
      throw _mapFunctionsException(error);
    }
  }

  Future<Map<String, int>> backfillAuthProfiles({String? workspaceId}) async {
    try {
      final result = await _functions
          .httpsCallable('backfillAuthProfiles')
          .call(<String, dynamic>{'workspaceId': workspaceId});
      final payload = Map<String, dynamic>.from(result.data as Map);
      return <String, int>{
        'createdCount': (payload['createdCount'] as num?)?.toInt() ?? 0,
        'updatedLookupCount':
            (payload['updatedLookupCount'] as num?)?.toInt() ?? 0,
      };
    } on FirebaseFunctionsException catch (error) {
      throw _mapFunctionsException(error);
    }
  }
}

AppException _mapFunctionsException(FirebaseFunctionsException error) {
  switch (error.code) {
    case 'already-exists':
      return const AppException(
        'يوجد حساب مسجل بهذا البريد الإلكتروني بالفعل.',
        code: 'email_in_use',
      );
    case 'invalid-argument':
      return AppException(
        error.message ?? 'تحقق من بيانات الحساب المدخلة ثم حاول مرة أخرى.',
        code: 'invalid_argument',
      );
    case 'permission-denied':
      return const AppException(
        'ليس لديك صلاحية لإنشاء حسابات الشركاء.',
        code: 'permission_denied',
      );
    case 'unavailable':
      return const AppException(
        'خدمة إنشاء حسابات الشركاء غير متاحة الآن.',
        code: 'functions_unavailable',
      );
    case 'failed-precondition':
      return AppException(
        error.message ??
            'إعداد Cloud Functions غير مكتمل. تحقق من النشر ثم أعد المحاولة.',
        code: 'functions_failed_precondition',
      );
    case 'not-found':
    case 'unimplemented':
      return const AppException(
        'وظيفة إنشاء حسابات الشركاء غير منشورة بعد.',
        code: 'functions_not_ready',
      );
    default:
      return AppException(
        error.message ?? 'تعذر إنشاء حساب الشريك عبر Cloud Functions.',
        code: error.code,
      );
  }
}
