const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * 유지보수 포인트:
 * 앱에서 동일 callable(sendTradeProposalPush)로
 * 제안/승낙/코드 알림을 모두 전송하므로, payload를 범용으로 처리합니다.
 */
exports.sendTradeProposalPush = onCall(async (request) => {
  const authUid = request.auth?.uid ?? "";
  const {
    targetUid = "",
    senderUid = "",
    offerId = "",
    title = "",
    body = "",
    type = "market_notification",
  } = request.data ?? {};

  const normalizedTargetUid = String(targetUid).trim();
  const normalizedSenderUid = String(senderUid).trim();
  const normalizedOfferId = String(offerId).trim();
  const normalizedTitle = String(title).trim();
  const normalizedBody = String(body).trim();
  const normalizedType = String(type).trim() || "market_notification";

  if (!authUid) {
    throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
  }
  if (!normalizedTargetUid) {
    throw new HttpsError("invalid-argument", "targetUid가 필요합니다.");
  }
  if (!normalizedSenderUid) {
    throw new HttpsError("invalid-argument", "senderUid가 필요합니다.");
  }
  if (!normalizedOfferId) {
    throw new HttpsError("invalid-argument", "offerId가 필요합니다.");
  }
  if (authUid !== normalizedSenderUid) {
    throw new HttpsError("permission-denied", "senderUid가 인증 사용자와 다릅니다.");
  }

  const pushAllowed = await isPushEnabledForType({
    targetUid: normalizedTargetUid,
    type: normalizedType,
  });
  if (!pushAllowed) {
    logger.info("Push skipped by user notification preference", {
      targetUid: normalizedTargetUid,
      offerId: normalizedOfferId,
      type: normalizedType,
    });
    return {
      ok: true,
      sentCount: 0,
      failCount: 0,
      reason: "preference_disabled",
    };
  }

  const tokens = await collectUserFcmTokens(normalizedTargetUid);
  if (tokens.length === 0) {
    logger.info("No FCM tokens for target user", {
      targetUid: normalizedTargetUid,
      offerId: normalizedOfferId,
      type: normalizedType,
    });
    return {
      ok: true,
      sentCount: 0,
      failCount: 0,
      reason: "no_tokens",
    };
  }

  const message = {
    tokens,
    notification: {
      title: normalizedTitle || "새 알림",
      body: normalizedBody || "새로운 활동이 있어요.",
    },
    data: {
      type: normalizedType,
      offerId: normalizedOfferId,
      senderUid: normalizedSenderUid,
      title: normalizedTitle,
      body: normalizedBody,
    },
    android: {
      priority: "high",
      notification: {
        channelId: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  };

  const response = await messaging.sendEachForMulticast(message);

  const invalidTokens = [];
  response.responses.forEach((item, index) => {
    if (item.success) {
      return;
    }
    const code = item.error?.code ?? "";
    const token = tokens[index];
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      invalidTokens.push(token);
    }
  });

  if (invalidTokens.length > 0) {
    await cleanupInvalidTokens(normalizedTargetUid, invalidTokens);
  }

  logger.info("sendTradeProposalPush done", {
    targetUid: normalizedTargetUid,
    offerId: normalizedOfferId,
    type: normalizedType,
    successCount: response.successCount,
    failureCount: response.failureCount,
  });

  return {
    ok: true,
    sentCount: response.successCount,
    failCount: response.failureCount,
    invalidTokenCount: invalidTokens.length,
  };
});

async function isPushEnabledForType({targetUid, type}) {
  const preferenceField = resolveNotificationPreferenceField(type);
  if (!preferenceField) {
    return true;
  }

  try {
    const prefDoc = await db
        .collection("users")
        .doc(targetUid)
        .collection("settings")
        .doc("notifications")
        .get();
    if (!prefDoc.exists) {
      return true;
    }

    const data = prefDoc.data() ?? {};
    const enabled = data[preferenceField];
    if (typeof enabled === "boolean") {
      return enabled;
    }
  } catch (error) {
    logger.warn("Failed to read notification preference. fallback=true", {
      targetUid,
      type,
      error: String(error),
    });
  }

  return true;
}

function resolveNotificationPreferenceField(type) {
  switch ((type ?? "").trim()) {
    case "market_trade_proposal":
    case "market_trade_cancel":
    case "market_trade_complete":
      return "tradeOfferEnabled";
    case "market_trade_accept":
    case "market_trade_code":
      return "dodoCodeInviteEnabled";
    case "airport_queue_standby":
      return "airportQueueStandbyEnabled";
    default:
      return "";
  }
}

async function collectUserFcmTokens(uid) {
  const userRef = db.collection("users").doc(uid);

  const fcmTokensSnap = await userRef.collection("fcmTokens").get();

  const tokenSet = new Set();
  for (const doc of fcmTokensSnap.docs) {
    const data = doc.data() ?? {};
    addToken(tokenSet, data.token);
    addToken(tokenSet, doc.id);
  }

  // 유지보수 포인트:
  // 토큰 저장 구조를 users/{uid}/fcmTokens로 단일화했지만,
  // 마이그레이션 과도기에는 레거시 필드/컬렉션을 fallback으로 허용합니다.
  if (tokenSet.size === 0) {
    const [userSnap, devicesSnap, pushTokensSnap] = await Promise.all([
      userRef.get(),
      userRef.collection("devices").get(),
      userRef.collection("pushTokens").get(),
    ]);

    if (userSnap.exists) {
      const data = userSnap.data() ?? {};
      addToken(tokenSet, data.fcmtoken);
      addToken(tokenSet, data.fcmToken);
      addToken(tokenSet, data.pushToken);
      addToken(tokenSet, data.deviceToken);

      if (Array.isArray(data.fcmTokens)) {
        data.fcmTokens.forEach((value) => addToken(tokenSet, value));
      }
      if (Array.isArray(data.pushTokens)) {
        data.pushTokens.forEach((value) => addToken(tokenSet, value));
      }
    }

    for (const doc of devicesSnap.docs) {
      const data = doc.data() ?? {};
      addToken(tokenSet, data.fcmToken);
      addToken(tokenSet, data.token);
      addToken(tokenSet, doc.id);
    }
    for (const doc of pushTokensSnap.docs) {
      const data = doc.data() ?? {};
      addToken(tokenSet, data.fcmToken);
      addToken(tokenSet, data.token);
      addToken(tokenSet, doc.id);
    }
  }

  return Array.from(tokenSet);
}

function addToken(tokenSet, rawValue) {
  if (typeof rawValue !== "string") {
    return;
  }
  const token = rawValue.trim();
  // 유지보수 포인트:
  // FCM 토큰은 길이가 길기 때문에 최소 길이로 20을 사용해
  // 잘못된 문서 id(uid 등)가 섞여도 전송 대상에서 제외합니다.
  if (token.length < 20) {
    return;
  }
  tokenSet.add(token);
}

async function cleanupInvalidTokens(uid, invalidTokens) {
  if (!invalidTokens.length) {
    return;
  }
  const userRef = db.collection("users").doc(uid);
  const batch = db.batch();

  batch.set(userRef, {
    fcmtoken: FieldValue.delete(),
    fcmToken: FieldValue.delete(),
    fcmTokens: FieldValue.arrayRemove(...invalidTokens),
    pushToken: FieldValue.delete(),
    pushTokens: FieldValue.arrayRemove(...invalidTokens),
    deviceToken: FieldValue.delete(),
  }, {merge: true});

  for (const token of invalidTokens) {
    batch.delete(userRef.collection("devices").doc(token));
    batch.delete(userRef.collection("pushTokens").doc(token));
    batch.delete(userRef.collection("fcmTokens").doc(token));
  }

  await batch.commit();
}
