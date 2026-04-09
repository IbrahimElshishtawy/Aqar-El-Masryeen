const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const DEFAULT_ROUTE = '/notifications';
const DEFAULT_CHANNEL_ID = 'finance_alerts';
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
