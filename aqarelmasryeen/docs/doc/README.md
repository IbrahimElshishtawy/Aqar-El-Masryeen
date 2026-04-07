# Firebase Documentation

الملفات داخل هذا المجلد مخصصة لتجهيز وربط Firebase للمشروع:

- `firebase_schema.md`
  وصف الكولكشنز والحقول والعلاقات بين البيانات.
- `firebase_rules.md`
  قواعد Firestore وStorage المقترحة لحماية البيانات.
- `firebase_integration_checklist.md`
  خطوات التنفيذ العملية داخل Firebase Console ومع التطبيق.

هذه الملفات مبنية على الكود الحالي في المشروع داخل `lib/` وعلى الملفات:

- `firestore.rules`
- `storage.rules`
- `firestore.indexes.json`

إذا تم تعديل الـ models أو الـ repositories لاحقًا، يُفضَّل تحديث التوثيق هنا أيضًا.
