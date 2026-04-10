# Firebase Rules

الوثيقة هنا تحتوي الكود الجاهز نفسه، بحيث يكون عندك مرجع مباشر داخل `docs` متوافق مع الملفات الفعلية في جذر المشروع.

## Firestore rules

هذه القواعد تسمح بالوصول فقط للمستخدم الشريك النشط الذي لديه مستند صحيح داخل `users/{uid}`.

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    function currentUserDoc() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid));
    }

    function currentUserExists() {
      return exists(/databases/$(database)/documents/users/$(request.auth.uid));
    }

    function isActivePartner() {
      return isSignedIn()
        && currentUserExists()
        && currentUserDoc().data.role == 'partner'
        && currentUserDoc().data.isActive == true;
    }

    function immutableUserCore(userId) {
      return request.resource.data.uid == userId
        && request.resource.data.role == resource.data.role
        && request.resource.data.createdAt == resource.data.createdAt;
    }

    function validUserProfile(userId) {
      return request.resource.data.uid == userId
        && request.resource.data.role == 'partner'
        && request.resource.data.fullName is string
        && request.resource.data.email is string
        && request.resource.data.biometricEnabled is bool
        && request.resource.data.appLockEnabled is bool
        && (request.resource.data.trustedDeviceEnabled == null
          || request.resource.data.trustedDeviceEnabled is bool)
        && request.resource.data.isActive is bool
        && request.resource.data.inactivityTimeoutSeconds is int
        && request.resource.data.inactivityTimeoutSeconds >= 30
        && request.resource.data.inactivityTimeoutSeconds <= 300;
    }

    match /users/{userId} {
      allow create: if (isOwner(userId) || isActivePartner())
        && validUserProfile(userId)
        && request.resource.data.isActive == true;

      allow read: if isOwner(userId);

      allow update: if isOwner(userId)
        && immutableUserCore(userId)
        && validUserProfile(userId);

      allow delete: if false;
    }

    match /user_email_lookup/{email} {
      allow read: if isActivePartner();
      allow create, update: if isSignedIn()
        && request.resource.data.uid is string
        && request.resource.data.email == email
        && (request.auth.uid == request.resource.data.uid || isActivePartner());
      allow delete: if isSignedIn()
        && (request.auth.uid == resource.data.uid || isActivePartner());
    }

    match /notifications/{notificationId} {
      allow create: if isActivePartner();
      allow read, update: if isActivePartner()
        && resource.data.userId == request.auth.uid;
      allow delete: if false;
    }

    match /activity_logs/{logId} {
      allow create, read: if isActivePartner();
      allow update, delete: if false;
    }

    match /settings/{settingId} {
      allow read, write: if isActivePartner();
    }

    match /{collection}/{documentId} {
      allow read, write: if isActivePartner()
        && collection in [
          'partners',
          'properties',
          'expenses',
          'unit_expenses',
          'material_expenses',
          'supplier_payments',
          'units',
          'installment_plans',
          'installments',
          'payments',
          'partner_ledgers'
        ];
    }
  }
}
```

## Storage rules

```js
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function isSignedIn() {
      return request.auth != null;
    }

    function isPartner() {
      return isSignedIn();
    }

    match /properties/{propertyId}/files/{fileName} {
      allow read, write: if isPartner();
    }
  }
}
```

## What these rules expect

- وجود مستند للمستخدم الحالي داخل `users/{uid}`.
- أن يكون `role == 'partner'`.
- أن يكون `isActive == true`.
- أن تكون الإعدادات الأساسية في ملف المستخدم موجودة مثل `fullName` و `email` و `biometricEnabled` و `appLockEnabled` و `inactivityTimeoutSeconds`.

إذا ظهر في التطبيق `permission-denied` عند فتح المشروعات أو بيانات العقار، فأول شيء يجب التحقق منه هو مستند `users/{uid}` قبل مراجعة الشاشة نفسها.

## Deployment

انشر الملفات التالية:

- `firestore.rules`
- `storage.rules`
- `firestore.indexes.json`

أوامر النشر المعتادة:

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
```
