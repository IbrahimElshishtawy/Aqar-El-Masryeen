# Firebase Data Model

## Collections

`users`
- `phone`, `name`, `email`, `role`
- `biometricEnabled`, `trustedDevices`
- `createdAt`, `updatedAt`, `lastLoginAt`

`partners`
- `userId`, `name`
- `shareRatio`, `contributionTotal`
- `createdAt`, `updatedAt`

`properties`
- `name`, `location`, `description`, `status`
- `totalBudget`, `totalSalesTarget`
- `archived`
- `createdBy`, `updatedBy`, `createdAt`, `updatedAt`

`units`
- `propertyId`, `unitNumber`, `floor`, `unitType`, `area`
- `customerName`, `customerPhone`
- `totalPrice`, `downPayment`, `remainingAmount`
- `paymentPlanType`, `status`
- `createdBy`, `updatedBy`, `createdAt`, `updatedAt`

`expenses`
- `propertyId`, `amount`, `category`, `description`
- `paidByPartnerId`, `paymentMethod`, `date`
- `attachmentUrl`, `notes`, `archived`
- `createdBy`, `updatedBy`, `createdAt`, `updatedAt`

`installment_plans`
- `propertyId`, `unitId`
- `installmentCount`, `startDate`, `intervalDays`, `installmentAmount`
- `createdBy`, `updatedBy`, `createdAt`, `updatedAt`

`installments`
- `planId`, `propertyId`, `unitId`, `sequence`
- `amount`, `paidAmount`, `dueDate`, `status`
- `createdBy`, `updatedBy`, `createdAt`, `updatedAt`

`payments`
- `propertyId`, `unitId`, `installmentId`
- `amount`, `receivedAt`, `paymentMethod`, `notes`
- `createdBy`, `updatedBy`, `createdAt`, `updatedAt`

`notifications`
- `userId`, `title`, `body`, `type`, `route`
- `isRead`, `createdAt`

`activity_logs`
- `actorId`, `actorName`
- `action`, `entityType`, `entityId`
- `metadata`, `createdAt`

`settings`
- app-level preferences and finance categories when needed

## Storage

`properties/{propertyId}/files/{filename}`
- Property attachments and legal/accounting documents
- Metadata read via Firebase Storage in the property Files tab

## Query Notes

- Global collections keep filters/indexes simple for the two-partner workflow.
- `propertyId` is duplicated on accounting records for efficient property detail queries.
- `archived` is used for soft deletion on properties and expenses.
- Every write model carries audit fields for activity logging and reporting.
