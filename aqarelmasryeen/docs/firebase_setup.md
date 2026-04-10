# Firebase Setup

## Services to enable

- Authentication
  - Email/Password
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Cloud Functions
- Firebase Analytics
- Firebase Crashlytics
- Firebase App Check

## Platform status

- Android config موجود بالفعل في `android/app/google-services.json`.
- iOS التهيئة الأساسية تتم من `lib/firebase_options.dart`، لكن Push Notifications يحتاج:
  - تفعيل `Push Notifications` و `Background Modes` داخل Xcode.
  - تفعيل `Remote notifications` و `Background fetch`.
  - رفع `APNs Authentication Key` أو `APNs certificates` داخل Firebase Console.
- Firebase initialization يعمل من `lib/core/services/firebase_initializer.dart`.
- إرسال Push الخارجي أصبح معتمدًا على `functions/index.js` عند إنشاء مستند جديد داخل `notifications`.

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
- راجع الكود الجاهز داخل `docs/doc/firebase_rules.md`.

## Cloud Functions setup

1. ادخل إلى مجلد `functions`.
2. ثبّت الاعتمادات:

```bash
npm install
```

3. انشر الدوال:

```bash
firebase deploy --only functions
```

الدالة `sendNotificationPush` ستراقب:

```text
notifications/{notificationId}
```

وعند إنشاء مستند جديد ستقرأ `users/{uid}.fcmTokens` وترسل Push فعلي إلى Android وiOS.

## Recommended rollout

1. فعّل Authentication و Firestore و Storage.
2. انشر `firestore.rules` و `storage.rules`.
3. انشر `firestore.indexes.json`.
4. أنشئ أول مستخدم من التطبيق.
5. تأكد من إنشاء `users/{uid}` بعد التسجيل أو أول دخول.
6. تأكد أن `users/{uid}.role == 'partner'` و `users/{uid}.isActive == true`.
7. اختبر إنشاء مشروع.
8. اختبر إنشاء وحدة.
9. اختبر خطة تقسيط ثم أقساط.
10. اختبر تسجيل دفعة ومصروف ومصروف خامات.
11. اختبر إنشاء مستند جديد داخل `notifications`.
12. تأكد من ظهور `pushDelivery.status` داخل نفس المستند بعد تشغيل Function.
13. اختبر الإشعار والتطبيق في foreground وbackground وclosed state على Android وiPhone.

## Important note

المشروع لم يعد يعتمد على أي mock data داخل `lib/`، وكل القراءة والكتابة الحالية أصبحت موجهة إلى Firebase فقط.
