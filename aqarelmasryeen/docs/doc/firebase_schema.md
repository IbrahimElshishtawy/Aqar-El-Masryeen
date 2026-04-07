# Firebase Schema

## Overview

المشروع يعتمد على:

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging

هيكل البيانات الحالي في Firestore عبارة عن root collections وليس subcollections.

## Main Collections

### `users`

يمثل حساب المستخدم داخل التطبيق، وهو مرتبط مباشرة بـ Firebase Auth UID.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `uid` | `string` | yes | يجب أن يساوي `docId` و `request.auth.uid` |
| `phone` | `string` | yes | رقم الهاتف |
| `fullName` | `string` | yes | الاسم الكامل |
| `name` | `string` | optional | نسخة مساعدة من الاسم |
| `email` | `string` | yes | البريد الإلكتروني |
| `role` | `string` | yes | القيمة الحالية: `partner` |
| `trustedDeviceEnabled` | `bool` | yes | تفعيل الجهاز الموثوق |
| `biometricEnabled` | `bool` | yes | بصمة/Face ID |
| `appLockEnabled` | `bool` | yes | قفل التطبيق |
| `inactivityTimeoutSeconds` | `int` | yes | من 30 إلى 300 |
| `deviceInfo` | `map` | optional | بيانات الجهاز |
| `isActive` | `bool` | yes | حالة الحساب |
| `securitySetupCompletedAt` | `timestamp` | optional | وقت إكمال إعدادات الحماية |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تعديل |
| `lastLoginAt` | `timestamp` | optional | وقت آخر تسجيل دخول |

مثال:

```json
{
  "uid": "auth_uid_here",
  "phone": "+201234567890",
  "fullName": "Ahmed Ali",
  "name": "Ahmed Ali",
  "email": "ahmed@example.com",
  "role": "partner",
  "trustedDeviceEnabled": false,
  "biometricEnabled": true,
  "appLockEnabled": true,
  "inactivityTimeoutSeconds": 90,
  "deviceInfo": {
    "deviceId": "device-1",
    "deviceName": "Pixel 8",
    "platform": "android"
  },
  "isActive": true,
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### `partners`

يمثل الشريك التجاري داخل النظام، وقد يكون مربوطًا بحساب مستخدم.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `userId` | `string` | yes | مرجع إلى `users/{uid}` |
| `linkedEmail` | `string` | yes | البريد المستخدم للربط |
| `name` | `string` | yes | اسم الشريك |
| `shareRatio` | `number` | yes | نسبة المشاركة |
| `contributionTotal` | `number` | yes | إجمالي المساهمة |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تحديث |

### `properties`

يمثل مشروع أو عقار.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | `string` | yes | اسم المشروع |
| `location` | `string` | yes | الموقع |
| `description` | `string` | yes | وصف المشروع |
| `status` | `string` | yes | `planning`, `active`, `delivered`, `archived` |
| `totalBudget` | `number` | yes | الميزانية |
| `totalSalesTarget` | `number` | yes | المستهدف البيعي |
| `createdBy` | `string` | yes | UID المنفذ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `archived` | `bool` | yes | soft delete |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تحديث |

### `units`

الوحدات التابعة لكل مشروع.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | مرجع إلى `properties/{id}` |
| `unitNumber` | `string` | yes | رقم الوحدة |
| `floor` | `int` | yes | الدور |
| `unitType` | `string` | yes | `apartment`, `penthouse`, `office`, `retail`, `floor`, `villa` |
| `area` | `number` | yes | المساحة |
| `customerName` | `string` | yes | اسم العميل |
| `customerPhone` | `string` | yes | هاتف العميل |
| `saleAmount` | `number` | yes | قيمة البيع |
| `totalPrice` | `number` | yes | السعر الكلي |
| `contractAmount` | `number` | yes | قيمة التعاقد |
| `downPayment` | `number` | yes | المقدم |
| `remainingAmount` | `number` | yes | المتبقي |
| `installmentScheduleCount` | `int` | yes | عدد الأقساط |
| `paymentPlanType` | `string` | yes | `cash`, `installment`, `custom` |
| `status` | `string` | yes | `available`, `reserved`, `sold`, `cancelled` |
| `notes` | `string` | optional | ملاحظات |
| `projectedCompletionDate` | `timestamp` | optional | تاريخ متوقع |
| `createdBy` | `string` | yes | UID المنفذ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تحديث |

### `expenses`

المصروفات العامة الخاصة بالمشروع.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | مرجع إلى المشروع |
| `amount` | `number` | yes | المبلغ |
| `category` | `string` | yes | من `ExpenseCategory` |
| `description` | `string` | yes | وصف المصروف |
| `paidByPartnerId` | `string` | yes | مرجع إلى الشريك |
| `paymentMethod` | `string` | yes | `cash`, `bankTransfer`, `cheque`, `wallet`, `other` |
| `date` | `timestamp` | yes | تاريخ العملية |
| `attachmentUrl` | `string` | optional | رابط مرفق |
| `notes` | `string` | optional | ملاحظات |
| `createdBy` | `string` | yes | UID المنفذ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تحديث |
| `archived` | `bool` | yes | soft delete |

القيم المستخدمة في `category`:

- `construction`
- `legal`
- `permits`
- `utilities`
- `marketing`
- `brokerage`
- `maintenance`
- `materials`
- `partnerSettlement`
- `other`

### `material_expenses`

فواتير ومشتريات المواد الخام.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | مرجع إلى المشروع |
| `date` | `timestamp` | yes | تاريخ الفاتورة |
| `materialCategory` | `string` | yes | من `MaterialCategory` |
| `itemName` | `string` | yes | اسم الصنف |
| `quantity` | `number` | yes | الكمية |
| `unitPrice` | `number` | yes | سعر الوحدة |
| `totalPrice` | `number` | yes | الإجمالي |
| `supplierName` | `string` | yes | اسم المورد |
| `amountPaid` | `number` | yes | المدفوع |
| `amountRemaining` | `number` | yes | المتبقي |
| `dueDate` | `timestamp` | optional | تاريخ الاستحقاق |
| `notes` | `string` | optional | ملاحظات |
| `createdBy` | `string` | yes | UID المنفذ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تحديث |
| `archived` | `bool` | yes | soft delete |

### `installment_plans`

خطة التقسيط المرتبطة بوحدة.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | مرجع إلى المشروع |
| `unitId` | `string` | yes | مرجع إلى الوحدة |
| `installmentCount` | `int` | yes | عدد الأقساط |
| `startDate` | `timestamp` | yes | بداية الخطة |
| `intervalDays` | `int` | yes | عدد الأيام بين الأقساط |
| `installmentAmount` | `number` | yes | قيمة القسط |
| `createdBy` | `string` | yes | UID المنفذ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تحديث |

### `installments`

الأقساط الناتجة من خطة التقسيط.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `planId` | `string` | yes | مرجع إلى `installment_plans/{id}` |
| `propertyId` | `string` | yes | مرجع إلى المشروع |
| `unitId` | `string` | yes | مرجع إلى الوحدة |
| `sequence` | `int` | yes | ترتيب القسط |
| `amount` | `number` | yes | قيمة القسط |
| `paidAmount` | `number` | yes | المدفوع من القسط |
| `dueDate` | `timestamp` | yes | تاريخ الاستحقاق |
| `status` | `string` | yes | `pending`, `partiallyPaid`, `paid`, `overdue` |
| `notes` | `string` | optional | ملاحظات |
| `createdBy` | `string` | yes | UID المنفذ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تحديث |

### `payments`

الدفعات المحصلة من العميل.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | مرجع إلى المشروع |
| `unitId` | `string` | yes | مرجع إلى الوحدة |
| `payerName` | `string` | optional | اسم الدافع |
| `customerName` | `string` | yes | اسم العميل |
| `installmentId` | `string` | optional | لو الدفعة مرتبطة بقسط |
| `amount` | `number` | yes | المبلغ |
| `receivedAt` | `timestamp` | yes | تاريخ الاستلام |
| `paymentMethod` | `string` | yes | طريقة الدفع |
| `paymentSource` | `string` | yes | مصدر الدفعة |
| `notes` | `string` | optional | ملاحظات |
| `createdBy` | `string` | yes | UID المنفذ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تحديث |

### `partner_ledgers`

قيود الشركاء المالية.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `partnerId` | `string` | yes | مرجع إلى الشريك |
| `propertyId` | `string` | yes | مرجع إلى المشروع |
| `entryType` | `string` | yes | `contribution`, `settlement`, `obligation`, `adjustment` |
| `amount` | `number` | yes | قيمة القيد |
| `notes` | `string` | optional | ملاحظات |
| `authorizedBy` | `string` | yes | UID المعتمد |
| `createdBy` | `string` | yes | UID المنفذ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تحديث |
| `archived` | `bool` | yes | soft delete |

### `notifications`

تنبيهات داخل التطبيق.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `userId` | `string` | yes | صاحب الإشعار |
| `title` | `string` | yes | عنوان |
| `body` | `string` | yes | محتوى |
| `type` | `string` | yes | من `NotificationType` |
| `route` | `string` | yes | المسار داخل التطبيق |
| `isRead` | `bool` | yes | مقروء أم لا |
| `referenceKey` | `string` | optional | مفتاح مرجعي |
| `metadata` | `map` | optional | بيانات إضافية |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |

### `activity_logs`

سجل الأحداث داخل النظام.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `actorId` | `string` | yes | UID صاحب الإجراء |
| `actorName` | `string` | yes | اسم صاحب الإجراء |
| `action` | `string` | yes | نوع العملية |
| `entityType` | `string` | yes | نوع العنصر |
| `entityId` | `string` | yes | المعرف المرتبط |
| `createdAt` | `timestamp` | yes | وقت التنفيذ |
| `metadata` | `map` | optional | بيانات إضافية |

### `settings`

Collection محجوزة للإعدادات العامة. الكود الحالي يعرف المسار فقط ولا يستخدم structure ثابت حتى الآن.

## Relations

العلاقات الأساسية في قاعدة البيانات:

- `users.uid` <- مرتبط بـ Firebase Auth UID
- `partners.userId` -> `users/{uid}`
- `units.propertyId` -> `properties/{propertyId}`
- `expenses.propertyId` -> `properties/{propertyId}`
- `expenses.paidByPartnerId` -> `partners/{partnerId}`
- `material_expenses.propertyId` -> `properties/{propertyId}`
- `installment_plans.propertyId` -> `properties/{propertyId}`
- `installment_plans.unitId` -> `units/{unitId}`
- `installments.planId` -> `installment_plans/{planId}`
- `installments.propertyId` -> `properties/{propertyId}`
- `installments.unitId` -> `units/{unitId}`
- `payments.propertyId` -> `properties/{propertyId}`
- `payments.unitId` -> `units/{unitId}`
- `payments.installmentId` -> `installments/{installmentId}`
- `partner_ledgers.partnerId` -> `partners/{partnerId}`
- `partner_ledgers.propertyId` -> `properties/{propertyId}`
- `notifications.userId` -> `users/{uid}`

## Storage Structure

الملفات الحالية في Firebase Storage محفوظة تحت:

```text
properties/{propertyId}/files/{fileName}
```

ويُفضَّل عند الرفع حفظ metadata مثل:

- `uploadedBy`
- `propertyId`
- `contentType`
- `uploadedAt`

## Required Composite Indexes

طبقًا للـ repositories الحالية، هذه أهم الـ indexes المطلوبة:

| Collection | Fields |
| --- | --- |
| `properties` | `archived ASC`, `updatedAt DESC` |
| `expenses` | `archived ASC`, `date DESC` |
| `expenses` | `propertyId ASC`, `archived ASC`, `date DESC` |
| `material_expenses` | `archived ASC`, `date DESC` |
| `material_expenses` | `propertyId ASC`, `archived ASC`, `date DESC` |
| `units` | `propertyId ASC`, `updatedAt DESC` |
| `installment_plans` | `propertyId ASC`, `updatedAt DESC` |
| `installments` | `propertyId ASC`, `dueDate ASC` |
| `installments` | `unitId ASC`, `dueDate ASC` |
| `payments` | `propertyId ASC`, `receivedAt DESC` |
| `payments` | `unitId ASC`, `receivedAt DESC` |
| `notifications` | `userId ASC`, `createdAt DESC` |
| `partner_ledgers` | `archived ASC`, `updatedAt DESC` |

## Notes Before Production

- بعض الـ indexes السابقة موجودة بالفعل في `firestore.indexes.json` وبعضها ما زال ناقصًا.
- `firestore.rules` الحالية لا تغطي كل الكولكشنز المستخدمة في الكود.
- الأفضل الالتزام دائمًا بكتابة `createdAt`, `updatedAt`, `createdBy`, `updatedBy` في كل عملية حفظ.
