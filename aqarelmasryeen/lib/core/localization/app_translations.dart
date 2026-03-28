import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppTranslations extends Translations {
  static const fallbackLocale = Locale('en', 'US');
  static const supportedLocales = [Locale('ar', 'EG'), Locale('en', 'US')];

  @override
  Map<String, Map<String, String>> get keys => {'ar_EG': _ar, 'en_US': _en};

  static const _ar = {
    'app_name': 'عقار المصريين',
    'welcome_title': 'إدارة مالية وعقارية بمستوى تنفيذي',
    'welcome_subtitle':
        'منصة موحدة لإدارة العقارات، المبيعات، المصروفات، والتحصيلات بواجهة عربية احترافية.',
    'get_started': 'ابدأ الآن',
    'sign_in': 'تسجيل الدخول',
    'create_account': 'إنشاء حساب',
    'phone_number': 'رقم الهاتف',
    'password': 'كلمة المرور',
    'confirm_password': 'تأكيد كلمة المرور',
    'full_name': 'الاسم الكامل',
    'email_optional': 'البريد الإلكتروني (اختياري)',
    'continue': 'متابعة',
    'verify_code': 'تأكيد الرمز',
    'otp_title': 'تحقق من رقم الهاتف',
    'otp_subtitle': 'أدخل الرمز المرسل إلى رقمك لإكمال الدخول الآمن.',
    'send_code': 'إرسال الرمز',
    'use_otp': 'الدخول عبر رمز التحقق',
    'complete_profile': 'استكمال البيانات',
    'enable_biometrics': 'تفعيل الدخول الحيوي',
    'skip_for_now': 'لاحقاً',
    'dashboard': 'لوحة التحكم',
    'properties': 'العقارات',
    'workers': 'العاملون',
    'units': 'الوحدات',
    'sales': 'المبيعات',
    'expenses': 'المصروفات',
    'reports': 'التقارير',
    'notifications': 'الإشعارات',
    'settings': 'الإعدادات',
    'logout': 'تسجيل الخروج',
    'total_properties': 'إجمالي العقارات',
    'total_sales': 'إجمالي المبيعات',
    'total_expenses': 'إجمالي المصروفات',
    'remaining_receivables': 'المتبقي للتحصيل',
    'overdue_installments': 'أقساط متأخرة',
    'latest_activity': 'أحدث النشاط',
    'recent_notifications': 'أحدث الإشعارات',
    'premium_workspace': 'تشغيل مالي وعقاري في مساحة عمل واحدة',
    'trusted_devices': 'أمان الأجهزة الموثوقة',
    'role_owner': 'مالك / مدير',
    'role_accountant': 'محاسب',
    'role_employee': 'موظف',
    'role_viewer': 'مشاهد',
    'unlock_workspace': 'فتح مساحة العمل',
    'biometric_quick_login': 'الدخول السريع بالبصمة أو رمز الجهاز',
    'password_setup_title': 'أنشئ كلمة مرور آمنة',
    'password_setup_subtitle':
        'سيتم ربط كلمة المرور بحساب Firebase نفسه لتسجيل الدخول برقم الهاتف لاحقاً.',
    'profile_subtitle':
        'أكمل بيانات الحساب الرئيسية ليصبح النظام جاهزاً للبدء وإضافة الفريق والعقارات.',
    'biometric_prompt_subtitle':
        'فعّل الدخول الحيوي لتأمين الوصول السريع على هذا الجهاز الموثوق.',
    'add_worker': 'إضافة مستخدم',
    'add_property': 'إضافة عقار',
    'profile': 'الحساب',
    'account_secure': 'الحساب محمي',
    'firebase_setup_needed': 'يلزم ربط Firebase لإكمال التحقق والإشعارات.',
    'desktop_otp_note':
        'التحقق عبر الهاتف متاح عملياً على الأجهزة المحمولة. استخدم الهاتف للتسجيل الأول، ثم ادخل من سطح المكتب برقم الهاتف وكلمة المرور.',
  };

  static const _en = {
    'app_name': 'Aqar El Masryeen',
    'welcome_title': 'Executive-grade real estate finance operations',
    'welcome_subtitle':
        'One premium workspace for properties, expenses, collections, and sales operations.',
    'get_started': 'Get Started',
    'sign_in': 'Sign In',
    'create_account': 'Create Account',
    'phone_number': 'Phone Number',
    'password': 'Password',
    'confirm_password': 'Confirm Password',
    'full_name': 'Full Name',
    'email_optional': 'Email (Optional)',
    'continue': 'Continue',
    'verify_code': 'Verify Code',
    'otp_title': 'Verify phone number',
    'otp_subtitle':
        'Enter the SMS verification code to complete your secure sign-in.',
    'send_code': 'Send Code',
    'use_otp': 'Use OTP Instead',
    'complete_profile': 'Complete Profile',
    'enable_biometrics': 'Enable Biometrics',
    'skip_for_now': 'Skip for now',
    'dashboard': 'Dashboard',
    'properties': 'Properties',
    'workers': 'Workers',
    'units': 'Units',
    'sales': 'Sales',
    'expenses': 'Expenses',
    'reports': 'Reports',
    'notifications': 'Notifications',
    'settings': 'Settings',
    'logout': 'Logout',
    'total_properties': 'Total Properties',
    'total_sales': 'Total Sales',
    'total_expenses': 'Total Expenses',
    'remaining_receivables': 'Remaining Receivables',
    'overdue_installments': 'Overdue Installments',
    'latest_activity': 'Latest Activity',
    'recent_notifications': 'Recent Notifications',
    'premium_workspace': 'Financial and property operations in one workspace',
    'trusted_devices': 'Trusted device security',
    'role_owner': 'Owner / Admin',
    'role_accountant': 'Accountant',
    'role_employee': 'Employee',
    'role_viewer': 'Viewer',
    'unlock_workspace': 'Unlock Workspace',
    'biometric_quick_login': 'Quick unlock with biometrics or device passcode',
    'password_setup_title': 'Create a secure password',
    'password_setup_subtitle':
        'This password is linked to the same Firebase account for future phone + password sign-in.',
    'profile_subtitle':
        'Complete the core account details so the workspace is ready for team and property setup.',
    'biometric_prompt_subtitle':
        'Enable biometric unlock for fast secure access on this trusted device.',
    'add_worker': 'Add Worker',
    'add_property': 'Add Property',
    'profile': 'Profile',
    'account_secure': 'Account Secured',
    'firebase_setup_needed':
        'Firebase configuration is required to enable verification and messaging.',
    'desktop_otp_note':
        'Phone OTP is practically supported on mobile first. Use a phone for initial registration, then sign in on desktop with phone + password.',
  };
}
