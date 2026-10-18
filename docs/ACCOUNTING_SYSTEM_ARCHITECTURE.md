# بنية النظام المحاسبي والمالي: منصة عقار المصريين
## Accounting System Architecture & Financial Specifications

**الإصدار:** 1.0.0 (الإنتاج المشترك: Flutter & Next.js)  
**التاريخ:** أكتوبر 2026  
**المعايير المعتمدة:** المعايير المحاسبية للمشاريع العقارية، التوافق مع Firestore، الحساب العشري الآمن (BigInt Cents).

---

## 1. الأهداف الهندسية والمعمارية (Architecture Goals)

1. **مصدر وحيد للحقيقة المالية (Single Source of Financial Truth):**
   تشارك تطبيق الهواتف الذكية (Flutter) وموقع الويب (Next.js) نفس القواعد المالية الدقيقة ونفس هيكل البيانات في Firestore (`aqarr-cfd58`).
2. **الحساب العشري الدقيق (Decimal-Safe Precision):**
   القضاء التام على مشاكل الدقة العائمة في لغة جافاسكريبت ودارت (`IEEE 754 Floating-Point Drift`) عبر تمثيل القيم المالية بوحدة السنتات/القروش الصحيحة (`BigInt Cents`).
3. **أمن وحماية الوصول المالي (Zero-Trust Financial RBAC):**
   منع الوصول غير المصرح به للبيانات المالية وتطبيق التحقق الصارم من الصلاحيات على جهة الخادم (`Server-Side Route Middleware & API Handlers`).
4. **تتبع تاريخ الأسعار والتدقيق (Immutable Audit Trail):**
   تسجيل أي تعديل في أسعار الطرح أو المعاملات المالية بهوية القائم بالتعديل والوقت والتاريخ دون احتساب أسعار العرض كإيراد فعلي محقق.

---

## 2. مصفوفة الصلاحيات والحماية (RBAC & Authentication)

### 2.1. مسارات الدخول وحفظ الجلسات
- مدخل الدخول المالي المخصص: `/accounting/login`
- كوكيز آمنة (`aqar_accounting_session`) مع الخصائص:
  - `HttpOnly: true` (تمنع سرقة الرمز عبر هجمات XSS في المتصفح).
  - `SameSite: 'lax'` (حماية ضد CSRF).
  - `Secure: true` في بيئة الإنتاج HTTPS.
- التوقيع الرقمي للرموز: `HMAC-SHA256` عبر Web Crypto API، مع التحقق من انتهاء الصلاحية ورفض التلاعب (`Tamper-Proof Payload`).

### 2.2. جدول الصلاحيات حسب الدور
```mermaid
graph TD
    User([المستخدم]) --> Authenticate{التحقق من الهوية}
    Authenticate -->|فشل| Redirect[/accounting/login]
    Authenticate -->|نجاح| RoleCheck{فحص الدور}
    RoleCheck -->|admin| FullAccess[صلاحيات كاملة واعتماد التسويات]
    RoleCheck -->|accountant| AccountingOps[إدارة المصروفات والأقساط وفواتير الموردين]
    RoleCheck -->|partner| PartnerIsolated[استعراض كشف الحساب الشخصي فقط ومراقبة الأسعار]
    RoleCheck -->|viewer| ReadOnly[قراءة مؤشرات السوق ومراقبة الأسعار]
```

| الدور الوظيفي | عرض لوحة القيادة | إضافة/تعديل المصروفات | تحصيل الأقساط | كشف حساب الشركاء | كشف الحساب الشخصي | تعديل أسعار الطرح | إدارة المستخدمين والتسويات |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **مدير المنظومة (`admin`)** | نعم | نعم | نعم | نعم (الجميع) | نعم | نعم | نعم |
| **رئيس الحسابات (`accountant`)** | نعم | نعم | نعم | نعم (الجميع) | نعم | نعم | لا |
| **شريك المشروع (`partner`)** | لا | لا | لا | لا (محظور) | نعم (بياناته فقط) | قراءة فقط | لا |
| **مراقب الحسابات (`viewer`)** | لا | لا | لا | لا (محظور) | لا | قراءة فقط | لا |

---

## 3. محرك الحسابات المالية (Accounting Calculation Rules)

### 3.1. حساب التعرض المالي وحصص الشركاء (Partner Ledger Formula)
يتطابق المحرك `AccountingEngine.calculatePartnerLedgers` حرفياً مع كود Flutter في `partner_ledger_calculator.dart`:

1. **إجمالي التعرض المالي للمشروع (Total Project Expense Exposure):**
   $$\text{TotalExposure} = \sum \text{GeneralExpenses} + \sum \text{MaterialInvoices.totalPrice}$$
2. **الحصة المتوقعة لكل شريك (Expected Contribution):**
   $$\text{ExpectedShare} = \text{TotalExposure} \times \text{ShareRatio}$$
3. **إجمالي ما سدده الشريك فعلياً (Total Paid by Partner):**
   $$\text{TotalPaid} = \text{AuthorizedLedgerCredits} + \text{DirectExpensesPaid} + \text{InitialMaterialsPaid} + \text{SupplierPaymentsPaid}$$
4. **فارق الحساب (Balance Delta):**
   $$\Delta = \text{TotalPaid} - \text{ExpectedShare}$$
   - **إذا كان $\Delta > 0$:** الشركة والمشروع مدينان للشريك بالمبلغ (يستحق الشريك استرداد المبلغ أو اعتباره رصيداً دائناً له).
   - **إذا كان $\Delta < 0$:** الشريك مدين للمشروع بمبلغ $|\Delta|$ وعليه سداده لاستكمال حصته من التكاليف.

### 3.2. تسوية حسابات الموردين (Supplier Ledger Formula)
يتطابق المحرك مع `materials_ledger_calculator.dart` في Flutter:
- إجمالي قيمة المشتريات والتوريدات: $\sum \text{MaterialInvoices.totalPrice}$
- إجمالي المدفوع للمورد: $\max(\text{RecordedPaid}, \text{InitialPaid} + \sum \text{SupplierPayments})$
- رصيد المورد المستحق (الديون الواجبة السداد): $\max(0, \text{TotalPurchased} - \text{TotalPaid})$

### 3.3. الإيراد والأرباح والتدفق النقدي (Company Reconciliation)
- **إجمالي قيمة المبيعات التعاقدية:** مجموع أسعار بيع الوحدات المتعاقد عليها والمحجوزة.
- **إجمالي المقبوضات النقدية المحققة:**
  $$\text{TotalCollected} = \max(\text{TotalDownPayments} + \text{PaidInstallments}, \text{DirectReceipts})$$
- **المستحقات المعلقة لدى العملاء (Outstanding Receivables):**
  $$\text{Receivables} = \max(0, \text{TotalSalesValue} - \text{TotalCollected})$$
- **صافي ربح المشروع المحقق (Net Project Profit):**
  $$\text{NetProfit} = \text{TotalSalesValue} - \text{TotalExpenseExposure}$$
- **صافي التدفق النقدي الفعلي (Net Cash Flow):**
  $$\text{CashFlow} = \text{TotalCollected} - (\text{GeneralExpensesPaid} + \text{SupplierPaymentsPaid})$$

---

## 4. نظام مراقبة وتحديث أسعار العقارات (Price Monitoring Engine)

### 4.1. القواعد والضوابط
1. **فصل سعر الطرح (Asking Price) عن سعر البيع (Contract Price):**
   - تعديل سعر الطرح للوحدات المتاحة يمثل تقييماً سوقياً وليس ربحاً محاسبياً محققاً.
   - لا يجوز قيد أي زيادة في سعر الطرح كإيراد أو تدفق نقدي إلا عند إتمام التعاقد وسداد الدفعة المقدمة.
2. **سجل التغييرات غير القابل للحذف (`PriceHistoryRecord`):**
   - يسجل السعر السابق، السعر الجديد، الفارق المطلق، النسبة المئوية للتغيير، معرف المستخدم واسمه، والوقت الدقيق بالثواني.
3. **حساب سعر المتر المربع:**
   $$\text{PricePerSqm} = \frac{\text{AskingPrice}}{\text{AreaInSquareMeters}}$$
4. **محددات التنبيه (Alert Threshold):**
   - يتم رفع علامة تحذيرية في الواجهة إذا تجاوزت نسبة تعديل السعر 20% للتأكد من عدم وجود أخطاء في الإدخال.

---

## 5. هيكل البيانات في Firestore وتكامل Next.js

```text
Firestore Collections Schema:
├── properties/                    # المشروعات العقارية
│   ├── [id] { name, location, totalExpenses, expectedProfit, ... }
├── units/                         # الوحدات السكنية والتجارية
│   ├── [id] { unitNumber, propertyId, salePrice, areaSqm, status, ... }
├── expenses/                      # المصروفات العمومية والإنشائية
│   ├── [id] { amount, category, propertyId, paidByPartnerId, ... }
├── material_expenses/             # فواتير توريد مواد البناء
│   ├── [id] { supplierName, totalPrice, amountPaid, initialPaidByPartnerId, ... }
├── supplier_payments/             # إيصالات سداد مستحقات الموردين
│   ├── [id] { supplierName, amount, paidByPartnerId, paymentDate, ... }
├── partners/                      # الشركاء والمساهمين
│   ├── [id] { name, shareRatio, initialCapital, status, ... }
├── partner_ledger_entries/        # قيود دفتر أستاذ الشركاء
│   ├── [id] { partnerId, entryType, amount, notes, ... }
├── installments/                  # أقساط ومستحقات الوحدات
│   ├── [id] { unitId, amount, paidAmount, dueDate, status, ... }
├── price_history/                 # سجل تدقيق تغيرات الأسعار
│   ├── [id] { unitId, previousPrice, newPrice, absoluteChange, changedBy, ... }
└── activity_logs/                 # سجل العمليات المالي والأمني
    ├── [id] { actorId, action, entityType, entityId, createdAt, ... }
```
