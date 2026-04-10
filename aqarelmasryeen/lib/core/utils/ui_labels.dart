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
    case 'unit_deleted':
      return 'حذف الوحدة';
    case 'unit_expense_created':
      return 'أضاف مصروف وحدة';
    case 'unit_expense_updated':
      return 'حدّث مصروف الوحدة';
    case 'material_expense_created':
      return 'أضاف فاتورة مواد';
    case 'material_expense_updated':
      return 'حدّث فاتورة مواد';
    case 'supplier_payment_recorded':
      return 'سجل دفعة مورد';
    case 'installment_plan_created':
      return 'أنشأ خطة أقساط';
    case 'installment_created':
      return 'أضاف قسطًا';
    case 'installment_updated':
      return 'حدّث القسط';
    case 'payment_recorded':
      return 'سجل تحصيلًا';
    case 'payment_created':
      return 'سجل تحصيلًا';
    case 'payment_updated':
      return 'حدّث التحصيل';
    case 'partner_created':
      return 'أضاف شريكًا';
    case 'partner_updated':
      return 'حدّث بيانات الشريك';
    case 'partner_ledger_created':
      return 'أضاف حركة شريك';
    case 'partner_ledger_updated':
      return 'حدّث حركة شريك';
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
    case 'unit_expense':
      return 'مصروف الوحدة';
    case 'material_supplier':
      return 'مورد';
    case 'material_expense':
      return 'مواد بناء';
    case 'installment_plan':
      return 'خطة أقساط';
    case 'installment':
      return 'قسط';
    case 'payment':
      return 'تحصيل';
    case 'partner':
      return 'شريك';
    case 'partner_ledger':
      return 'حركة شريك';
    default:
      return entityType;
  }
}
