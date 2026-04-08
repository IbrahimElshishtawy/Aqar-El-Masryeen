# Firebase Schema

هذا الملف هو النسخة التفصيلية للـ schema المطلوب في Firebase بناءً على الـ models والـ repositories الحالية في المشروع.

## Main collections

### `users`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `uid` | `string` | yes | يساوي `docId` و Firebase Auth UID |
| `phone` | `string` | yes | رقم الهاتف |
| `fullName` | `string` | yes | الاسم الكامل |
| `name` | `string` | yes | نسخة مساعدة من الاسم |
| `email` | `string` | yes | البريد الإلكتروني |
| `role` | `string` | yes | حاليًا `partner` |
| `trustedDeviceEnabled` | `bool` | yes | تفعيل الجهاز الموثوق |
| `biometricEnabled` | `bool` | yes | تفعيل البصمة |
| `appLockEnabled` | `bool` | yes | قفل التطبيق |
| `inactivityTimeoutSeconds` | `int` | yes | مهلة عدم النشاط |
| `deviceInfo` | `map` | optional | بيانات الجهاز |
| `isActive` | `bool` | yes | حالة الحساب |
| `securitySetupCompletedAt` | `timestamp` | optional | وقت إكمال إعدادات الحماية |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تعديل |
| `lastLoginAt` | `timestamp` | optional | وقت آخر تسجيل دخول |

`deviceInfo` يحتوي عادة على:

- `deviceId`
- `deviceName`
- `platform`
- `osVersion`
- `appVersion`
- `buildNumber`
- `model`
- `manufacturer`
- `isPhysicalDevice`
- `lastSeenAt`

### `partners`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `userId` | `string` | yes | مرجع إلى `users/{uid}` |
| `linkedEmail` | `string` | yes | البريد المرتبط بالشريك |
| `name` | `string` | yes | اسم الشريك |
| `shareRatio` | `number` | yes | نسبة الشراكة |
| `contributionTotal` | `number` | yes | إجمالي المساهمة |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تعديل |

### `properties`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | `string` | yes | اسم المشروع |
| `location` | `string` | yes | موقع المشروع |
| `description` | `string` | yes | وصف المشروع |
| `status` | `string` | yes | `planning`, `active`, `delivered`, `archived` |
| `totalBudget` | `number` | yes | الميزانية |
| `totalSalesTarget` | `number` | yes | المستهدف البيعي |
| `createdBy` | `string` | yes | UID المنشئ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `archived` | `bool` | yes | soft delete |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تعديل |

### `units`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | مرجع إلى `properties/{propertyId}` |
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
| `createdBy` | `string` | yes | UID المنشئ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تعديل |

### `expenses`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | مرجع إلى المشروع |
| `amount` | `number` | yes | قيمة المصروف |
| `category` | `string` | yes | `construction`, `legal`, `permits`, `utilities`, `marketing`, `brokerage`, `maintenance`, `materials`, `partnerSettlement`, `other` |
| `description` | `string` | yes | وصف المصروف |
| `paidByPartnerId` | `string` | yes | مرجع إلى الشريك |
| `paymentMethod` | `string` | yes | `cash`, `bankTransfer`, `cheque`, `wallet`, `other` |
| `date` | `timestamp` | yes | تاريخ العملية |
| `attachmentUrl` | `string` | optional | رابط مرفق |
| `notes` | `string` | optional | ملاحظات |
| `createdBy` | `string` | yes | UID المنشئ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تعديل |
| `archived` | `bool` | yes | soft delete |

### `material_expenses`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | مرجع إلى المشروع |
| `date` | `timestamp` | yes | تاريخ الفاتورة |
| `materialCategory` | `string` | yes | `cement`, `brick`, `steel`, `sand`, `gravel`, `finishing`, `electrical`, `plumbing`, `paint`, `other` |
| `itemName` | `string` | yes | اسم الصنف |
| `quantity` | `number` | yes | الكمية |
| `unitPrice` | `number` | yes | سعر الوحدة |
| `totalPrice` | `number` | yes | الإجمالي |
| `supplierName` | `string` | yes | اسم المورد |
| `amountPaid` | `number` | yes | المدفوع |
| `amountRemaining` | `number` | yes | المتبقي |
| `dueDate` | `timestamp` | optional | موعد الاستحقاق |
| `notes` | `string` | optional | ملاحظات |
| `createdBy` | `string` | yes | UID المنشئ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تعديل |
| `archived` | `bool` | yes | soft delete |

### `installment_plans`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | مرجع إلى المشروع |
| `unitId` | `string` | yes | مرجع إلى الوحدة |
| `installmentCount` | `int` | yes | عدد الأقساط |
| `startDate` | `timestamp` | yes | بداية الخطة |
| `intervalDays` | `int` | yes | الفاصل بين الأقساط بالأيام |
| `installmentAmount` | `number` | yes | قيمة القسط |
| `createdBy` | `string` | yes | UID المنشئ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تعديل |

### `installments`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `planId` | `string` | yes | مرجع إلى `installment_plans/{planId}` |
| `propertyId` | `string` | yes | مرجع إلى المشروع |
| `unitId` | `string` | yes | مرجع إلى الوحدة |
| `sequence` | `int` | yes | ترتيب القسط |
| `amount` | `number` | yes | قيمة القسط |
| `paidAmount` | `number` | yes | المبلغ المدفوع منه |
| `dueDate` | `timestamp` | yes | تاريخ الاستحقاق |
| `status` | `string` | yes | `pending`, `partiallyPaid`, `paid`, `overdue` |
| `notes` | `string` | optional | ملاحظات |
| `createdBy` | `string` | yes | UID المنشئ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تعديل |

### `payments`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | مرجع إلى المشروع |
| `unitId` | `string` | yes | مرجع إلى الوحدة |
| `payerName` | `string` | optional | اسم الدافع |
| `customerName` | `string` | yes | اسم العميل |
| `installmentId` | `string` | optional | مرجع إلى القسط إن وجد |
| `amount` | `number` | yes | المبلغ |
| `receivedAt` | `timestamp` | yes | تاريخ التحصيل |
| `paymentMethod` | `string` | yes | `cash`, `bankTransfer`, `cheque`, `wallet`, `other` |
| `paymentSource` | `string` | yes | مصدر الدفعة |
| `notes` | `string` | optional | ملاحظات |
| `createdBy` | `string` | yes | UID المنشئ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تعديل |

### `partner_ledgers`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `partnerId` | `string` | yes | مرجع إلى الشريك |
| `propertyId` | `string` | yes | مرجع إلى المشروع |
| `entryType` | `string` | yes | `contribution`, `settlement`, `obligation`, `adjustment` |
| `amount` | `number` | yes | قيمة القيد |
| `notes` | `string` | optional | ملاحظات |
| `authorizedBy` | `string` | yes | UID المعتمد |
| `createdBy` | `string` | yes | UID المنشئ |
| `updatedBy` | `string` | yes | UID آخر من عدل |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |
| `updatedAt` | `timestamp` | yes | وقت آخر تعديل |
| `archived` | `bool` | yes | soft delete |

### `notifications`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `userId` | `string` | yes | صاحب الإشعار |
| `title` | `string` | yes | عنوان |
| `body` | `string` | yes | المحتوى |
| `type` | `string` | yes | من `NotificationType` |
| `route` | `string` | yes | مسار داخل التطبيق |
| `isRead` | `bool` | yes | مقروء أم لا |
| `referenceKey` | `string` | optional | مفتاح مرجعي لتفادي التكرار |
| `metadata` | `map` | optional | بيانات إضافية |
| `createdAt` | `timestamp` | yes | وقت الإنشاء |

### `activity_logs`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `actorId` | `string` | yes | UID صاحب الإجراء |
| `actorName` | `string` | yes | الاسم |
| `action` | `string` | yes | نوع الحدث |
| `entityType` | `string` | yes | نوع العنصر |
| `entityId` | `string` | yes | معرف العنصر |
| `metadata` | `map` | optional | بيانات إضافية |
| `createdAt` | `timestamp` | yes | وقت التنفيذ |

### `settings`

Collection محجوزة لإعدادات عامة لاحقًا. لا يوجد schema ثابت مستخدم الآن.

## Storage structure

```text
properties/{propertyId}/files/{fileName}
```

## Required composite indexes

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
| `partner_ledgers` | `archived ASC`, `updatedAt DESC` |
| `activity_logs` | `entityId ASC`, `createdAt DESC` |
| `notifications` | `userId ASC`, `createdAt DESC` |
