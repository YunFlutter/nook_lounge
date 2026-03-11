const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {getStorage} = require("firebase-admin/storage");

initializeApp();

const auth = getAuth();
const db = getFirestore();
const messaging = getMessaging();
const storage = getStorage();
const USER_DELETE_QUERY_PAGE_SIZE = 40;
const WITHDRAWAL_ARCHIVE_RETENTION_DAYS = parseWithdrawalRetentionDays();

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

/**
 * 유지보수 포인트:
 * 탈퇴는 Auth/Firestore/Storage를 함께 정리해야 하므로
 * 클라이언트 권한 대신 Admin SDK callable에서 일괄 처리합니다.
 */
exports.deleteUserAccount = onCall({timeoutSeconds: 300}, async (request) => {
  const authUid = String(request.auth?.uid ?? "").trim();

  if (!authUid) {
    throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
  }

  logger.info("deleteUserAccount started", {uid: authUid});

  const archiveRef = withdrawalArchiveRef(authUid);
  let currentStage = "archive_seed";

  try {
    const archiveSeed = await buildWithdrawalArchiveSeed(authUid);
    await archiveRef.set(archiveSeed, {merge: true});

    currentStage = "firestore_delete";
    const firestoreDeletionSummary = await deleteUserRelatedFirestore(authUid);
    currentStage = "storage_delete";
    await deleteUserRelatedStorage(authUid);
    currentStage = "auth_delete";
    await deleteAuthUser(authUid);
    currentStage = "archive_complete";
    await archiveRef.set({
      archiveStatus: "completed",
      authDeleted: true,
      authDeletedAt: new Date(),
      deletedDataSummary: firestoreDeletionSummary,
      updatedAt: new Date(),
    }, {merge: true});
  } catch (error) {
    console.error(
        formatWithdrawalDebugSummary({
          uid: authUid,
          stage: currentStage,
          error,
        }),
    );

    await markWithdrawalArchiveFailed(archiveRef, error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw buildWithdrawalInternalError({
      stage: currentStage,
      error,
    });
  }

  logger.info("deleteUserAccount done", {uid: authUid});
  return {ok: true};
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

async function deleteUserRelatedFirestore(uid) {
  const normalizedUid = String(uid).trim();
  if (!normalizedUid) {
    return {};
  }

  const deletionSummary = {};

  deletionSummary.marketPostsOwned = await runDeletionTask(
      "marketPosts.ownerUid",
      () => deleteQueryDocuments(
          db.collection("marketPosts").where("ownerUid", "==", normalizedUid),
          "marketPosts.ownerUid",
      ),
  );
  deletionSummary.marketTradeCodesOwned = await runDeletionTask(
      "marketTradeCodes.ownerUid",
      () => deleteQueryDocuments(
          db.collection("marketTradeCodes").where("ownerUid", "==", normalizedUid),
          "marketTradeCodes.ownerUid",
      ),
  );
  deletionSummary.marketTradeCodesParticipated = await runDeletionTask(
      "marketTradeCodes.proposerUid",
      () => deleteQueryDocuments(
          db.collection("marketTradeCodes").where("proposerUid", "==", normalizedUid),
          "marketTradeCodes.proposerUid",
      ),
  );
  deletionSummary.marketProposalsOwned = "handled_by_marketPosts_cleanup";
  deletionSummary.marketProposalsParticipated = await runDeletionTask(
      "proposals.proposerUid",
      () => deleteQueryDocuments(
          db.collectionGroup("proposals").where("proposerUid", "==", normalizedUid),
          "proposals.proposerUid",
      ),
  );
  deletionSummary.airportQueuesOwned = await runDeletionTask(
      "airportQueues.ownerUid",
      () => deleteQueryDocuments(
          db.collection("airportQueues").where("ownerUid", "==", normalizedUid),
          "airportQueues.ownerUid",
      ),
  );
  deletionSummary.airportRequestsHosted = "handled_by_airportQueues_cleanup";
  deletionSummary.airportRequestsRequested = await runDeletionTask(
      "requests.requesterUid",
      () => deleteQueryDocuments(
          db.collectionGroup("requests").where("requesterUid", "==", normalizedUid),
          "requests.requesterUid",
      ),
  );
  deletionSummary.supportInquiries = await runDeletionTask(
      "supportInquiries.uid",
      () => deleteQueryDocuments(
          db.collection("supportInquiries").where("uid", "==", normalizedUid),
          "supportInquiries.uid",
      ),
  );
  deletionSummary.reportsSubmitted = await runDeletionTask(
      "reports.reporterUid",
      () => deleteQueryDocuments(
          db.collection("reports").where("reporterUid", "==", normalizedUid),
          "reports.reporterUid",
      ),
  );
  deletionSummary.reportsAboutOwnedOffers = await runDeletionTask(
      "reports.offerOwnerUid",
      () => deleteQueryDocuments(
          db.collection("reports").where("offerOwnerUid", "==", normalizedUid),
          "reports.offerOwnerUid",
      ),
  );
  deletionSummary.reportsAsAirportHost = await runDeletionTask(
      "reports.requestHostUid",
      () => deleteQueryDocuments(
          db.collection("reports").where("requestHostUid", "==", normalizedUid),
          "reports.requestHostUid",
      ),
  );
  deletionSummary.reportsAsAirportRequester = await runDeletionTask(
      "reports.requestRequesterUid",
      () => deleteQueryDocuments(
          db.collection("reports").where("requestRequesterUid", "==", normalizedUid),
          "reports.requestRequesterUid",
      ),
  );
  deletionSummary.notificationsSent = await runDeletionTask(
      "notifications.senderUid",
      () => deleteQueryDocuments(
          db.collectionGroup("notifications").where("senderUid", "==", normalizedUid),
          "notifications.senderUid",
      ),
  );
  deletionSummary.blockedUserEdges = await runDeletionTask(
      "blockedUsers.blockedUid",
      () => deleteQueryDocuments(
          db.collectionGroup("blockedUsers").where("blockedUid", "==", normalizedUid),
          "blockedUsers.blockedUid",
      ),
  );
  deletionSummary.blockedByUserEdges = await runDeletionTask(
      "blockedByUsers.blockerUid",
      () => deleteQueryDocuments(
          db.collectionGroup("blockedByUsers").where("blockerUid", "==", normalizedUid),
          "blockedByUsers.blockerUid",
      ),
  );

  deletionSummary.userServiceBlock = await runDeletionTask(
      "userServiceBlocks.doc",
      () => safeDeleteDocument(db.collection("userServiceBlocks").doc(normalizedUid)),
  );

  // 유지보수 포인트:
  // users/{uid}는 마지막에 재귀 삭제해, 탈퇴 완료 직전까지는
  // 클라이언트 세션 문서 감시가 불필요하게 흔들리지 않도록 합니다.
  deletionSummary.userRootDeleted = await runDeletionTask(
      "users.root",
      () => safeRecursiveDelete(
          db.collection("users").doc(normalizedUid),
      ),
  );

  return deletionSummary;
}

async function deleteUserRelatedStorage(uid) {
  const normalizedUid = String(uid).trim();
  if (!normalizedUid) {
    return;
  }

  try {
    await storage.bucket().deleteFiles({
      prefix: `users/${normalizedUid}/`,
      force: true,
    });
  } catch (error) {
    logger.warn("deleteUserRelatedStorage skipped", {
      uid: normalizedUid,
      error: String(error),
    });
  }
}

async function deleteAuthUser(uid) {
  try {
    await auth.deleteUser(uid);
  } catch (error) {
    if (error?.code === "auth/user-not-found") {
      return;
    }
    throw error;
  }
}

async function deleteQueryDocuments(query, label) {
  let deletedCount = 0;

  while (true) {
    const snapshot = await query.limit(USER_DELETE_QUERY_PAGE_SIZE).get();
    if (snapshot.empty) {
      if (deletedCount > 0) {
        logger.info("deleteUserAccount query cleanup", {label, deletedCount});
      }
      return deletedCount;
    }

    for (const doc of snapshot.docs) {
      await safeRecursiveDelete(doc.ref);
      deletedCount += 1;
    }

    if (snapshot.size < USER_DELETE_QUERY_PAGE_SIZE) {
      logger.info("deleteUserAccount query cleanup", {label, deletedCount});
      return deletedCount;
    }
  }
}

async function safeRecursiveDelete(ref) {
  await db.recursiveDelete(ref);
  return true;
}

async function safeDeleteDocument(ref) {
  try {
    await ref.delete();
    return true;
  } catch (error) {
    const code = String(error?.code ?? "");
    if (code === "5" || code === "not-found") {
      return false;
    }
    throw error;
  }
}

async function runDeletionTask(label, task) {
  try {
    return await task();
  } catch (error) {
    throw new Error(
        `[firestore_delete:${label}] ${sanitizeWithdrawalErrorMessage(error)}`,
    );
  }
}

function withdrawalArchiveRef(uid) {
  return db.collection("complianceArchives")
      .doc("withdrawnUsers")
      .collection("records")
      .doc(uid);
}

async function buildWithdrawalArchiveSeed(uid) {
  const now = new Date();
  const retentionUntil = new Date(
      now.getTime() + WITHDRAWAL_ARCHIVE_RETENTION_DAYS * 24 * 60 * 60 * 1000,
  );
  const authSnapshot = await safeGetUserRecord(uid);

  return {
    uid,
    archiveStatus: "in_progress",
    withdrawalReason: "self_service_withdrawal",
    archiveSchemaVersion: 1,
    legalHold: false,
    retentionDays: WITHDRAWAL_ARCHIVE_RETENTION_DAYS,
    retentionReason: "withdrawal_minimum_compliance_archive",
    withdrawnAt: now,
    retentionUntil,
    authDeleted: false,
    deletedAuthProviders: authSnapshot.providerIds,
    createdAt: now,
    updatedAt: now,
  };
}

async function markWithdrawalArchiveFailed(archiveRef, error) {
  try {
    await archiveRef.set({
      archiveStatus: "failed",
      lastErrorCode: String(error?.code ?? "unknown"),
      lastErrorMessage: String(error?.message ?? error ?? "unknown"),
      updatedAt: new Date(),
    }, {merge: true});
  } catch (archiveError) {
    logger.warn("deleteUserAccount archive failure update skipped", {
      archivePath: archiveRef.path,
      error: String(archiveError),
    });
  }
}

async function safeGetUserRecord(uid) {
  try {
    const userRecord = await auth.getUser(uid);
    return {
      providerIds: userRecord.providerData
          .map((provider) => String(provider.providerId ?? "").trim())
          .filter((providerId) => providerId),
    };
  } catch (error) {
    if (error?.code === "auth/user-not-found") {
      return {providerIds: []};
    }
    throw error;
  }
}

function parseWithdrawalRetentionDays() {
  const rawValue = String(
      process.env.WITHDRAWAL_ARCHIVE_RETENTION_DAYS ?? "1095",
  ).trim();
  const parsedValue = Number.parseInt(rawValue, 10);

  // 유지보수 포인트:
  // 보관 기간은 개인정보처리방침/법무 검토 기준으로 조정할 수 있도록
  // 환경변수로 덮어쓸 수 있게 두고, 기본값은 3년(1095일)로 둡니다.
  if (!Number.isFinite(parsedValue) || parsedValue <= 0) {
    return 1095;
  }
  return parsedValue;
}

function buildWithdrawalInternalError({stage, error}) {
  const rawMessage = sanitizeWithdrawalErrorMessage(error);

  return new HttpsError(
      "internal",
      `탈퇴 처리 중 오류가 발생했어요. [${stage}] ${rawMessage}`,
      {
        stage,
        message: rawMessage,
      },
  );
}

function formatWithdrawalDebugSummary({uid, stage, error}) {
  const rawMessage = sanitizeWithdrawalErrorMessage(error);
  return `deleteUserAccount failed uid=${uid} stage=${stage} error=${rawMessage}`;
}

function sanitizeWithdrawalErrorMessage(error) {
  const rawMessage = String(error?.message ?? error ?? "unknown");
  const normalizedMessage = rawMessage.replace(/\s+/g, " ").trim();

  if (!normalizedMessage) {
    return "unknown";
  }

  if (normalizedMessage.length <= 300) {
    return normalizedMessage;
  }

  return `${normalizedMessage.slice(0, 300)}...`;
}
