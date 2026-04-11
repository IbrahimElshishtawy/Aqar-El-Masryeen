const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const logger = require('firebase-functions/logger');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const DEFAULT_ROUTE = '/notifications';
const DEFAULT_CHANNEL_ID = 'finance_alerts';
const DEFAULT_WORKSPACE_ID = '';
const REMINDER_LEAD_DAYS = [7, 3, 1];
const MAX_TOKENS_PER_BATCH = 500;
const INVALID_TOKEN_CODES = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

exports.sendNotificationPush = onDocumentCreated(
  {
    document: 'notifications/{notificationId}',
    retry: false,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const notificationId = snapshot.id;
    const data = snapshot.data() || {};
    const metadata = isObject(data.metadata) ? data.metadata : {};
    const userId = asNonEmptyString(data.userId);
    const title = asNonEmptyString(data.title);
    const body = asNonEmptyString(data.body);
    const route = asNonEmptyString(data.route) || DEFAULT_ROUTE;
    const extraId = asNonEmptyString(metadata.extraId);
    const referenceKey = asNonEmptyString(data.referenceKey);

    if (!userId || (!title && !body)) {
      await writePushDelivery(snapshot.ref, {
        status: 'skipped',
        reason: 'missing_required_fields',
      });
      return;
    }

    try {
      const userSnapshot = await db.collection('users').doc(userId).get();
      if (!userSnapshot.exists) {
        await writePushDelivery(snapshot.ref, {
          status: 'skipped',
          reason: 'user_not_found',
        });
        return;
      }

      const tokens = uniqueNonEmptyStrings(userSnapshot.get('fcmTokens'));
      if (tokens.length == 0) {
        await writePushDelivery(snapshot.ref, {
          status: 'skipped',
          reason: 'no_registered_tokens',
        });
        return;
      }

      const payload = JSON.stringify({
        route,
        extraId: extraId || null,
      });

      let successCount = 0;
      let failureCount = 0;
      const invalidTokens = [];
      const failures = [];

      for (const tokenBatch of chunkArray(tokens, MAX_TOKENS_PER_BATCH)) {
        const response = await messaging.sendEachForMulticast(
          buildMulticastMessage({
            tokens: tokenBatch,
            title,
            body,
            route,
            extraId,
            notificationId,
            referenceKey,
            payload,
          }),
        );

        successCount += response.successCount;
        failureCount += response.failureCount;

        response.responses.forEach((result, index) => {
          if (result.success) {
            return;
          }

          const code = result.error?.code || 'messaging/unknown-error';
          const message =
            result.error?.message || 'Push delivery failed without details.';
          failures.push(`${code}: ${message}`);
          if (INVALID_TOKEN_CODES.has(code)) {
            invalidTokens.push(tokenBatch[index]);
          }
        });
      }

      if (invalidTokens.length > 0) {
        await userSnapshot.ref.set(
          {
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
            lastFcmTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }

      await writePushDelivery(snapshot.ref, {
        status: successCount > 0 ? 'sent' : 'failed',
        reason:
          successCount > 0
            ? 'sent_to_registered_devices'
            : 'all_delivery_attempts_failed',
        tokenCount: tokens.length,
        successCount,
        failureCount,
        invalidTokenCount: invalidTokens.length,
        errors: failures.slice(0, 5),
      });
    } catch (error) {
      logger.error('Failed to deliver notification push.', {
        notificationId,
        userId,
        error,
      });

      await writePushDelivery(snapshot.ref, {
        status: 'failed',
        reason: 'function_error',
        errors: [error instanceof Error ? error.message : String(error)],
      });
    }
  },
);

exports.provisionPartnerAccount = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً.');
  }

  const fullName = asNonEmptyString(request.data?.fullName);
  const email = asNonEmptyString(request.data?.email).toLowerCase();
  const password = asNonEmptyString(request.data?.password);
  const createdBy = asNonEmptyString(request.data?.createdBy) || request.auth.uid;
  const createdByName =
    asNonEmptyString(request.data?.createdByName) || fullName;
  let workspaceId = asNonEmptyString(request.data?.workspaceId);

  if (!fullName || !email || !password) {
    throw new HttpsError(
      'invalid-argument',
      'الاسم والبريد الإلكتروني وكلمة المرور مطلوبة.',
    );
  }

  if (password.length < 10) {
    throw new HttpsError(
      'invalid-argument',
      'يجب أن تكون كلمة المرور 10 أحرف على الأقل.',
    );
  }

  if (!workspaceId) {
    const callerSnapshot = await db.collection('users').doc(request.auth.uid).get();
    workspaceId = asNonEmptyString(callerSnapshot.get('workspaceId'));
  }

  if (!workspaceId) {
    throw new HttpsError(
      'failed-precondition',
      'لا يمكن إنشاء حساب شريك قبل ربط الحساب الحالي بمساحة عمل.',
    );
  }

  try {
    await admin.auth().getUserByEmail(email);
    throw new HttpsError(
      'already-exists',
      'يوجد حساب مسجل بهذا البريد الإلكتروني بالفعل.',
    );
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    if (error?.code !== 'auth/user-not-found') {
      logger.error('Failed while checking existing partner account.', {
        email,
        error,
      });
      throw new HttpsError(
        'failed-precondition',
        'تعذر التحقق من البريد الإلكتروني قبل إنشاء الحساب.',
      );
    }
  }

  let createdUser = null;

  try {
    createdUser = await admin.auth().createUser({
      email,
      password,
      displayName: fullName,
      disabled: false,
    });

    const userRef = db.collection('users').doc(createdUser.uid);
    const lookupRef = db.collection('user_email_lookup').doc(email);
    const now = admin.firestore.FieldValue.serverTimestamp();
    const batch = db.batch();

    batch.set(
      userRef,
      {
        uid: createdUser.uid,
        phone: '',
        fullName,
        name: fullName,
        email,
        role: 'partner',
        trustedDeviceEnabled: false,
        biometricEnabled: false,
        appLockEnabled: true,
        inactivityTimeoutSeconds: 90,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        createdBy,
        createdByName,
        workspaceId,
        linkedPartnerId: '',
        linkedPartnerName: '',
        fcmTokens: [],
      },
      { merge: true },
    );
    batch.set(
      lookupRef,
      {
        uid: createdUser.uid,
        email,
        updatedAt: now,
      },
      { merge: true },
    );

    await batch.commit();

    const userSnapshot = await userRef.get();
    return {
      success: true,
      user: serializeUserForCallable(userSnapshot),
    };
  } catch (error) {
    logger.error('Failed to provision partner account.', {
      caller: request.auth.uid,
      email,
      error,
    });

    if (createdUser?.uid) {
      try {
        await admin.auth().deleteUser(createdUser.uid);
      } catch (rollbackError) {
        logger.error('Failed to roll back created Auth user.', {
          uid: createdUser.uid,
          rollbackError,
        });
      }
    }

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      'failed-precondition',
      error instanceof Error
        ? error.message
        : 'تعذر إنشاء حساب الشريك في الوقت الحالي.',
    );
  }
});

exports.backfillAuthProfiles = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً.');
  }

  const callerDoc = await db.collection('users').doc(request.auth.uid).get();
  if (!callerDoc.exists || callerDoc.get('isActive') !== true) {
    throw new HttpsError(
      'permission-denied',
      'هذا الحساب غير مصرح له بتنفيذ مزامنة الحسابات.',
    );
  }

  const defaultWorkspaceId =
    asNonEmptyString(request.data?.workspaceId) ||
    asNonEmptyString(callerDoc.get('workspaceId'));
  let nextPageToken;
  let createdCount = 0;
  let updatedLookupCount = 0;

  do {
    const page = await admin.auth().listUsers(1000, nextPageToken);
    const batch = db.batch();
    let pageWrites = 0;
    for (const authUser of page.users) {
      const userRef = db.collection('users').doc(authUser.uid);
      const userSnapshot = await userRef.get();
      const normalizedEmail = asNonEmptyString(authUser.email).toLowerCase();
      const fullName =
        asNonEmptyString(authUser.displayName) ||
        (normalizedEmail ? normalizedEmail.split('@')[0] : 'مستخدم');
      const now = admin.firestore.FieldValue.serverTimestamp();

      if (!userSnapshot.exists) {
        batch.set(
          userRef,
          {
            uid: authUser.uid,
            phone: asNonEmptyString(authUser.phoneNumber),
            fullName,
            name: fullName,
            email: normalizedEmail,
            role: 'partner',
            trustedDeviceEnabled: false,
            biometricEnabled: false,
            appLockEnabled: true,
            inactivityTimeoutSeconds: 90,
            isActive: authUser.disabled !== true,
            createdAt: now,
            updatedAt: now,
            createdBy: request.auth.uid,
            createdByName:
              asNonEmptyString(callerDoc.get('fullName')) ||
              asNonEmptyString(callerDoc.get('name')) ||
              'System',
            workspaceId: defaultWorkspaceId,
            linkedPartnerId: '',
            linkedPartnerName: '',
            fcmTokens: [],
          },
          { merge: true },
        );
        createdCount += 1;
        pageWrites += 1;
      }

      if (normalizedEmail) {
        batch.set(
          db.collection('user_email_lookup').doc(normalizedEmail),
          {
            uid: authUser.uid,
            email: normalizedEmail,
            updatedAt: now,
          },
          { merge: true },
        );
        updatedLookupCount += 1;
        pageWrites += 1;
      }
    }

    if (pageWrites > 0) {
      await batch.commit();
    }
    nextPageToken = page.pageToken;
  } while (nextPageToken);

  return {
    success: true,
    createdCount,
    updatedLookupCount,
  };
});

exports.syncFinancialNotifications = onSchedule(
  {
    schedule: 'every 6 hours',
    timeZone: 'Africa/Cairo',
    retryCount: 0,
  },
  async () => {
    const activeUsers = await loadActiveUsers();
    if (activeUsers.length === 0) {
      logger.info('Skipping scheduled notifications because no active users were found.');
      return;
    }

    await syncInstallmentNotifications(activeUsers);
    await syncSupplierNotifications(activeUsers);
  },
);

async function syncInstallmentNotifications(activeUsers) {
  const snapshot = await db.collection('installments').get();
  const batch = db.batch();
  let writes = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data() || {};
    const amount = asNumber(data.amount);
    const paidAmount = asNumber(data.paidAmount);
    const status = asNonEmptyString(data.status);
    const dueDate = asDate(data.dueDate);

    if (!dueDate || amount <= 0) {
      continue;
    }
    if (status === 'paid' || paidAmount >= amount) {
      continue;
    }

    const diffDays = diffDaysFromToday(dueDate);
    const userIds = resolveWorkspaceUserIds(activeUsers, data.workspaceId);
    if (userIds.length === 0) {
      continue;
    }

    const propertyId = asNonEmptyString(data.propertyId);
    const unitId = asNonEmptyString(data.unitId);
    const sequence = asNumber(data.sequence);
    const unitLabel = unitId ? `الوحدة ${unitId}` : 'الوحدة';
    const dueDateLabel = dueDate.toISOString().split('T')[0];

    if (diffDays < 0) {
      for (const userId of userIds) {
        const notificationId = `installment-overdue-${doc.id}-${userId}`;
        batch.set(
          db.collection('notifications').doc(notificationId),
          buildNotificationPayload({
            userId,
            workspaceId: resolveWorkspaceId(data.workspaceId),
            title: 'قسط متأخر',
            body: `${unitLabel} - القسط ${sequence || '-'} متأخر عن السداد منذ ${dueDateLabel}.`,
            type: 'overdueInstallment',
            route: propertyId ? `/properties/${propertyId}` : DEFAULT_ROUTE,
            referenceKey: notificationId,
            metadata: {
              propertyId,
              unitId,
              installmentId: doc.id,
              dueDate: dueDateLabel,
            },
          }),
          { merge: true },
        );
        writes += 1;
      }
      continue;
    }

    if (!REMINDER_LEAD_DAYS.includes(diffDays)) {
      continue;
    }

    for (const userId of userIds) {
      const notificationId = `installment-due-${diffDays}-${doc.id}-${userId}`;
      batch.set(
        db.collection('notifications').doc(notificationId),
        buildNotificationPayload({
          userId,
          workspaceId: resolveWorkspaceId(data.workspaceId),
          title: 'قسط مستحق قريبًا',
          body: `${unitLabel} - القسط ${sequence || '-'} مستحق بعد ${diffDays} يوم بتاريخ ${dueDateLabel}.`,
          type: 'installmentDue',
          route: propertyId ? `/properties/${propertyId}` : DEFAULT_ROUTE,
          referenceKey: notificationId,
          metadata: {
            propertyId,
            unitId,
            installmentId: doc.id,
            dueDate: dueDateLabel,
            leadDays: diffDays,
          },
        }),
        { merge: true },
      );
      writes += 1;
    }
  }

  if (writes > 0) {
    await batch.commit();
  }
}

async function syncSupplierNotifications(activeUsers) {
  const snapshot = await db.collection('material_expenses').get();
  const batch = db.batch();
  let writes = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data() || {};
    const archived = data.archived === true;
    const dueDate = asDate(data.dueDate);
    const amountRemaining = asNumber(data.amountRemaining);

    if (archived || !dueDate || amountRemaining <= 0) {
      continue;
    }

    const diffDays = diffDaysFromToday(dueDate);
    const userIds = resolveWorkspaceUserIds(activeUsers, data.workspaceId);
    if (userIds.length === 0) {
      continue;
    }

    const propertyId = asNonEmptyString(data.propertyId);
    const supplierName = asNonEmptyString(data.supplierName) || 'المورد';
    const dueDateLabel = dueDate.toISOString().split('T')[0];

    if (diffDays < 0) {
      for (const userId of userIds) {
        const notificationId = `supplier-overdue-${doc.id}-${userId}`;
        batch.set(
          db.collection('notifications').doc(notificationId),
          buildNotificationPayload({
            userId,
            workspaceId: resolveWorkspaceId(data.workspaceId),
            title: 'دفعة مورد متأخرة',
            body: `${supplierName} لديه مبلغ متأخر بقيمة ${amountRemaining.toFixed(0)} يستحق منذ ${dueDateLabel}.`,
            type: 'supplierPaymentOverdue',
            route: propertyId ? `/properties/${propertyId}/materials` : '/expenses',
            referenceKey: notificationId,
            metadata: {
              propertyId,
              materialExpenseId: doc.id,
              supplierName,
              dueDate: dueDateLabel,
            },
          }),
          { merge: true },
        );
        writes += 1;
      }
      continue;
    }

    if (!REMINDER_LEAD_DAYS.includes(diffDays)) {
      continue;
    }

    for (const userId of userIds) {
      const notificationId = `supplier-due-${diffDays}-${doc.id}-${userId}`;
      batch.set(
        db.collection('notifications').doc(notificationId),
        buildNotificationPayload({
          userId,
          workspaceId: resolveWorkspaceId(data.workspaceId),
          title: 'استحقاق مورد قريب',
          body: `${supplierName} لديه استحقاق بعد ${diffDays} يوم بقيمة ${amountRemaining.toFixed(0)} بتاريخ ${dueDateLabel}.`,
          type: 'supplierPaymentDue',
          route: propertyId ? `/properties/${propertyId}/materials` : '/expenses',
          referenceKey: notificationId,
          metadata: {
            propertyId,
            materialExpenseId: doc.id,
            supplierName,
            dueDate: dueDateLabel,
            leadDays: diffDays,
          },
        }),
        { merge: true },
      );
      writes += 1;
    }
  }

  if (writes > 0) {
    await batch.commit();
  }
}

async function loadActiveUsers() {
  const snapshot = await db.collection('users').where('isActive', '==', true).get();
  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
}

function resolveWorkspaceUserIds(activeUsers, workspaceId) {
  const resolvedWorkspaceId = resolveWorkspaceId(workspaceId);
  if (!resolvedWorkspaceId) {
    return [];
  }
  return activeUsers
    .filter((user) => resolveWorkspaceId(user.workspaceId) === resolvedWorkspaceId)
    .map((user) => user.id)
    .filter(Boolean);
}

function resolveWorkspaceId(workspaceId) {
  return asNonEmptyString(workspaceId) || DEFAULT_WORKSPACE_ID;
}

function buildNotificationPayload({
  userId,
  workspaceId,
  title,
  body,
  type,
  route,
  referenceKey,
  metadata,
}) {
  return {
    userId,
    workspaceId,
    title,
    body,
    type,
    route,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    referenceKey,
    metadata,
    pushDelivery: {
      status: 'queued',
      reason: 'awaiting_function_dispatch',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  };
}

function serializeUserForCallable(snapshot) {
  const data = snapshot.data() || {};
  return {
    uid: snapshot.id,
    phone: asNonEmptyString(data.phone),
    fullName: asNonEmptyString(data.fullName || data.name),
    name: asNonEmptyString(data.name || data.fullName),
    email: asNonEmptyString(data.email).toLowerCase(),
    role: asNonEmptyString(data.role) || 'partner',
    trustedDeviceEnabled: data.trustedDeviceEnabled === true,
    biometricEnabled: data.biometricEnabled === true,
    appLockEnabled: data.appLockEnabled !== false,
    inactivityTimeoutSeconds: asNumber(data.inactivityTimeoutSeconds) || 90,
    isActive: data.isActive !== false,
    createdAt: asDate(data.createdAt)?.toISOString() || new Date().toISOString(),
    updatedAt: asDate(data.updatedAt)?.toISOString() || new Date().toISOString(),
    lastLoginAt: asDate(data.lastLoginAt)?.toISOString() || null,
    securitySetupCompletedAt:
      asDate(data.securitySetupCompletedAt)?.toISOString() || null,
    createdBy: asNonEmptyString(data.createdBy),
    createdByName: asNonEmptyString(data.createdByName),
    workspaceId: resolveWorkspaceId(data.workspaceId),
    linkedPartnerId: asNonEmptyString(data.linkedPartnerId),
    linkedPartnerName: asNonEmptyString(data.linkedPartnerName),
    fcmTokens: Array.isArray(data.fcmTokens) ? data.fcmTokens : [],
  };
}

function asDate(value) {
  if (!value) {
    return null;
  }
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate();
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value === 'string' || typeof value === 'number') {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  return null;
}

function asNumber(value) {
  if (typeof value === 'number') {
    return value;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

function diffDaysFromToday(targetDate) {
  const today = new Date();
  const startOfToday = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const startOfTarget = new Date(
    targetDate.getFullYear(),
    targetDate.getMonth(),
    targetDate.getDate(),
  );
  return Math.round((startOfTarget - startOfToday) / 86400000);
}

function buildMulticastMessage({
  tokens,
  title,
  body,
  route,
  extraId,
  notificationId,
  referenceKey,
  payload,
}) {
  const data = {
    notificationId,
    route,
    payload,
    title,
    body,
  };

  if (referenceKey) {
    data.referenceKey = referenceKey;
  }
  if (extraId) {
    data.extraId = extraId;
  }

  return {
    tokens,
    notification: {
      title,
      body,
    },
    data,
    android: {
      priority: 'high',
      notification: {
        channelId: DEFAULT_CHANNEL_ID,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        defaultSound: true,
      },
    },
    apns: {
      headers: {
        'apns-priority': '10',
      },
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
          contentAvailable: true,
        },
      },
    },
  };
}

async function writePushDelivery(
  documentReference,
  {
    status,
    reason,
    tokenCount = 0,
    successCount = 0,
    failureCount = 0,
    invalidTokenCount = 0,
    errors = [],
  },
) {
  await documentReference.set(
    {
      pushDelivery: {
        status,
        reason,
        tokenCount,
        successCount,
        failureCount,
        invalidTokenCount,
        errors,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    },
    { merge: true },
  );
}

function chunkArray(items, chunkSize) {
  const chunks = [];
  for (let index = 0; index < items.length; index += chunkSize) {
    chunks.push(items.slice(index, index + chunkSize));
  }
  return chunks;
}

function uniqueNonEmptyStrings(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return [...new Set(value.map(asNonEmptyString).filter(Boolean))];
}

function asNonEmptyString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function isObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}
