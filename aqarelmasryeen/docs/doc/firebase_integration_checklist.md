# Firebase Integration Checklist

## 1. Products to Enable

فعّل الخدمات التالية من Firebase Console:

1. Authentication
2. Cloud Firestore
3. Storage
4. Cloud Messaging
5. Analytics
6. Crashlytics
7. App Check

## 2. Authentication

فعّل:

- Phone Authentication
- Email/Password

ثم تأكد أن كل مستخدم بعد التسجيل لديه document داخل:

```text
users/{uid}
```

بنفس قيمة `uid` القادمة من Firebase Auth.

## 3. Firestore Collections to Create

أنشئ أو ابدأ استخدام الـ collections التالية:

- `users`
- `partners`
- `properties`
- `units`
- `expenses`
- `material_expenses`
- `installment_plans`
- `installments`
- `payments`
- `partner_ledgers`
- `notifications`
- `activity_logs`
- `settings`

## 4. Firestore Rules

انسخ القواعد الموجودة في:

- `docs/doc/firebase_rules.md`

ثم راجعها قبل النشر حسب بيئة العمل.

## 5. Firestore Indexes

بجانب الـ indexes الحالية، أضف indexes للكولكشنز التالية إذا ظهر خطأ من Firestore:

- `material_expenses`
  الحقول: `archived ASC`, `date DESC`
- `material_expenses`
  الحقول: `propertyId ASC`, `archived ASC`, `date DESC`
- `installments`
  الحقول: `unitId ASC`, `dueDate ASC`
- `payments`
  الحقول: `unitId ASC`, `receivedAt DESC`
- `partner_ledgers`
  الحقول: `archived ASC`, `updatedAt DESC`

## 6. Storage

اربط الملفات على المسار:

```text
properties/{propertyId}/files/{fileName}
```

ويُفضَّل أن يكون اسم الملف unique مثل:

```text
{timestamp}_{originalFileName}
```

## 7. Data Writing Rules داخل التطبيق

عند كل عملية حفظ في Firestore:

- استخدم `doc(id).set(..., SetOptions(merge: true))` عند الحاجة للتحديث المرن
- اكتب `createdAt` عند الإنشاء فقط
- حدّث `updatedAt` في كل تعديل
- اكتب `createdBy` و`updatedBy`
- استخدم `archived = true` بدل الحذف النهائي عندما يكون ذلك مناسبًا

## 8. Relations to Respect

قبل الحفظ، تأكد من العلاقات التالية:

- لا تنشئ `unit` إلا لو `propertyId` موجود
- لا تنشئ `installment_plan` إلا لو `unitId` و`propertyId` صحيحين
- لا تنشئ `installment` إلا لو `planId` موجود
- لا تنشئ `payment` مرتبط بقسط إلا لو `installmentId` صحيح
- لا تنشئ `expense` أو `partner_ledger` إلا لو `partnerId` أو `paidByPartnerId` صحيح

## 9. Current Gaps in Repository

النقاط التي تحتاج انتباه وقت الربط:

- `firestore.rules` الحالية لا تسمح بـ `material_expenses` و`partner_ledgers` رغم أن التطبيق يستخدمهما.
- `firestore.indexes.json` الحالية لا تحتوي كل الـ indexes المطلوبة من جميع الـ queries.
- `settings` معرفة كمسار فقط، لكن لا يوجد schema واضح لها حتى الآن.

## 10. Suggested Rollout Order

1. فعّل Authentication وFirestore وStorage
2. انشر `firestore.rules`
3. انشر `storage.rules`
4. أضف الـ indexes
5. أنشئ أول user document بعد أول login
6. اختبر إنشاء property
7. اختبر إنشاء unit
8. اختبر installments وpayments
9. اختبر notifications وfile uploads
