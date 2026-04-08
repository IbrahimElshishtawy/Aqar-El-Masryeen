# Firebase Integration Checklist

## Firebase Console

1. فعّل Authentication.
2. فعّل Email/Password.
3. فعّل Firestore.
4. فعّل Storage.
5. فعّل Cloud Messaging.
6. فعّل Analytics.
7. فعّل Crashlytics.
8. فعّل App Check.

## Project files to deploy

1. انشر `firestore.rules`.
2. انشر `storage.rules`.
3. انشر `firestore.indexes.json`.

## Collections expected by the app

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

## Smoke test order

1. سجّل مستخدم جديد.
2. تأكد من إنشاء `users/{uid}`.
3. أنشئ شريكًا داخل `partners`.
4. أنشئ مشروعًا داخل `properties`.
5. أضف وحدة داخل `units`.
6. أضف خطة تقسيط داخل `installment_plans`.
7. تأكد من توليد الأقساط داخل `installments`.
8. أضف دفعة داخل `payments`.
9. أضف مصروفًا داخل `expenses`.
10. أضف مصروف خامات داخل `material_expenses`.
11. أضف قيد شريك داخل `partner_ledgers`.
12. راقب ظهور إشعار داخل `notifications`.
13. جرّب قراءة ملفات المشروع من Storage.
