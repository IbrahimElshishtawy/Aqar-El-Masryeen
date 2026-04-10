
# System Refactor Plan (Flutter + Firebase)

## 1) المشاكل الحالية التي كانت تؤثر على الترابط

1. **اختلاط محتمل للبيانات بين الجلسات**
   - بعض مصادر البيانات كانت تُقرأ مع Cache عام (global cache keys) بدون تنظيف شامل بعد تسجيل الخروج.
   - هذا كان قد يؤدي لظهور بيانات سابقة مؤقتًا بعد تبديل الحساب.

2. **Dashboard يقرأ كل البيانات الخام مباشرة**
   - القراءة كانت شاملة ثم التجميع مباشرة، بدون طبقة واضحة لتحديد نطاق البيانات حسب الحساب/الشريك/الـ workspace.
   - المستخدم الجديد غير المرتبط كان ممكن يشاهد أرقامًا لا تخصه.

3. **غياب طبقة Scope مركزية**
   - لم يكن هناك كلاس موحد يحدد أي بيانات تعتبر "مرئية" لهذا المستخدم قبل الحسابات المالية.

---

## 2) التعديلات التي تم تنفيذها في هذا التحديث

### A) إضافة طبقة Scope للـ Dashboard
تمت إضافة ملف جديد:
- `lib/features/dashboard/domain/dashboard_scope.dart`

الملف الجديد يقدم:
- `DashboardScopeResolver`: يحدد نطاق البيانات المرئية حسب:
  - `currentUserId`
  - `AppUser.workspaceId`
  - علاقة المستخدم بالشركاء المرتبطين
  - المشاريع والوحدات والأقساط التابعة لهذا النطاق
- `DashboardScopedData`: حاوية نظيفة لكل القوائم بعد التصفية.

### B) ربط الـ Dashboard بالتصفية قبل التجميع
تم تعديل:
- `lib/features/dashboard/presentation/dashboard_providers.dart`

التعديل أصبح:
1. تحميل البيانات الخام من repositories.
2. تمريرها إلى `DashboardScopeResolver`.
3. تمرير البيانات المفلترة فقط إلى:
   - `DashboardSnapshotBuilder`
   - `PartnerLedgerCalculator`

**النتيجة:**
- المستخدم الجديد غير المرتبط يظهر له Dashboard بصفر بشكل صحيح (إلا إذا كانت له بيانات منشأة بنفسه).
- المستخدم المرتبط تظهر له بيانات النطاق المرتبط بدل البيانات العامة.

### C) إصلاح منع اختلاط البيانات عند Logout / تبديل الحساب
تم تعديل:
- `lib/features/auth/data/repositories/firebase_auth_repository_impl.dart`
- `lib/features/auth/data/firebase_auth_repository.dart`

التعديل أصبح:
- عند `signOut`:
  - مسح بيانات الجلسة الحساسة من Secure Storage.
  - مسح **كل الـ cache** ذات البادئة `cache.`.
  - ثم تنفيذ `FirebaseAuth.signOut()`.
- عند مراقبة session وعند `user == null`:
  - يتم أيضًا تنظيف cache بنفس الأسلوب.

**النتيجة:**
- منع تسرب أرقام dashboard والبيانات المؤقتة من مستخدم لآخر.
- بداية نظيفة للحساب الجديد بعد تسجيل الدخول.

---

## 3) ما الذي تغير وظيفيًا حسب الوحدات المطلوبة

### Home Dashboard
- أصبح الحساب يعتمد على بيانات بعد Scope filtering بدل البيانات العامة.
- أي تحديث في Firestore ينعكس realtime عبر StreamProvider كما هو، لكن ضمن نطاق الحساب الصحيح.

### الحسابات والشركاء
- الاعتماد على `workspaceId + partner/user linkage` في تحديد البيانات المرئية للـ Dashboard.

### الوحدات / المبيعات / التحصيلات / الأقساط
- التصفية الآن تبدأ بالمشاريع المرئية، ثم الوحدات التابعة، ثم الأقساط والمدفوعات.
- هذا يحافظ على ترابط الأرقام ومنع التلوث بين حسابات مختلفة.

### المصروفات / الموردين
- المصروفات والمواد ومدفوعات الموردين أصبحت تُحتسب فقط للمشاريع الواقعة داخل Scope المرئي.

### الإشعارات
- هذا التحديث ركّز على ترابط الأرقام + عزل الجلسات.
- إشعارات FCM موجود لها بنية في المشروع، لكن يُنصح بخطة المرحلة التالية أدناه لإكمال السيناريو الإنتاجي الكامل.

---

## 4) هيكل Firebase المقترح النهائي (Production-ready)

> الهدف: توحيد الربط بين كل كيانات النظام عبر `workspaceId` + `createdBy/updatedBy` + مفاتيح العلاقات.

### Collections الأساسية
- `users/{uid}`
- `partners/{partnerId}`
- `properties/{propertyId}`
- `units/{unitId}`
- `installment_plans/{planId}`
- `installments/{installmentId}`
- `payments/{paymentId}`
- `expenses/{expenseId}`
- `material_expenses/{materialExpenseId}`
- `supplier_payments/{supplierPaymentId}`
- `notifications/{notificationId}`
- `activity_logs/{activityId}`

### Fields إلزامية مقترحة لكل مستندات business
- `workspaceId: string`
- `createdBy: string`
- `updatedBy: string`
- `createdAt: timestamp`
- `updatedAt: timestamp`
- `archived: bool` (عند الحاجة)

### ربط المستخدم بالحساب
- `users/{uid}.workspaceId`
- `users/{uid}.linkedPartnerId`
- `users/{uid}.linkedPartnerName`

### قاعدة المستخدم الجديد بصفر
- عند إنشاء مستخدم بدون ربط شريك/Workspace فعلي:
  - لا تُنشأ له كيانات projects/units/payments/expenses.
  - dashboard يعتمد على scope الفارغ = أرقام صفر.

---

## 5) Firestore Rules (نسخة Development + Production)

## Development (مرنة لاختبارات الفريق)
- السماح للمستخدم المصدق فقط `request.auth != null`.
- تقييد القراءة/الكتابة بحسب `workspaceId` عندما يكون field موجودًا.

## Production (أكثر أمانًا)
- لا قراءة/كتابة إلا إذا:
  1. `request.auth.uid != null`
  2. `resource.data.workspaceId == user.workspaceId`
  3. أو المستخدم Admin ضمن claims.
- منع تعديل حقول السيادة مثل:
  - `createdBy`, `createdAt`, `workspaceId` بعد الإنشاء.
- السماح بتعديل `updatedBy/updatedAt` فقط عند مطابقة `request.auth.uid`.

> ملاحظة: يلزم إضافة `workspaceId` لكل collections business بالكامل قبل تشديد قواعد الإنتاج.

---

## 6) Firestore Indexes المطلوبة (نموذج عام)

1. `expenses`: `workspaceId ASC, archived ASC, date DESC`
2. `payments`: `workspaceId ASC, receivedAt DESC`
3. `installments`: `workspaceId ASC, dueDate ASC, status ASC`
4. `units`: `workspaceId ASC, propertyId ASC, updatedAt DESC`
5. `properties`: `workspaceId ASC, archived ASC, updatedAt DESC`
6. `material_expenses`: `workspaceId ASC, propertyId ASC, date DESC`
7. `supplier_payments`: `workspaceId ASC, propertyId ASC, paidAt DESC`
8. `notifications`: `userId ASC, isRead ASC, createdAt DESC`

---

## 7) Auth + Session أفضل ممارسة لإنشاء مستخدمين بدون كسر الجلسة

- يفضّل إنشاء حسابات الشركاء عبر **Cloud Functions + Admin SDK**.
- في هذا المشروع يوجد fallback على isolated app provisioning بالفعل.
- لا تستخدم `createUserWithEmailAndPassword` على نفس Firebase app للجلسة الحالية مباشرة.

---

## 8) الإشعارات في الخلفية (خطة إكمال عملية)

1. حفظ FCM tokens في `users/{uid}.fcmTokens` وتحديثها دوريًا.
2. Cloud Scheduler + Cloud Functions:
   - وظيفة يومية/كل ساعة تفحص الأقساط المتأخرة والقريبة.
3. كتابة Notification داخل Firestore + إرسال FCM بنفس الوقت.
4. عند الضغط على الإشعار:
   - route payload يفتح الشاشة الصحيحة داخل التطبيق.
5. دعم Arabic/RTL في نصوص الإشعار والعناوين.

---

## 9) قائمة الملفات التي تم تعديلها/إضافتها في هذا التحديث

### ملفات جديدة
- `lib/features/dashboard/domain/dashboard_scope.dart`

### ملفات معدلة
- `lib/features/dashboard/presentation/dashboard_providers.dart`
- `lib/features/auth/data/repositories/firebase_auth_repository_impl.dart`
- `lib/features/auth/data/firebase_auth_repository.dart`

---

## 10) سبب كل Refactor

1. **Scope Resolver**
   - لفصل مسؤولية "تحديد البيانات المرئية" عن provider والتجميع المالي.
2. **تصفية قبل الحساب**
   - لضمان أرقام dashboard صحيحة لكل حساب وعدم حساب بيانات لا تخص المستخدم.
3. **تنظيف cache عند logout/auth-null**
   - لمنع اختلاط بيانات الجلسات وتحقيق سلوك آمن ومتوقع.

---

## 11) المرحلة التالية المقترحة (Priority)

1. إضافة `workspaceId` فعليًا لكل models + repositories أثناء save/query.
2. ترحيل بيانات Firestore القديمة migration script.
3. تحديث Firestore Rules الإنتاجية الصارمة.
4. توليد `firestore.indexes.json` نهائي بناءً على الاستعلامات بعد الترحيل.
5. استكمال pipeline إشعارات الأقساط المتأخرة/القريبة عبر Cloud Scheduler.
