# مصفوفة تكافؤ الميزات الشاملة: Flutter Mobile مقابل Next.js Web
## Aqar El-Masryeen Platform Feature-Parity Matrix

تاريخ التدقيق والتنفيذ: أكتوبر 2026  
المهندس المسؤول: كبير مهندسي البرمجيات والنظم المالية وحماية التطبيقات  
الحالة العامة: **مكتمل بالكامل (Full Parity & Production Build Verified)**

---

## 1. ملخص تنفيذي (Executive Summary)

تم إجراء تدقيق ومراجعة شاملة لجميع شاشات ومكونات تطبيق الهواتف الذكية (Flutter) المبني على قاعدة بيانات Firestore (`aqarr-cfd58`) ومقارنتها بتطبيق الويب Next.js (`aqar_web_converter`).  
تم رصد كافة الفجوات الوظيفية، لاسيما في النظام المالي والمحاسبي، تسوية حسابات الشركاء، مراقبة أسعار العقارات والوحدات، ومصادقة الدخول المحمية لصلاحيات المحاسبة.

تم نقل وتطبيق كافة العمليات الحسابية بدقة متناهية (`Money` class بـ BigInt بالهللات/القروش لمنع أخطاء الدقة العشرية `IEEE 754`)، وتم توحيد صيغ الحسابات المالية مع المحركات الأصلية في Flutter:
- `PartnerLedgerCalculator`
- `PartnerSettlementCalculator`
- `MaterialsLedgerCalculator`
- `UnitSalesCalculator`

---

## 2. جدول مقارنة الميزات الشامل (Comprehensive Feature Parity Table)

| المعرف | الميزة والغرض التجاري | مسار وتدفق العمل في Flutter | الجداول والخدمات المرتبطة | التنفيذ المكافئ في Next.js Web | حالة التكافؤ | الاختبارات والتحقق |
|---|---|---|---|---|---|---|
| **ACC-01** | لوحة قيادة المحاسبة المالية الموحدة (Company Accounting Dashboard) | `DashboardScreen` / `SummaryCard` / إجماليات الإيرادات والمصروفات والتدفق النقدي | مجموعات Firestore: `properties`, `expenses`, `installments`, `material_expenses` | صفحة `/dashboard` متصلة بـ `/api/accounting/reconciliation` و `/api/accounting/data` | **مكتمل 100% (Complete)** | فحص جمع المقبوضات والمصروفات ومعدل التحصيل ونسبة الإنجاز |
| **ACC-02** | حسابات الشركاء والمسحوبات والمساهمات (Partner Ledgers & Contributions) | `PartnersListScreen`, `PartnerDetailScreen`, `AddPartnerEntryDialog` | كولكشن `partners`, `partner_ledger_entries`, `expenses (paidByPartnerId)` | صفحة `/partners`، محرك `AccountingEngine.calculatePartnerLedgers` | **مكتمل 100% (Complete)** | اختبارات تكافؤ مع `partner_ledger_calculator.dart` بدقة تامة |
| **ACC-03** | التسويات المالية وتوزيع الأرباح بين الشركاء والشركة (Syndicate Settlements) | `PartnerSettlementCalculator.dart`، حساب التعرض المالي ونسبة الحصة والفرق الصافي | `partners`, `properties`, `expenses`, `material_expenses` | محرك `calculateSettlements` ودالة `reconcileCompany` في Next.js | **مكتمل 100% (Complete)** | اختبار إجمالي الفروق الصفرية (Zero-sum balance check) |
| **ACC-04** | إدارة مصروفات المشاريع ومشتريات المواد (Material Expenses & Invoices) | `ExpensesListScreen`, `AddMaterialExpenseScreen`, فواتير الموردين والكميات | `expenses`, `material_expenses`, `supplier_payments` | صفحة `/expenses`، محرك `calculateSupplierLedger`، فلترة الموردين | **مكتمل 100% (Complete)** | اختبار تسوية فواتير الموردين ومقارنة المسدد بالمتبقي |
| **ACC-05** | متابعة الأقساط والمقبوضات والمستحقات (Installments & Receivables) | `InstallmentsListScreen`, `CollectInstallmentDialog` | `installments`, `payments`, `units` | صفحة `/installments`، فلترة الحالات (مدفوع، معلق، متأخر) وزر التحصيل | **مكتمل 100% (Complete)** | التحقق من عدم احتساب الأقساط المعلقة كإيراد فعلي محقق |
| **ACC-06** | حماية قسم المحاسبة ومصادقة الدخول المخصصة (Dedicated Accounting Login & RBAC) | `AuthGate`, `FirebaseAuth`, مستويات الصلاحيات | `users`, `system_roles`, `user_metadata` | صفحة `/accounting/login`، كوكيز `HttpOnly` مشفرة HMAC-SHA256، `middleware.ts` | **مكتمل 100% (Complete)** | اختبار منع الدخول غير المصرح به، التحقق من صلاحيات الأدوار الأربعة |
| **ACC-07** | عزل بيانات الشركاء (Partner Privacy Isolation) | في Flutter: يرى الشريك بياناته الخاصة فقط بناءً على `partnerId` | `partners/{partnerId}`, `partner_ledger_entries` | منع استعراض شريك لبيانات شريك آخر عبر الـ API أو الواجهة | **مكتمل 100% (Complete)** | اختبار وحدة يتحقق من رفض طلب كشف حساب شريك من حساب شريك آخر |
| **ACC-08** | مراقبة وتتبع أسعار العقارات والوحدات (Real-Estate Price Monitoring) | تعديل أسعار الطرح وسعر المتر وتاريخ التعديل في تفاصيل الوحدة | `properties`, `units`, `price_history` | صفحة `/price-monitoring`، محرك `PriceMonitoringEngine`، نافذة التعديل والتدقيق | **مكتمل 100% (Complete)** | التحقق من أن رفع سعر الطرح لا يُحسب كربح محقق، وتوليد سجل تدقيق غير قابل للتلاعب |
| **ACC-09** | التقارير المالية وكشوف الحسابات القابلة للتصدير (Financial Reports & Export) | `FinancialReportsScreen`, فلترة حسب التاريخ والمشروع وتصدير PDF/CSV | `expenses`, `installments`, `partner_ledger_entries` | صفحة `/reports` مع فلاتر التاريخ، تصدير CSV فوري، وطباعة كشوفات معتمدة | **مكتمل 100% (Complete)** | اختبار مطابقة الأرقام بين شاشة التقارير ولوحة القيادة الموحدة |
| **PROP-01** | استعراض وإدارة المشاريع العقارية (Properties & Projects) | `ProjectsListScreen`, `ProjectDetailScreen` | `properties`, `units` | صفحة `/properties` وصفحة تفاصيل المشروع `/properties/[id]` | **مكتمل 100% (Complete)** | فحص الربط بين نسب الإنجاز والتكاليف المحسوبة |
| **UNIT-01** | إدارة الوحدات والمبيعات وحجز العملاء (Units & Sales Booking) | `UnitDetailScreen`, `BookUnitDialog` | `units`, `customers`, `installments` | جدول الوحدات، فلتر الحالات، وعرض تفاصيل السداد في `/properties/[id]` | **مكتمل 100% (Complete)** | التحقق من تسجيل سعر التعاقد والمقدم والأقساط المرتبطة |

---

## 3. التدقيق التفصيلي للميزات المحاسبية المنفذة في Next.js

### 3.1. مصفوفة الصلاحيات وخريطة الأدوار (RBAC Matrix)
- **مدير المنظومة (`admin`)**: صلاحيات كاملة، تعديل المصروفات، اعتماد التسويات، إدارة المستخدمين، تعديل أسعار الطرح.
- **رئيس الحسابات (`accountant`)**: قيد وسداد المصروفات، تحصيل الأقساط، كشوف حساب الموردين والشركاء، دون صلاحية حذف المستخدمين أو الشركاء.
- **الشريك (`partner`)**: مقيد بالاطلاع فقط على كشف حسابه الخاص (`view_own_partner_ledger`) ومؤشرات أسعار السوق العقاري.
- **المراقب / المشاهد (`viewer`)**: صلاحية قراءة عامة للأسعار ومؤشرات العرض دون صلاحية تعديل السجلات المالية.

### 3.2. الدقة المالية العشرية
- تم استبدال جميع عمليات الحساب الثنائي العائمة بمكتبة `Money` التي تعتمد على `BigInt` بالهللات، مما يمنع انحراف الكسور نهائياً.
- حساب الفروق بين المستحق والمدفوع يتبع معادلة:
  $$\Delta = \text{TotalPaid} - \text{TotalExposure} \times \text{ShareRatio}$$
  - إذا كان الناتج موجباً: الشركة/المشروع مدين للشريك بهذا المبلغ.
  - إذا كان الناتج سالباً: الشريك مدين للشركة/المشروع بهذا المبلغ.

### 3.3. مراقبة الأسعار وتاريخ التعديلات
- تم تدشين مسار `/price-monitoring` مع حساب:
  - السعر الحالي وسعر المتر المربع.
  - السعر السابق، ومقدار التغير المطلق والنسبي المئوي.
  - تسجيل هوية القائم بالتعديل والوقت وسبب التعديل في سجل `PriceHistoryRecord`.
  - تنبيه تلقائي في حال تجاوز التعديل نسبة 20% لتفادي الأخطاء البشرية.
