# دليل CI / CD للمشروع

هذا الدليل يشرح طريقة تشغيل CI على GitHub Actions وطريقة تنفيذ نفس الفحوصات محليًا.

## 1) أين ملف CI؟

تمت إضافة ملف:

- `.github/workflows/ci.yml`

ويشمل خطَّي عمل:

1. **Flutter Checks**
   - `flutter pub get`
   - `flutter analyze`
   - `flutter test`
   - `flutter build web --release` (sanity check)
2. **Firebase Functions Checks** (إذا كان مجلد `functions` موجودًا)
   - `npm ci`
   - `npm run lint` (إذا script موجود)
   - `npm test` (إذا script موجود)

---

## 2) كيف يعمل CI على GitHub؟

1. ارفع التعديلات إلى أي branch.
2. سيعمل الـ workflow تلقائيًا مع `push` أو `pull_request`.
3. من تبويب **Actions** في GitHub:
   - افتح تشغيل الـ workflow.
   - راجع Job: `Flutter Checks` و`Firebase Functions Checks`.
4. إذا كانت كل الخطوات خضراء ✅ فهذا يعني أن CI نجح.

---

## 3) التشغيل المحلي (نفس فكرة CI)

> من داخل جذر المشروع:

### Flutter

```bash
cd aqarelmasryeen
flutter --version
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-tree-shake-icons
```

### Functions

```bash
cd aqarelmasryeen/functions
node -v
npm ci
npm run lint   # إذا كان متوفرًا
npm test       # إذا كان متوفرًا
```

---

## 4) ماذا أفعل إذا فشل `flutter analyze`؟

1. اقرأ أول خطأ ظاهر في السجل.
2. أصلح الملف المذكور.
3. أعد تشغيل:

```bash
flutter analyze
```

4. إذا كان الخطأ متعلقًا بـ null-safety أو imports أو lints، أصلحه ثم أعد تشغيل `flutter test`.

---

## 5) ماذا أفعل إذا فشل `npm ci` داخل functions؟

1. تأكد أنك داخل `aqarelmasryeen/functions`.
2. تأكد من نسخة Node المطابقة.
3. احذف `node_modules` وحاول مجددًا:

```bash
rm -rf node_modules
npm ci
```

4. إذا استمر الفشل، راجع `package-lock.json` أو توافق الحزم.

---

## 6) الإصدارات المطلوبة

- **Flutter:** `3.24.5` (كما هو محدد في workflow).
- **Node.js:** `20` (مطابق لـ `functions/package.json` engines).

---

## 7) متطلبات Firebase

لتشغيل التطبيق والفانكشنز بشكل صحيح:

- إعداد مشروع Firebase وربط `firebase_options.dart`.
- تفعيل Authentication (Email/Password).
- إعداد Firestore وقواعد الأمان.
- نشر Cloud Functions عند الحاجة:

```bash
cd aqarelmasryeen/functions
npm ci
npm run deploy
```

---

## 8) الفرق بين CI و CD هنا

- **CI (Continuous Integration):**
  - فحص جودة الكود واكتشاف الأعطال مبكرًا (analyze/test/build checks).
- **CD (Continuous Delivery/Deployment):**
  - نشر تلقائي (مثلاً deploy إلى Firebase Hosting أو Functions) بعد نجاح CI.

حاليًا الملف المضاف يركز على **CI** فقط.

---

## 9) ما المطلوب قبل تفعيل CD؟

قبل إضافة نشر تلقائي، جهّز:

1. **Secrets** في GitHub:
   - `FIREBASE_SERVICE_ACCOUNT` أو `GOOGLE_APPLICATION_CREDENTIALS` (حسب طريقة النشر)
   - `FIREBASE_PROJECT_ID`
2. صلاحيات Service Account المناسبة (Hosting/Functions/Firestore).
3. قرار واضح: هل النشر على `main` فقط أم أيضًا على `staging`.
4. إضافة خطوة deploy في workflow بعد نجاح جميع Jobs.

---

## 10) رسائل النجاح والفشل

- عند نجاح CI: **"تم تشغيل CI بنجاح"**.
- عند فشل CI: **"فشل CI، راجع السجلات"**.

