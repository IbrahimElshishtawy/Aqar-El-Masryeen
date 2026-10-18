# خريطة تدفق العمليات البرمجية لكل زر في تطبيق الفلاتر (Flutter Buttons Workflow Map)
**مشروع عقار المصريين (Aqar El-Masryeen)**

---

## 📌 الفهرس العام
1. [وحدة المصادقة وتسجيل الدخول والحماية (Authentication & Security)](#1-وحدة-المصادقة-وتسجيل-الدخول-والحماية)
2. [وحدة المشروعات والعقارات (Properties & Units)](#2-وحدة-المشروعات-والعقارات)
3. [وحدة مبيعات الوحدات (Unit Sales)](#3-وحدة-مبيعات-الوحدات)
4. [وحدة الأقساط والتحصيل (Installments & Collections)](#4-وحدة-الأقساط-والتحصيل)
5. [وحدة المصروفات والتشوينات والموردين (Expenses & Procurement)](#5-وحدة-المصروفات-والتشوينات-والموردين)
6. [وحدة الشركاء وحسابات الدخول والتسويات (Partners & Settlements)](#6-وحدة-الشركاء-وحسابات-الدخول-والتسويات)
7. [لوحة المؤشرات العامة (Dashboard & Navigation)](#7-لوحة-المؤشرات-العامة)

---

## 1. وحدة المصادقة وتسجيل الدخول والحماية

### 1.1 زر "دخول" (`LoginScreen`)
- **الملف:** `lib/features/auth/presentation/screens/login_screen.dart`
- **الدالة المستدعاة:** `_submit()`
- **البروفايدر المسؤول:** `credentialLoginControllerProvider.notifier.loginWithEmailAndPassword()`
- **المدخلات:** البريد الإلكتروني (`_emailController`) + كلمة المرور (`_passwordController`).
- **ما يحدث في الخلفية:**
  1. التحقق من صيغة الإيميل وكلمة المرور عبر `AuthValidators`.
  2. استدعاء `FirebaseAuthRemoteDataSource.signInWithEmailAndPassword`.
  3. استرجاع بيانات المستخدم من `userProfileRemoteDataSource.fetchProfile(uid)`.
  4. حفظ التوكن ومساحة العمل `workspaceId` في `AuthLocalDataSource` (التخزين الآمن `FlutterSecureStorage`).
  5. تفعيل جلسة `authSessionProvider`.
- **النتيجة في الواجهة:** الانتقال التلقائي عبر `AppRouter` إلى شاشة الـ Dashboard الرئيسية `/dashboard`.

---

### 1.2 زر "إنشاء حساب" (`RegisterScreen`)
- **الملف:** `lib/features/auth/presentation/screens/register_screen.dart`
- **الدالة المستدعاة:** `_submit()`
- **البروفايدر:** `registerControllerProvider.notifier.register()`
- **المدخلات:** الاسم الكامل + الإيميل + كلمة المرور + تأكيد كلمة المرور.
- **ما يحدث في الخلفية:**
  1. إنشاء حساب في الفايربيز: `FirebaseAuth.createUserWithEmailAndPassword`.
  2. إنشاء مستند بروفايل في مسار `users/{uid}` بقيم أولية للمستخدم.
  3. إنشاء مساحة عمل افتراضية أو ربط المستخدم بالمساحة المحددة.
  4. تسجيل نشاط أولي في `ActivityRepository`.
- **النتيجة في الواجهة:** توجيه المستخدم لشاشة إكمال الملف الشخصي `/profile-completion`.

---

### 1.3 زر "حفظ ومتابعة" (`ProfileCompletionScreen`)
- **الملف:** `lib/features/auth/presentation/screens/profile_completion_screen.dart`
- **الدالة المستدعاة:** `_submitProfile()`
- **البروفايدر:** `profileSetupControllerProvider.notifier.completeProfile()`
- **المدخلات:** الاسم، رقم الهاتف، والدور الوظيفي (أدمن، محاسب، شريك).
- **ما يحدث في الخلفية:**
  1. تحديث مستند `users/{uid}` بالبيانات الجديدة.
  2. تحديث الـ `AppSession` لتعكس البيانات الكاملة.
- **النتيجة في الواجهة:** الانتقال إلى إعداد الأمان الحيوي `/biometric-setup`.

---

### 1.4 زر "تفعيل البصمة / تخطي" (`BiometricSetupScreen`)
- **الملف:** `lib/features/auth/presentation/screens/biometric_setup_screen.dart`
- **الدالة:** `_authenticateAndEnable()` أو `_skip()`
- **البروفايدر:** `securitySetupControllerProvider.notifier.enableBiometrics()`
- **ما يحدث في الخلفية:**
  - استدعاء مكتبة `local_auth` للتحقق من بصمة الإصبع أو الوجه.
  - في حال النجاح، يُخزن مفتاح تشفير في `SecureStorageKeys.biometricsEnabled`.
- **النتيجة في الواجهة:** الدخول المباشر إلى لوحة التحكم `/dashboard`.

---

### 1.5 زر "فتح القفل" (`UnlockScreen`)
- **الملف:** `lib/features/security/presentation/screens/unlock_screen.dart`
- **الدالة:** `_unlockWithBiometrics()` أو إدخال رمز PIN.
- **البروفايدر:** `unlockControllerProvider.notifier.unlock()`
- **ما يحدث في الخلفية:** مطابقة البصمة أو الـ PIN مع القيمة المشفرة محلياً وإلغاء حالة القفل `sessionLockProvider = false`.
- **النتيجة في الواجهة:** اختفاء شاشة القفل والعودة للشاشة السابقة فوراً.

---

### 1.6 زر "تسجيل الخروج" (`Logout Button`)
- **الملف:** `lib/features/profile/presentation/profile_screen.dart`
- **الدالة:** `_logout()`
- **البروفايدر:** `authSessionProvider.notifier.logout()`
- **ما يحدث في الخلفية:**
  1. إنهاء جلسة الفايربيز: `FirebaseAuth.signOut()`.
  2. مسح الكاش والبيانات الحساسة من `FlutterSecureStorage`.
  3. تصفير الـ Stream الخاص بالشركاء والوحدات.
- **النتيجة في الواجهة:** إعادة التوجيه الفوري لشاشة تسجيل الدخول `/login`.

---

## 2. وحدة المشروعات والعقارات

### 2.1 زر "إضافة مشروع" (`FloatingActionButton` في شاشة المشروعات)
- **الملف:** `lib/features/properties/presentation/properties_screen.dart`
- **الإجراء:** `context.push(AppRoutes.propertyForm)`
- **النتيجة في الواجهة:** فتح شاشة إنشاء مشروع جديد [PropertyFormScreen].

---

### 2.2 زر "حفظ المشروع" (`PropertyFormScreen`)
- **الملف:** `lib/features/properties/presentation/property_form_screen.dart`
- **الدالة المستدعاة:** `_save(existing)`
- **البروفايدر:** `propertyRepositoryProvider.save(property)`
- **المدخلات:** اسم المشروع، الموقع الجغرافي، عدد الوحدات، الوصف، وحالة المشروع (`planning`, `delivered`, `archived`).
- **ما يحدث في الخلفية:**
  1. التحقق من صحة المدخلات `_formKey.validate()`.
  2. حفظ أو تعديل مستند المشروع في `properties/{id}` في الفايرستور.
  3. تسجيل نشاط في `activityRepositoryProvider.log` بـ (`property_created` أو `property_updated`).
  4. تحديث الكاش المحلي تلقائياً.
- **النتيجة في الواجهة:** إغلاق الشاشة والرجوع لقائمة المشروعات مع ظهور المشروع فوراً.

---

### 2.3 زر "أرشفة / استعادة مشروع" (`Archive Button`)
- **الملف:** `lib/features/properties/presentation/widgets/property_record_tables.dart`
- **الدالة:** `propertyRepository.toggleArchive(propertyId)`
- **ما يحدث في الخلفية:**
  - تعديل الحقل `archived = true/false` في مستند الفايرستور.
  - إخفاء المشروع من القوائم النشطة وإظهاره فقط في الأرشيف.

---

## 3. وحدة مبيعات الوحدات

### 3.1 زر "إضافة مبيعات وحدة" (`UnitFormSheet`)
- **الملف:** `lib/features/sales/presentation/unit_form_sheet.dart`
- **الدالة المستدعاة:** `_submit()`
- **البروفايدر:** `salesRepositoryProvider.save(unit)`
- **المدخلات:** رقم الوحدة، الدور، المساحة، نوع الوحدة، اسم العميل، هاتفه، سعر الوحدة، المقدم، عدد أقساط الجدولة.
- **ما يحدث في الخلفية:**
  1. حساب المبلغ المتبقي: `remainingAmount = apartmentPrice - downPayment`.
  2. توليد `UUID` وحفظ الوحدة في مجموعة `units/{id}`.
  3. تحديث الكاش المحلي للوحدات [LocalCacheService].
  4. تسجيل العملية في سجل الأنشطة `activityRepository`.
- **النتيجة في الواجهة:** إغلاق الشاشة وتحديث جدول الوحدات بالبيانات وحسابات المشروع آلياً.

---

## 4. وحدة الأقساط والتحصيل

### 4.1 زر "توليد جدول الأقساط" (`InstallmentPlanFormSheet`)
- **الملف:** `lib/features/installments/presentation/installment_plan_form_sheet.dart`
- **الدالة المستدعاة:** `_submit()`
- **البروفايدر:** `installmentRepositoryProvider.savePlan()` و `saveInstallment()`
- **المدخلات:** الوحدة المستهدفة، عدد الأقساط، تاريخ البداية، الفاصل الزمني (أيام)، قيمة القسط.
- **ما يحدث في الخلفية:**
  1. حفظ خطة التقسيط الأساسية في مجموعة `installment_plans/{planId}`.
  2. حلقة تكرارية (`for loop`) لحفظ كل قسط في مسار `installments/{installmentId}` مع رقم تسلسلي `sequence` وتاريخ استحقاق `dueDate`.
  3. تعيين حالة كل قسط كـ `pending`.
  4. تسجيل نشاط في `activityRepository` باسم `installment_plan_created`.
- **النتيجة في الواجهة:** إغلاق النموذج وظهور جدول الأقساط الكامل في كشف حساب الوحدة.

---

### 4.2 زر "تسجيل تحصيل / سداد قسط" (`PaymentFormSheet`)
- **الملف:** `lib/features/payments/presentation/payment_form_sheet.dart`
- **الدالة المستدعاة:** `_submit()`
- **البروفايدر:** `paymentRepositoryProvider.save(payment)`
- **المدخلات:** قيمة الدفعة، تاريخ القبض، طريقة الدفع (كاش، تحويل بنكي، شيك)، والقسط المرتبط (إن وجد).
- **ما يحدث في الخلفية:**
  1. حفظ سجل المقبوضات في مجموعة `payments/{id}`.
  2. في حال كان السداد مرتبطاً بقسط، يتم استدعاء `installmentRepository.recordPayment()` لتحديث:
     - `paidAmount += amount`
     - إذا تم سداد كامل القيمة تتحول الحالة إلى `InstallmentStatus.paid`.
  3. إعادة حساب إجمالي المتحصلات للوحدة والمشروع.
  4. تسجيل العملية في سجل الأنشطة `activityRepository`.
- **النتيجة في الواجهة:** إغلاق الشاشة وتحديث مؤشر التحصيل وكروت المبالغ فوراً.

---

## 5. وحدة المصروفات والتشوينات والموردين

### 5.1 زر "إضافة مصروف مشروع" (`ExpenseFormSheet`)
- **الملف:** `lib/features/expenses/presentation/expense_form_sheet.dart`
- **الدالة المستدعاة:** `_submit()`
- **البروفايدر:** `expenseRepositoryProvider.save(expense)`
- **المدخلات:** المبلغ، بند الصرف (`construction`, `permits`, `labor`, `marketing`.. إلخ)، الشريك القائم بالصرف، والتاريخ.
- **ما يحدث في الخلفية:**
  1. حفظ المستند في الفايرستور داخل `expenses/{id}`.
  2. خصم المصروف من رصيد المشروع وإضافته لمصروفات الشريك الذي سدده.
  3. تسجيل الحدث في `activityRepository`.
- **النتيجة في الواجهة:** ظهور السجل فوراً في دفتر الأستاذ العام للمصروفات وتحديث إجمالي تكاليف المشروع.

---

### 5.2 زر "إضافة توريد مواد بناء" (`MaterialExpenseFormSheet`)
- **الملف:** `lib/features/expenses/presentation/material_expense_form_sheet.dart`
- **الدالة المستدعاة:** `_submit()`
- **البروفايدر:** `materialExpenseRepositoryProvider.save(material)`
- **المدخلات:** اسم المادة (حديد، أسمنت، طوب، رمل)، الكمية، سعر الوحدة، الإجمالي، واسم المورد.
- **ما يحدث في الخلفية:**
  1. حفظ الفاتورة في مجموعة `material_expenses/{id}`.
  2. ربط الفاتورة بحساب المورد وتحديث المديونية المستحقة له.
  3. تحديث جدول التشوينات للمشروع.
- **النتيجة في الواجهة:** إضافة الفاتورة لكشف حساب المورد والمشروع.

---

### 5.3 زر "سداد دفعة للمورد" (`SupplierPaymentSheet`)
- **الملف:** `lib/features/properties/presentation/widgets/supplier_payment_sheet.dart`
- **الدالة المستدعاة:** `_submit()`
- **البروفايدر:** `supplierPaymentRepositoryProvider.save(payment)`
- **المدخلات:** اسم المورد، المبلغ المسدد، التاريخ، الشريك المسدد.
- **ما يحدث في الخلفية:**
  1. تسجيل الدفعة في `supplier_payments/{id}`.
  2. خصم القيمة من المتبقي للمورد في دفتر حسابات الموردين.
  3. تسجيل النشاط وتحديث المؤشرات.
- **النتيجة في الواجهة:** تحديث مديونية المورد وإظهار السداد كبند رسمي في الجدول.

---

## 6. وحدة الشركاء وحسابات الدخول والتسويات

### 6.1 زر "حفظ الشريك / إنشاء الحساب" (`PartnerFormSheet`)
- **الملف:** `lib/features/partners/presentation/partner_form_sheet.dart`
- **الدالة المستدعاة:** `_submit()`
- **البروفايدر:** `partnerRepositoryProvider.upsert(partner)`
- **المدخلات:** اسم الشريك، البريد الإلكتروني، كلمة المرور (عند إنشاء حساب جديد)، خيار ربط الحساب.
- **ما يحدث في الخلفية:**
  1. **إذا كان حساباً جديداً:** استدعاء الدالة السحابية `provisionPartnerAccount` عبر `FirebaseFunctions` لإنشاء حساب Auth دون خروج الأدمن.
  2. حفظ بيانات الشريك في `partners/{partnerId}` شاملاً الحصة ورأس المال.
  3. ربط ملف المستخدم `users/{uid}` بسجل الشريك عبر `updateAccountLinkage`.
  4. تسجيل نشاط `partner_created`.
- **النتيجة في الواجهة:** ظهور الشريك الجديد في قائمة الشركاء وتفعيل حسابه للدخول الفوري.

---

### 6.2 زر "مراجعة وقبول طلب ربط شريك" (`_PendingRequestsSheet`)
- **الملف:** `lib/features/partners/presentation/widgets/pending_requests_sheet.dart`
- **الدالة المستدعاة:** `_accept(request)`
- **البروفايدر:** `userProfileRemoteDataSource.updateAccountLinkage()`
- **ما يحدث في الخلفية:**
  1. ربط الـ `uid` الخاص بالشريك بالسجل المالي المعتمد.
  2. تحديث حالة الإشعار إلى مقروء ومكتمل.
  3. فك أي ارتباطات سابقة متضاربة عبر `_unlinkOtherPartners`.
- **النتيجة في الواجهة:** اختفاء الطلب من قائمة المعلقات وتأكيد الارتباط الرسمي للشريك.

---

### 6.3 زر "إضافة قيد في دفتر الشريك" (`PartnerLedgerEntryFormSheet`)
- **الملف:** `lib/features/partners/presentation/partner_ledger_entry_form_sheet.dart`
- **الدالة المستدعاة:** `_submit()`
- **البروفايدر:** `partnerLedgerRepositoryProvider.saveAuthorized(entry)`
- **المدخلات:** نوع القيد (إيداع رأس مال `capitalContribution`، سحب أرباح `profitWithdrawal`، تسوية `settlement`)، المبلغ، والملاحظات.
- **ما يحدث في الخلفية:**
  1. حفظ المستند في مسار `partner_ledger/{id}`.
  2. توثيق المعرف المعتمد `authorizedBy: session.userId`.
  3. إرسال إشعار فوري للشريك بتحديث دفتره المالي.
  4. تسجيل الحدث في `ActivityRepository`.
- **النتيجة في الواجهة:** تحديث رصيد الشريك، مساهماته، وحسابات التسوية في لوحة الشركاء.

---

## 7. لوحة المؤشرات العامة (Dashboard)

### 7.1 أزرار فلترة النطاق (`DashboardScopeSelector`)
- **الملف:** `lib/features/dashboard/presentation/dashboard_screen.dart`
- **الدالة المستدعاة:** تغيير القيمة في `dashboardScopeProvider`
- **الخيارات:**
  - كل المشروعات (`all`)
  - مشروع محدد (`propertyId`)
  - شريك محدد (`partnerId`)
- **ما يحدث في الخلفية:**
  - يقوم `dashboardSnapshotProvider` بإعادة فلترة تدفقات البيانات المجمعة عبر `DashboardAssembler`.
  - إعادة تجميع الأرقام (المبيعات، المحصلات، المصروفات، صافي الأرباح) للنطاق المختار فقط دون الحاجة لاستدعاءات شبكة إضافية (In-Memory Stream Recomputation).
- **النتيجة في الواجهة:** تحديث الرسوم البيانية والأرقام وكروت الإحصائيات في جزء من الثانية.

---

### 7.2 زر التحديث اليدوي بالسحب (`RefreshIndicator`)
- **الملف:** `lib/features/dashboard/presentation/dashboard_screen.dart`
- **الإجراء:** `ref.refresh(dashboardSnapshotProvider)`
- **ما يحدث في الخلفية:**
  - إعادة تشغيل استعلامات الفايرستور وتفريغ الكاش المؤقت لإحضار أحدث التغييرات السحابية.
- **النتيجة في الواجهة:** ظهور مؤشر التحميل ثم تحديث الشاشة بأحدث البيانات.

---

## 🎯 ملخص هيكلي للأنماط المعمارية الموحدة لجميع الأزرار
جميع أزرار الإدخال والحفظ في التطبيق تخضع لنفس الدورة الهندسية المحكمة:
1. **التحقق من البيانات (Form Validation):** منع إرسال بيانات ناقصة أو غير صحيحة.
2. **التحقق من الجلسة (Session & Tenant Isolation):** إلزام وجود `workspaceId` و `userId` لمنع تداخل الحسابات.
3. **الحفظ المزدوج (Cloud + Local Cache):** الكتابة في Firestore مع تحديث الـ `LocalCacheService` لضمان سرعة فائقة وتجربة مستخدم لا تتعطل.
4. **سجل الرقابة الإلزامي (Audit Trail):** كل نقرة حفظ تؤدي لاستدعاء `activityRepositoryProvider.log` لتوثيق من قام بالعملية وتاريخها.
