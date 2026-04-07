# Firebase Rules

## الهدف

الملف ده يوضح قواعد الحماية المقترحة لـ Firestore وStorage بما يتوافق مع الكود الحالي في المشروع.

## Firestore Rules المقترحة

القواعد التالية مناسبة للوضع الحالي حيث كل المستخدمين في التطبيق دورهم `partner`، وكل مستخدم يقرأ بروفايله فقط، وباقي البيانات متاحة للشركاء النشطين فقط.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }

    function currentUserPath() {
      return /databases/$(database)/documents/users/$(request.auth.uid);
    }

    function currentUserExists() {
      return isSignedIn() && exists(currentUserPath());
    }

    function currentUserDoc() {
      return get(currentUserPath());
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    function isActivePartner() {
      return currentUserExists()
        && currentUserDoc().data.role == 'partner'
        && currentUserDoc().data.isActive == true;
    }

    function validUserProfile(userId) {
      return request.resource.data.uid == userId
        && request.resource.data.role == 'partner'
        && request.resource.data.fullName is string
        && request.resource.data.email is string
        && request.resource.data.biometricEnabled is bool
        && request.resource.data.appLockEnabled is bool
        && request.resource.data.isActive is bool
        && request.resource.data.inactivityTimeoutSeconds is int
        && request.resource.data.inactivityTimeoutSeconds >= 30
        && request.resource.data.inactivityTimeoutSeconds <= 300;
    }

    function immutableUserCore(userId) {
      return request.resource.data.uid == userId
        && request.resource.data.role == resource.data.role
        && request.resource.data.createdAt == resource.data.createdAt;
    }

    match /users/{userId} {
      allow create: if isOwner(userId)
        && validUserProfile(userId)
        && request.resource.data.isActive == true;

      allow read: if isOwner(userId);

      allow update: if isOwner(userId)
        && immutableUserCore(userId)
        && validUserProfile(userId);

      allow delete: if false;
    }

    match /notifications/{notificationId} {
      allow create: if isActivePartner();
      allow read, update: if isActivePartner()
        && resource.data.userId == request.auth.uid;
      allow delete: if false;
    }

    match /{collection}/{documentId} {
      allow read, write: if isActivePartner()
        && collection in [
          'partners',
          'properties',
          'expenses',
          'units',
          'installment_plans',
          'installments',
          'payments',
          'material_expenses',
          'partner_ledgers',
          'activity_logs',
          'settings'
        ];
    }
  }
}
```

## Storage Rules المقترحة

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function isSignedIn() {
      return request.auth != null;
    }

    match /properties/{propertyId}/files/{fileName} {
      allow read, write: if isSignedIn();
    }
  }
}
```

## ملاحظات مهمة على الرولز الحالية في الريبو

الملف الحالي `firestore.rules` جيد كبداية، لكن توجد فجوات مقارنة بالكود:

- `material_expenses` مستخدمة في الكود لكنها غير موجودة في list الخاصة بـ `/{collection}/{documentId}`.
- `partner_ledgers` مستخدمة في الكود لكنها غير موجودة أيضًا في نفس الـ list.
- `notifications` لها rule مستقلة، وهذا صحيح، لكن باقي التوثيق لازم يوضح أنها collection أساسية مع `userId`.
- لو قررتوا لاحقًا تقسيم الوصول حسب الشركة أو المشروع، ستحتاجون إضافة حقول ownership واضحة مثل `workspaceId`.

## Validation Rules إضافية مقترحة مستقبلًا

لو أردتم تشديد الحماية لاحقًا، يفضّل إضافة checks مثل:

- التأكد أن `amount >= 0` في `expenses`, `payments`, `installments`, `partner_ledgers`.
- التأكد أن `propertyId` و`unitId` strings غير فارغة.
- منع تعديل `createdAt` بعد الإنشاء في معظم collections.
- منع حذف البيانات نهائيًا والاعتماد على `archived = true`.
- حصر تعديل `notifications.isRead` فقط بدل تحديث كامل المستند.

## App Check

بما أن المشروع يفعّل `Firebase App Check` في `firebase_initializer.dart`، يجب التأكد من:

- تفعيل App Check من Firebase Console.
- إضافة المزود المناسب لكل منصة.
- اختبار التطبيق في وضع debug أو production حسب مفاتيح App Check.
