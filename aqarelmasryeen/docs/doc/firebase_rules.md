# Firebase Rules

الـ rules الحالية في المشروع أصبحت متوافقة مع جميع الـ collections المستخدمة فعليًا بعد إزالة الـ mock layer.

## Firestore

- `users`: المستخدم يقرأ ويعدل ملفه فقط، ويمكن لأي شريك نشط إنشاء ملف شريك جديد أثناء provisioning.
- `user_email_lookup`: فهرس خفيف لربط البريد بـ `uid` ويُستخدم في طلبات ربط الشركاء بدون كشف ملف المستخدم الكامل.
- `notifications`: القراءة والتحديث لصاحب الإشعار فقط، والإنشاء لأي شريك نشط.
- `activity_logs`: قراءة وإنشاء فقط للشركاء النشطين، بدون تعديل أو حذف.
- `settings`: قراءة وكتابة للشركاء النشطين.
- باقي collections التشغيلية:
  - `partners`
  - `properties`
  - `expenses`
  - `material_expenses`
  - `units`
  - `installment_plans`
  - `installments`
  - `payments`
  - `partner_ledgers`

جميعها متاحة قراءة وكتابة للشركاء النشطين فقط.

## Storage

الملفات تقرأ وتكتب تحت:

```text
properties/{propertyId}/files/{fileName}
```

بشرط وجود مستخدم مسجل دخول.

## Deployment

انشر الملفات التالية:

- `firestore.rules`
- `storage.rules`
- `firestore.indexes.json`
