# Firebase Data Model

This document is a practical Firestore reference based on the models and repositories currently used in the app.

Use it when you want to add seed data manually from Firebase Console without breaking relations between collections.

## Important before adding data

1. Any field marked as `timestamp` must be created as a Firestore `timestamp`, not a string.
2. Enum values must match the code exactly, including lowercase names like `active` and `installment`.
3. Reference fields such as `propertyId`, `unitId`, and `partnerId` must point to real existing documents.
4. `users/{uid}` is special: the document ID must equal the Firebase Auth UID.
5. All other document IDs may be auto-generated or custom, but the same IDs must be reused across related documents.

## Recommended insert order

Create data in this order so references stay valid:

1. `users`
2. `partners`
3. `properties`
4. `units`
5. `installment_plans`
6. `installments`
7. `payments`
8. `expenses`
9. `material_expenses`
10. `partner_ledgers`
11. `notifications`
12. `activity_logs`

## Collections

### `users/{uid}`

Purpose: app user profile linked to Firebase Auth.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `uid` | `string` | yes | must equal `docId` |
| `phone` | `string` | yes | may be empty temporarily |
| `fullName` | `string` | yes | full display name |
| `name` | `string` | yes | helper copy of the full name |
| `email` | `string` | yes | prefer lowercase |
| `role` | `string` | yes | currently `partner` |
| `trustedDeviceEnabled` | `bool` | yes | trusted device flag |
| `biometricEnabled` | `bool` | yes | biometric flag |
| `appLockEnabled` | `bool` | yes | app lock flag |
| `inactivityTimeoutSeconds` | `number` | yes | example: `90` |
| `deviceInfo` | `map` | optional | nested device details |
| `isActive` | `bool` | yes | account status |
| `securitySetupCompletedAt` | `timestamp` | optional | security setup completion time |
| `createdAt` | `timestamp` | yes | created time |
| `updatedAt` | `timestamp` | yes | last update time |
| `lastLoginAt` | `timestamp` | optional | last login time |

Example:

```js
{
  uid: "uid_partner_001",
  phone: "+201001234567",
  fullName: "Ahmed Ali",
  name: "Ahmed Ali",
  email: "ahmed@example.com",
  role: "partner",
  trustedDeviceEnabled: false,
  biometricEnabled: false,
  appLockEnabled: true,
  inactivityTimeoutSeconds: 90,
  isActive: true,
  createdAt: Timestamp(...),
  updatedAt: Timestamp(...),
  lastLoginAt: Timestamp(...),
  securitySetupCompletedAt: null,
  deviceInfo: {
    deviceId: "device_001",
    deviceName: "Ahmed iPhone",
    platform: "ios",
    osVersion: "17.4",
    appVersion: "1.0.0",
    buildNumber: "1",
    model: "iPhone 13",
    manufacturer: "Apple",
    isPhysicalDevice: true,
    lastSeenAt: Timestamp(...)
  }
}
```

### `partners/{partnerId}`

Purpose: business partners in the system.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `userId` | `string` | yes | references `users/{uid}` |
| `linkedEmail` | `string` | yes | ideally matches `users.email` |
| `name` | `string` | yes | partner name |
| `shareRatio` | `number` | yes | keep one consistent format such as `0.5` |
| `contributionTotal` | `number` | yes | total contributed amount |
| `createdAt` | `timestamp` | yes | created time |
| `updatedAt` | `timestamp` | yes | last update time |

Example:

```js
{
  userId: "uid_partner_001",
  linkedEmail: "ahmed@example.com",
  name: "Ahmed Ali",
  shareRatio: 0.5,
  contributionTotal: 250000,
  createdAt: Timestamp(...),
  updatedAt: Timestamp(...)
}
```

### `properties/{propertyId}`

Purpose: project or property record.

Allowed `status` values:

- `planning`
- `active`
- `delivered`
- `archived`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | `string` | yes | project name |
| `location` | `string` | yes | project location |
| `apartmentCount` | `number` | yes | total units/apartments |
| `description` | `string` | yes | project description |
| `status` | `string` | yes | one of the values above |
| `totalBudget` | `number` | yes | planned budget |
| `totalSalesTarget` | `number` | yes | target sales value |
| `createdBy` | `string` | yes | creator UID |
| `updatedBy` | `string` | yes | last editor UID |
| `archived` | `bool` | yes | soft delete flag |
| `createdAt` | `timestamp` | yes | created time |
| `updatedAt` | `timestamp` | yes | last update time |

Example:

```js
{
  name: "Aqar El Masryeen - Nasr City",
  location: "Nasr City, Cairo",
  apartmentCount: 24,
  description: "Residential building with commercial ground floor",
  status: "active",
  totalBudget: 8500000,
  totalSalesTarget: 11200000,
  createdBy: "uid_partner_001",
  updatedBy: "uid_partner_001",
  archived: false,
  createdAt: Timestamp(...),
  updatedAt: Timestamp(...)
}
```

### `units/{unitId}`

Purpose: sale units under a property.

Allowed values:

- `unitType`: `apartment`, `penthouse`, `office`, `retail`, `floor`, `villa`
- `paymentPlanType`: `cash`, `installment`, `custom`
- `status`: `available`, `reserved`, `sold`, `cancelled`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | references `properties/{propertyId}` |
| `unitNumber` | `string` | yes | unit number |
| `floor` | `number` | yes | floor number |
| `unitType` | `string` | yes | unit type |
| `area` | `number` | yes | unit area |
| `customerName` | `string` | yes | may be empty for available units |
| `customerPhone` | `string` | yes | customer phone |
| `saleAmount` | `number` | yes | sale value |
| `totalPrice` | `number` | yes | total price |
| `contractAmount` | `number` | yes | contract amount |
| `downPayment` | `number` | yes | paid upfront |
| `remainingAmount` | `number` | yes | remaining amount |
| `installmentScheduleCount` | `number` | yes | installment count |
| `paymentPlanType` | `string` | yes | payment plan type |
| `status` | `string` | yes | unit status |
| `notes` | `string` | optional | notes |
| `projectedCompletionDate` | `timestamp` | optional | projected completion |
| `createdBy` | `string` | yes | creator UID |
| `updatedBy` | `string` | yes | last editor UID |
| `createdAt` | `timestamp` | yes | created time |
| `updatedAt` | `timestamp` | yes | last update time |

Example:

```js
{
  propertyId: "property_nasr_001",
  unitNumber: "A-12",
  floor: 3,
  unitType: "apartment",
  area: 165,
  customerName: "Mohamed Hassan",
  customerPhone: "+201011112222",
  saleAmount: 1850000,
  totalPrice: 1850000,
  contractAmount: 1850000,
  downPayment: 350000,
  remainingAmount: 1500000,
  installmentScheduleCount: 24,
  paymentPlanType: "installment",
  status: "sold",
  notes: "Sea-facing unit",
  projectedCompletionDate: Timestamp(...),
  createdBy: "uid_partner_001",
  updatedBy: "uid_partner_001",
  createdAt: Timestamp(...),
  updatedAt: Timestamp(...)
}
```

### `installment_plans/{planId}`

Purpose: master installment plan for a unit.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | references property |
| `unitId` | `string` | yes | references unit |
| `installmentCount` | `number` | yes | number of installments |
| `startDate` | `timestamp` | yes | first installment date |
| `intervalDays` | `number` | yes | days between installments |
| `installmentAmount` | `number` | yes | amount per installment |
| `createdBy` | `string` | yes | creator UID |
| `updatedBy` | `string` | yes | last editor UID |
| `createdAt` | `timestamp` | yes | created time |
| `updatedAt` | `timestamp` | yes | last update time |

Example:

```js
{
  propertyId: "property_nasr_001",
  unitId: "unit_a12_001",
  installmentCount: 24,
  startDate: Timestamp(...),
  intervalDays: 30,
  installmentAmount: 62500,
  createdBy: "uid_partner_001",
  updatedBy: "uid_partner_001",
  createdAt: Timestamp(...),
  updatedAt: Timestamp(...)
}
```

### `installments/{installmentId}`

Purpose: generated installments belonging to a plan.

Allowed `status` values:

- `pending`
- `partiallyPaid`
- `paid`
- `overdue`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `planId` | `string` | yes | references `installment_plans/{planId}` |
| `propertyId` | `string` | yes | references property |
| `unitId` | `string` | yes | references unit |
| `sequence` | `number` | yes | installment order |
| `amount` | `number` | yes | installment amount |
| `paidAmount` | `number` | yes | amount already paid |
| `dueDate` | `timestamp` | yes | due date |
| `status` | `string` | yes | one of the values above |
| `notes` | `string` | optional | notes |
| `createdBy` | `string` | yes | creator UID |
| `updatedBy` | `string` | yes | last editor UID |
| `createdAt` | `timestamp` | yes | created time |
| `updatedAt` | `timestamp` | yes | last update time |

Example:

```js
{
  planId: "plan_unit_a12_001",
  propertyId: "property_nasr_001",
  unitId: "unit_a12_001",
  sequence: 1,
  amount: 62500,
  paidAmount: 0,
  dueDate: Timestamp(...),
  status: "pending",
  notes: "",
  createdBy: "uid_partner_001",
  updatedBy: "uid_partner_001",
  createdAt: Timestamp(...),
  updatedAt: Timestamp(...)
}
```

### `payments/{paymentId}`

Purpose: customer payment records.

Allowed `paymentMethod` values:

- `cash`
- `bankTransfer`
- `cheque`
- `wallet`
- `other`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | references property |
| `unitId` | `string` | yes | references unit |
| `payerName` | `string` | optional | app falls back to `customerName` when empty |
| `customerName` | `string` | yes | customer name |
| `installmentId` | `string` | optional | references installment when linked |
| `amount` | `number` | yes | payment amount |
| `receivedAt` | `timestamp` | yes | received date |
| `paymentMethod` | `string` | yes | payment method |
| `paymentSource` | `string` | yes | examples: `downPayment`, `installment`, `cashCollection` |
| `notes` | `string` | optional | notes |
| `createdBy` | `string` | yes | creator UID |
| `updatedBy` | `string` | yes | last editor UID |
| `createdAt` | `timestamp` | yes | created time |
| `updatedAt` | `timestamp` | yes | last update time |

Example:

```js
{
  propertyId: "property_nasr_001",
  unitId: "unit_a12_001",
  payerName: "Mohamed Hassan",
  customerName: "Mohamed Hassan",
  installmentId: "installment_a12_001",
  amount: 62500,
  receivedAt: Timestamp(...),
  paymentMethod: "bankTransfer",
  paymentSource: "installment",
  notes: "April installment",
  createdBy: "uid_partner_001",
  updatedBy: "uid_partner_001",
  createdAt: Timestamp(...),
  updatedAt: Timestamp(...)
}
```

### `expenses/{expenseId}`

Purpose: general project expenses.

Allowed values:

- `category`: `construction`, `legal`, `permits`, `utilities`, `marketing`, `brokerage`, `maintenance`, `materials`, `partnerSettlement`, `other`
- `paymentMethod`: `cash`, `bankTransfer`, `cheque`, `wallet`, `other`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | references property |
| `amount` | `number` | yes | expense amount |
| `category` | `string` | yes | expense category |
| `description` | `string` | yes | clear description |
| `paidByPartnerId` | `string` | yes | references partner |
| `paymentMethod` | `string` | yes | payment method |
| `date` | `timestamp` | yes | expense date |
| `attachmentUrl` | `string` | optional | uploaded attachment URL |
| `notes` | `string` | optional | notes |
| `createdBy` | `string` | yes | creator UID |
| `updatedBy` | `string` | yes | last editor UID |
| `createdAt` | `timestamp` | yes | created time |
| `updatedAt` | `timestamp` | yes | last update time |
| `archived` | `bool` | yes | usually `false` unless soft deleted |

Example:

```js
{
  propertyId: "property_nasr_001",
  amount: 120000,
  category: "construction",
  description: "Concrete casting for roof",
  paidByPartnerId: "partner_001",
  paymentMethod: "bankTransfer",
  date: Timestamp(...),
  attachmentUrl: "",
  notes: "Paid to contractor",
  createdBy: "uid_partner_001",
  updatedBy: "uid_partner_001",
  createdAt: Timestamp(...),
  updatedAt: Timestamp(...),
  archived: false
}
```

### `material_expenses/{entryId}`

Purpose: material purchases and supplier invoice records.

Allowed `materialCategory` values:

- `cement`
- `brick`
- `steel`
- `sand`
- `gravel`
- `finishing`
- `electrical`
- `plumbing`
- `paint`
- `other`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `propertyId` | `string` | yes | references property |
| `date` | `timestamp` | yes | invoice date |
| `materialCategory` | `string` | yes | material category |
| `itemName` | `string` | yes | item name |
| `quantity` | `number` | yes | quantity |
| `unitPrice` | `number` | yes | unit price |
| `totalPrice` | `number` | yes | total price |
| `supplierName` | `string` | yes | supplier name |
| `amountPaid` | `number` | yes | paid amount |
| `amountRemaining` | `number` | yes | remaining amount |
| `dueDate` | `timestamp` | optional | due date |
| `notes` | `string` | optional | notes |
| `createdBy` | `string` | yes | creator UID |
| `updatedBy` | `string` | yes | last editor UID |
| `createdAt` | `timestamp` | yes | created time |
| `updatedAt` | `timestamp` | yes | last update time |
| `archived` | `bool` | yes | usually `false` unless soft deleted |

Example:

```js
{
  propertyId: "property_nasr_001",
  date: Timestamp(...),
  materialCategory: "steel",
  itemName: "Steel rebar 16mm",
  quantity: 12,
  unitPrice: 42000,
  totalPrice: 504000,
  supplierName: "El Salam Steel",
  amountPaid: 300000,
  amountRemaining: 204000,
  dueDate: Timestamp(...),
  notes: "First supply batch",
  createdBy: "uid_partner_001",
  updatedBy: "uid_partner_001",
  createdAt: Timestamp(...),
  updatedAt: Timestamp(...),
  archived: false
}
```

### `partner_ledgers/{entryId}`

Purpose: partner financial ledger entries.

Allowed `entryType` values:

- `contribution`
- `settlement`
- `obligation`
- `adjustment`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `partnerId` | `string` | yes | references `partners/{partnerId}` |
| `propertyId` | `string` | yes | references property |
| `entryType` | `string` | yes | ledger entry type |
| `amount` | `number` | yes | entry amount |
| `notes` | `string` | optional | notes |
| `authorizedBy` | `string` | yes | approver UID |
| `createdBy` | `string` | yes | creator UID |
| `updatedBy` | `string` | yes | last editor UID |
| `createdAt` | `timestamp` | yes | created time |
| `updatedAt` | `timestamp` | yes | last update time |
| `archived` | `bool` | yes | usually `false` unless soft deleted |

Example:

```js
{
  partnerId: "partner_001",
  propertyId: "property_nasr_001",
  entryType: "contribution",
  amount: 250000,
  notes: "Initial capital injection",
  authorizedBy: "uid_partner_001",
  createdBy: "uid_partner_001",
  updatedBy: "uid_partner_001",
  createdAt: Timestamp(...),
  updatedAt: Timestamp(...),
  archived: false
}
```

### `notifications/{notificationId}`

Purpose: in-app notifications. Usually created by the app, but can be added manually for testing.

Allowed `type` values:

- `installmentDue`
- `overdueInstallment`
- `installmentCompleted`
- `expenseAdded`
- `paymentReceived`
- `supplierPaymentDue`
- `largeExpenseRecorded`
- `ledgerUpdated`
- `partnerLinkRequest`
- `partnerLinkAccepted`
- `newDeviceLogin`
- `systemAlert`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `userId` | `string` | yes | notification owner |
| `title` | `string` | yes | title |
| `body` | `string` | yes | message body |
| `type` | `string` | yes | one of the values above |
| `route` | `string` | yes | app route |
| `isRead` | `bool` | yes | read flag |
| `createdAt` | `timestamp` | yes | created time |
| `referenceKey` | `string` | optional | may also be used as `docId` to avoid duplicates |
| `metadata` | `map` | optional | extra details |

Example:

```js
{
  userId: "uid_partner_001",
  title: "Installment due",
  body: "Unit A-12 has an installment due this week",
  type: "installmentDue",
  route: "/notifications",
  isRead: false,
  createdAt: Timestamp(...),
  referenceKey: "installment_due_unit_a12_2026_04",
  metadata: {
    propertyId: "property_nasr_001",
    unitId: "unit_a12_001",
    installmentId: "installment_a12_001"
  }
}
```

### `activity_logs/{logId}`

Purpose: activity history log. Usually created by the app automatically.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `actorId` | `string` | yes | actor UID |
| `actorName` | `string` | yes | visible actor name |
| `action` | `string` | yes | action type |
| `entityType` | `string` | yes | for example `property` or `unit` |
| `entityId` | `string` | yes | entity identifier |
| `createdAt` | `timestamp` | yes | event time |
| `metadata` | `map` | optional | extra data |

Example:

```js
{
  actorId: "uid_partner_001",
  actorName: "Ahmed Ali",
  action: "created_property",
  entityType: "property",
  entityId: "property_nasr_001",
  createdAt: Timestamp(...),
  metadata: {
    propertyName: "Aqar El Masryeen - Nasr City"
  }
}
```

### `settings/{settingId}`

This path exists in the code, but there is no active fixed schema for it right now, so you do not need to seed it.

## Relationships

- `users/{uid}` is directly linked to Firebase Auth.
- `partners.userId` points to `users/{uid}`.
- `units.propertyId` points to `properties/{propertyId}`.
- `installment_plans.propertyId`, `installments.propertyId`, `payments.propertyId`, `expenses.propertyId`, `material_expenses.propertyId`, and `partner_ledgers.propertyId` point to `properties/{propertyId}`.
- `installment_plans.unitId`, `installments.unitId`, and `payments.unitId` point to `units/{unitId}`.
- `installments.planId` points to `installment_plans/{planId}`.
- `payments.installmentId` points to `installments/{installmentId}` when present.
- `expenses.paidByPartnerId` and `partner_ledgers.partnerId` point to `partners/{partnerId}`.
- `notifications.userId` points to `users/{uid}`.

## Firebase Storage

Project files are not stored as a Firestore collection. They are uploaded to Firebase Storage under:

```text
properties/{propertyId}/files/{fileName}
```

## Notes

- The current parser expects real Firestore timestamps and does not parse date strings.
- Collections like `notifications` and `activity_logs` are usually created by the app, so they are optional for first-time seeding.
- If Firestore asks you to create an index, check `docs/doc/firebase_schema.md` for the more detailed schema and index reference.
