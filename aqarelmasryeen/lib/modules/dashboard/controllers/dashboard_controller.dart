import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/data/repositories/auth_repository.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final SessionService _sessionService = Get.find();

  final selectedIndex = 0.obs;

  final metrics = const [
    DashboardMetric('total_properties', '12', '+2 this month', 'domain'),
    DashboardMetric('total_sales', 'EGP 26.4M', '+18% growth', 'payments'),
    DashboardMetric('total_expenses', 'EGP 8.7M', '17 categories tracked', 'receipt_long'),
    DashboardMetric('remaining_receivables', 'EGP 11.2M', '42 active contracts', 'account_balance_wallet'),
    DashboardMetric('overdue_installments', '16', 'Needs follow-up today', 'notification_important'),
  ];

  final activities = const [
    'دفعة جديدة تم تسجيلها لعقد A-204 بقيمة 180,000 جنيه',
    'تمت إضافة مصروفات كهرباء لمشروع تلال التجمع',
    'تم تعيين محاسب جديد على مشروع Palm View',
  ];

  final propertyCards = const [
    PropertyPreview(
      name: 'Palm View Residence',
      code: 'PVR-01',
      location: 'القاهرة الجديدة',
      unitCount: 48,
      soldUnits: 21,
      availableUnits: 19,
      totalSales: 'EGP 13.8M',
      totalExpenses: 'EGP 4.1M',
      remainingReceivables: 'EGP 5.2M',
      status: 'Active',
      progress: 0.58,
    ),
    PropertyPreview(
      name: 'Nile Crown Towers',
      code: 'NCT-04',
      location: 'المعادي',
      unitCount: 32,
      soldUnits: 17,
      availableUnits: 10,
      totalSales: 'EGP 9.4M',
      totalExpenses: 'EGP 2.8M',
      remainingReceivables: 'EGP 3.6M',
      status: 'Construction',
      progress: 0.44,
    ),
    PropertyPreview(
      name: 'East Gate Plaza',
      code: 'EGP-09',
      location: 'العاصمة الإدارية',
      unitCount: 64,
      soldUnits: 41,
      availableUnits: 15,
      totalSales: 'EGP 21.7M',
      totalExpenses: 'EGP 7.9M',
      remainingReceivables: 'EGP 8.3M',
      status: 'Collection',
      progress: 0.72,
    ),
  ];

  void selectSection(int index) {
    selectedIndex.value = index;
    if (index > 0) {
      Get.snackbar(
        'Aqar El Masryeen',
        'Module routing is prepared and will be connected in the next phase.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    await _sessionService.clearSession();
    Get.offAllNamed(AppRoutes.login);
  }
}

class DashboardMetric {
  const DashboardMetric(this.titleKey, this.value, this.caption, this.iconName);

  final String titleKey;
  final String value;
  final String caption;
  final String iconName;
}

class PropertyPreview {
  const PropertyPreview({
    required this.name,
    required this.code,
    required this.location,
    required this.unitCount,
    required this.soldUnits,
    required this.availableUnits,
    required this.totalSales,
    required this.totalExpenses,
    required this.remainingReceivables,
    required this.status,
    required this.progress,
  });

  final String name;
  final String code;
  final String location;
  final int unitCount;
  final int soldUnits;
  final int availableUnits;
  final String totalSales;
  final String totalExpenses;
  final String remainingReceivables;
  final String status;
  final double progress;
}
