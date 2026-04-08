# Firebase Data Model

الملف ده هو المرجع السريع للـ collections الفعلية المستخدمة في التطبيق بعد إزالة أي mock data من الكود.

## Collections

### `users/{uid}`

- الغرض: ملف المستخدم المرتبط مباشرة بـ Firebase Auth UID
- الحقول الأساسية:
  - `uid`: string
  - `phone`: string
  - `fullName`: string
  - `name`: string
  - `email`: string
  - `role`: string = `partner`
  - `trustedDeviceEnabled`: bool
  - `biometricEnabled`: bool
  - `appLockEnabled`: bool
  - `inactivityTimeoutSeconds`: int
  - `deviceInfo`: map
  - `isActive`: bool
  - `securitySetupCompletedAt`: timestamp?
  - `createdAt`: timestamp
  - `updatedAt`: timestamp
  - `lastLoginAt`: timestamp?

### `partners/{partnerId}`

- الغرض: تعريف الشركاء التجاريين داخل النظام
- الحقول:
  - `userId`: string
  - `linkedEmail`: string
  - `name`: string
  - `shareRatio`: number
  - `contributionTotal`: number
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

### `properties/{propertyId}`

- الغرض: المشروع أو العقار
- الحقول:
  - `name`: string
  - `location`: string
  - `description`: string
  - `status`: `planning | active | delivered | archived`
  - `totalBudget`: number
  - `totalSalesTarget`: number
  - `createdBy`: string
  - `updatedBy`: string
  - `archived`: bool
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

### `units/{unitId}`

- الغرض: الوحدات التابعة لكل مشروع
- الحقول:
  - `propertyId`: string
  - `unitNumber`: string
  - `floor`: int
  - `unitType`: `apartment | penthouse | office | retail | floor | villa`
  - `area`: number
  - `customerName`: string
  - `customerPhone`: string
  - `saleAmount`: number
  - `totalPrice`: number
  - `contractAmount`: number
  - `downPayment`: number
  - `remainingAmount`: number
  - `installmentScheduleCount`: int
  - `paymentPlanType`: `cash | installment | custom`
  - `status`: `available | reserved | sold | cancelled`
  - `notes`: string
  - `projectedCompletionDate`: timestamp?
  - `createdBy`: string
  - `updatedBy`: string
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

### `expenses/{expenseId}`

- الغرض: المصروفات العامة للمشروع
- الحقول:
  - `propertyId`: string
  - `amount`: number
  - `category`: `construction | legal | permits | utilities | marketing | brokerage | maintenance | materials | partnerSettlement | other`
  - `description`: string
  - `paidByPartnerId`: string
  - `paymentMethod`: `cash | bankTransfer | cheque | wallet | other`
  - `date`: timestamp
  - `attachmentUrl`: string?
  - `notes`: string
  - `createdBy`: string
  - `updatedBy`: string
  - `createdAt`: timestamp
  - `updatedAt`: timestamp
  - `archived`: bool

### `material_expenses/{entryId}`

- الغرض: فواتير ومشتريات مواد البناء
- الحقول:
  - `propertyId`: string
  - `date`: timestamp
  - `materialCategory`: `cement | brick | steel | sand | gravel | finishing | electrical | plumbing | paint | other`
  - `itemName`: string
  - `quantity`: number
  - `unitPrice`: number
  - `totalPrice`: number
  - `supplierName`: string
  - `amountPaid`: number
  - `amountRemaining`: number
  - `dueDate`: timestamp?
  - `notes`: string
  - `createdBy`: string
  - `updatedBy`: string
  - `createdAt`: timestamp
  - `updatedAt`: timestamp
  - `archived`: bool

### `installment_plans/{planId}`

- الغرض: خطة تقسيط مرتبطة بوحدة
- الحقول:
  - `propertyId`: string
  - `unitId`: string
  - `installmentCount`: int
  - `startDate`: timestamp
  - `intervalDays`: int
  - `installmentAmount`: number
  - `createdBy`: string
  - `updatedBy`: string
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

### `installments/{installmentId}`

- الغرض: الأقساط الناتجة من خطة تقسيط
- الحقول:
  - `planId`: string
  - `propertyId`: string
  - `unitId`: string
  - `sequence`: int
  - `amount`: number
  - `paidAmount`: number
  - `dueDate`: timestamp
  - `status`: `pending | partiallyPaid | paid | overdue`
  - `notes`: string
  - `createdBy`: string
  - `updatedBy`: string
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

### `payments/{paymentId}`

- الغرض: التحصيلات والمدفوعات المستلمة من العميل
- الحقول:
  - `propertyId`: string
  - `unitId`: string
  - `payerName`: string
  - `customerName`: string
  - `installmentId`: string?
  - `amount`: number
  - `receivedAt`: timestamp
  - `paymentMethod`: `cash | bankTransfer | cheque | wallet | other`
  - `paymentSource`: string
  - `notes`: string
  - `createdBy`: string
  - `updatedBy`: string
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

### `partner_ledgers/{entryId}`

- الغرض: قيود الشركاء المالية
- الحقول:
  - `partnerId`: string
  - `propertyId`: string
  - `entryType`: `contribution | settlement | obligation | adjustment`
  - `amount`: number
  - `notes`: string
  - `authorizedBy`: string
  - `createdBy`: string
  - `updatedBy`: string
  - `createdAt`: timestamp
  - `updatedAt`: timestamp
  - `archived`: bool

### `notifications/{notificationId}`

- الغرض: إشعارات داخل التطبيق
- الحقول:
  - `userId`: string
  - `title`: string
  - `body`: string
  - `type`: `installmentDue | overdueInstallment | installmentCompleted | expenseAdded | paymentReceived | supplierPaymentDue | largeExpenseRecorded | ledgerUpdated | partnerLinkRequest | partnerLinkAccepted | newDeviceLogin | systemAlert`
  - `route`: string
  - `isRead`: bool
  - `referenceKey`: string
  - `metadata`: map
  - `createdAt`: timestamp

### `activity_logs/{logId}`

- الغرض: تتبع الأنشطة داخل النظام
- الحقول:
  - `actorId`: string
  - `actorName`: string
  - `action`: string
  - `entityType`: string
  - `entityId`: string
  - `metadata`: map
  - `createdAt`: timestamp

### `settings/{settingId}`

- الغرض: إعدادات عامة مستقبلية
- ملاحظة: المسار معرف في الكود، لكن لا يوجد schema ثابت مستخدم حاليًا.

## Storage

الملفات الخاصة بالمشروعات تحفظ تحت:

```text
properties/{propertyId}/files/{fileName}
```

## Relationships

- `users/{uid}` مرتبط مباشرة بـ Firebase Auth.
- `partners.userId` يشير إلى `users/{uid}`.
- `units.propertyId`, `expenses.propertyId`, `material_expenses.propertyId`, `installment_plans.propertyId`, `installments.propertyId`, `payments.propertyId`, `partner_ledgers.propertyId` تشير إلى `properties/{propertyId}`.
- `installment_plans.unitId`, `installments.unitId`, `payments.unitId` تشير إلى `units/{unitId}`.
- `installments.planId` يشير إلى `installment_plans/{planId}`.
- `payments.installmentId` يشير إلى `installments/{installmentId}` عند وجوده.
- `expenses.paidByPartnerId` و `partner_ledgers.partnerId` يشيران إلى `partners/{partnerId}`.
