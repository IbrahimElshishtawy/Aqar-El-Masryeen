# Firebase Setup

## Services to enable

- Authentication
  - Email/Password
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Firebase Analytics
- Firebase Crashlytics
- Firebase App Check

## Platform status

- Android config موجود بالفعل في `android/app/google-services.json`.
- iOS يحتاج `ios/Runner/GoogleService-Info.plist`.
- Firebase initialization يعمل من `lib/core/services/firebase_initializer.dart`.

## Firestore collections

أنشئ أو اسمح للتطبيق بإنشاء هذه الـ collections:

- `users`
- `user_email_lookup`
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

## Required rules and indexes

- انشر `firestore.rules`.
- انشر `storage.rules`.
- انشر `firestore.indexes.json`.

## Recommended rollout

1. فعّل Authentication و Firestore و Storage.
2. انشر `firestore.rules` و `storage.rules`.
3. انشر `firestore.indexes.json`.
4. أنشئ أول مستخدم من التطبيق.
5. تأكد من إنشاء `users/{uid}` بعد التسجيل أو أول دخول.
6. اختبر إنشاء مشروع.
7. اختبر إنشاء وحدة.
8. اختبر خطة تقسيط ثم أقساط.
9. اختبر تسجيل دفعة ومصروف ومصروف خامات.
10. اختبر الإشعارات وقراءة الملفات من Storage.

## Important note

المشروع لم يعد يعتمد على أي mock data داخل `lib/`، وكل القراءة والكتابة الحالية أصبحت موجهة إلى Firebase فقط.
