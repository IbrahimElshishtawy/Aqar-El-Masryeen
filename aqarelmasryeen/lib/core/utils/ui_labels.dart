String activityActionLabel(String action) {
  switch (action) {
    case 'register':
      return 'أنشأ حسابًا';
    case 'login':
      return 'سجل الدخول';
    case 'logout':
      return 'سجل الخروج';
    case 'profile_completed':
      return 'أكمل الملف الشخصي';
    case 'security_preferences_updated':
      return 'حدّث إعدادات الأمان';
    case 'property_created':
      return 'أنشأ عقارًا';
    case 'property_updated':
      return 'حدّث العقار';
    case 'property_archived':
      return 'أرشف العقار';
    case 'expense_created':
      return 'أضاف مصروفًا';
    case 'expense_updated':
      return 'حدّث المصروف';
    case 'expense_deleted':
      return 'حذف المصروف';
    case 'unit_created':
      return 'أضاف وحدة';
    case 'unit_updated':
      return 'حدّث الوحدة';
    case 'installment_plan_created':
      return 'أنشأ خطة أقساط';
    case 'payment_recorded':
      return 'سجل تحصيلًا';
    case 'partner_created':
      return 'أضاف شريكًا';
    case 'partner_updated':
      return 'حدّث بيانات الشريك';
    default:
      return action.replaceAll('_', ' ');
  }
}

String entityTypeLabel(String entityType) {
  switch (entityType) {
    case 'user':
      return 'مستخدم';
    case 'property':
      return 'عقار';
    case 'expense':
      return 'مصروف';
    case 'unit':
      return 'وحدة';
    case 'installment_plan':
      return 'خطة أقساط';
    case 'payment':
      return 'تحصيل';
    case 'partner':
      return 'شريك';
    default:
      return entityType;
  }
}
