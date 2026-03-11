import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nook_lounge_app/core/utils/app_version_comparator.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry_provider.dart';
import 'package:nook_lounge_app/data/datasource/app_version_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/app_version_platform_data_source.dart';
import 'package:nook_lounge_app/data/datasource/catalog_state_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/firebase_auth_data_source.dart';
import 'package:nook_lounge_app/data/datasource/airport_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/island_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/island_storage_data_source.dart';
import 'package:nook_lounge_app/data/datasource/local_catalog_data_source.dart';
import 'package:nook_lounge_app/data/datasource/market_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/market_storage_data_source.dart';
import 'package:nook_lounge_app/data/datasource/settings_firestore_data_source.dart';
import 'package:nook_lounge_app/data/service/local_notification_service.dart';
import 'package:nook_lounge_app/data/service/push_message_service.dart';
import 'package:nook_lounge_app/data/datasource/turnip_api_data_source.dart';
import 'package:nook_lounge_app/data/datasource/turnip_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/user_block_firestore_data_source.dart';
import 'package:nook_lounge_app/data/repository/auth_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/app_version_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/airport_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/catalog_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/island_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/market_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/settings_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/turnip_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/user_block_repository_impl.dart';
import 'package:nook_lounge_app/domain/repository/auth_repository.dart';
import 'package:nook_lounge_app/domain/repository/app_version_repository.dart';
import 'package:nook_lounge_app/domain/repository/airport_repository.dart';
import 'package:nook_lounge_app/domain/repository/catalog_repository.dart';
import 'package:nook_lounge_app/domain/repository/island_repository.dart';
import 'package:nook_lounge_app/domain/repository/market_repository.dart';
import 'package:nook_lounge_app/domain/repository/settings_repository.dart';
import 'package:nook_lounge_app/domain/repository/turnip_repository.dart';
import 'package:nook_lounge_app/domain/repository/user_block_repository.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';
import 'package:nook_lounge_app/domain/model/app_update_status.dart';
import 'package:nook_lounge_app/domain/model/blocked_user_summary.dart';
import 'package:nook_lounge_app/domain/model/market_trade_proposal.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/domain/model/market_user_notification.dart';
import 'package:nook_lounge_app/domain/model/settings_document.dart';
import 'package:nook_lounge_app/domain/model/settings_faq_item.dart';
import 'package:nook_lounge_app/domain/model/settings_notice.dart';
import 'package:nook_lounge_app/domain/model/settings_notification_preferences.dart';
import 'package:nook_lounge_app/domain/model/support_inquiry.dart';
import 'package:nook_lounge_app/presentation/state/catalog_search_view_state.dart';
import 'package:nook_lounge_app/presentation/state/create_island_view_state.dart';
import 'package:nook_lounge_app/presentation/state/home_shell_view_state.dart';
import 'package:nook_lounge_app/presentation/state/market_view_state.dart';
import 'package:nook_lounge_app/presentation/state/airport_view_state.dart';
import 'package:nook_lounge_app/presentation/state/push_offer_intent_notifier.dart';
import 'package:nook_lounge_app/presentation/state/session_view_state.dart';
import 'package:nook_lounge_app/presentation/state/sign_in_view_state.dart';
import 'package:nook_lounge_app/presentation/state/turnip_view_state.dart';
import 'package:nook_lounge_app/presentation/viewmodel/airport_view_model.dart';
import 'package:nook_lounge_app/presentation/viewmodel/catalog_search_view_model.dart';
import 'package:nook_lounge_app/presentation/viewmodel/catalog_binding_view_model.dart';
import 'package:nook_lounge_app/presentation/viewmodel/create_island_view_model.dart';
import 'package:nook_lounge_app/presentation/viewmodel/home_shell_view_model.dart';
import 'package:nook_lounge_app/presentation/viewmodel/market_view_model.dart';
import 'package:nook_lounge_app/presentation/viewmodel/session_view_model.dart';
import 'package:nook_lounge_app/presentation/viewmodel/sign_in_view_model.dart';
import 'package:nook_lounge_app/presentation/viewmodel/turnip_view_model.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final appVersionComparatorProvider = Provider<AppVersionComparator>((ref) {
  return const AppVersionComparator();
});

final flutterLocalNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  return LocalNotificationService(
    plugin: ref.watch(flutterLocalNotificationsPluginProvider),
  );
});

final pushOfferIntentNotifierProvider =
    StateNotifierProvider<PushOfferIntentNotifier, String?>((ref) {
      return PushOfferIntentNotifier();
    });

final pushMessageServiceProvider = Provider<PushMessageService>((ref) {
  final service = PushMessageService(
    messaging: ref.watch(firebaseMessagingProvider),
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    localNotificationService: ref.watch(localNotificationServiceProvider),
    offerIntentNotifier: ref.watch(pushOfferIntentNotifierProvider.notifier),
    telemetry: ref.watch(appTelemetryProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final islandFirestoreDataSourceProvider = Provider<IslandFirestoreDataSource>((
  ref,
) {
  return IslandFirestoreDataSource(firestore: ref.watch(firestoreProvider));
});

final islandStorageDataSourceProvider = Provider<IslandStorageDataSource>((
  ref,
) {
  return IslandStorageDataSource(storage: ref.watch(firebaseStorageProvider));
});

final localCatalogDataSourceProvider = Provider<LocalCatalogDataSource>((ref) {
  return LocalCatalogDataSource();
});

final catalogStateFirestoreDataSourceProvider =
    Provider<CatalogStateFirestoreDataSource>((ref) {
      return CatalogStateFirestoreDataSource(
        firestore: ref.watch(firestoreProvider),
      );
    });

final turnipApiDataSourceProvider = Provider<TurnipApiDataSource>((ref) {
  return TurnipApiDataSource();
});

final turnipFirestoreDataSourceProvider = Provider<TurnipFirestoreDataSource>((
  ref,
) {
  return TurnipFirestoreDataSource(firestore: ref.watch(firestoreProvider));
});

final marketFirestoreDataSourceProvider = Provider<MarketFirestoreDataSource>((
  ref,
) {
  return MarketFirestoreDataSource(firestore: ref.watch(firestoreProvider));
});

final marketStorageDataSourceProvider = Provider<MarketStorageDataSource>((
  ref,
) {
  return MarketStorageDataSource(storage: ref.watch(firebaseStorageProvider));
});

final appVersionFirestoreDataSourceProvider =
    Provider<AppVersionFirestoreDataSource>((ref) {
      return AppVersionFirestoreDataSource(
        firestore: ref.watch(firestoreProvider),
      );
    });

final appVersionPlatformDataSourceProvider =
    Provider<AppVersionPlatformDataSource>((ref) {
      return AppVersionPlatformDataSource();
    });

final settingsFirestoreDataSourceProvider =
    Provider<SettingsFirestoreDataSource>((ref) {
      return SettingsFirestoreDataSource(
        firestore: ref.watch(firestoreProvider),
      );
    });

final airportFirestoreDataSourceProvider = Provider<AirportFirestoreDataSource>(
  (ref) {
    return AirportFirestoreDataSource(firestore: ref.watch(firestoreProvider));
  },
);

final userBlockFirestoreDataSourceProvider =
    Provider<UserBlockFirestoreDataSource>((ref) {
      return UserBlockFirestoreDataSource(
        firestore: ref.watch(firestoreProvider),
      );
    });

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dataSource: ref.watch(firebaseAuthDataSourceProvider),
    telemetry: ref.watch(appTelemetryProvider),
  );
});

final islandRepositoryProvider = Provider<IslandRepository>((ref) {
  return IslandRepositoryImpl(
    firestoreDataSource: ref.watch(islandFirestoreDataSourceProvider),
    storageDataSource: ref.watch(islandStorageDataSourceProvider),
    telemetry: ref.watch(appTelemetryProvider),
  );
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(
    dataSource: ref.watch(localCatalogDataSourceProvider),
    stateDataSource: ref.watch(catalogStateFirestoreDataSourceProvider),
  );
});

final turnipRepositoryProvider = Provider<TurnipRepository>((ref) {
  return TurnipRepositoryImpl(
    apiDataSource: ref.watch(turnipApiDataSourceProvider),
    firestoreDataSource: ref.watch(turnipFirestoreDataSourceProvider),
  );
});

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepositoryImpl(
    firestoreDataSource: ref.watch(marketFirestoreDataSourceProvider),
    storageDataSource: ref.watch(marketStorageDataSourceProvider),
    telemetry: ref.watch(appTelemetryProvider),
  );
});

final appVersionRepositoryProvider = Provider<AppVersionRepository>((ref) {
  return AppVersionRepositoryImpl(
    dataSource: ref.watch(appVersionFirestoreDataSourceProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    dataSource: ref.watch(settingsFirestoreDataSourceProvider),
  );
});

final airportRepositoryProvider = Provider<AirportRepository>((ref) {
  return AirportRepositoryImpl(
    dataSource: ref.watch(airportFirestoreDataSourceProvider),
    telemetry: ref.watch(appTelemetryProvider),
  );
});

final userBlockRepositoryProvider = Provider<UserBlockRepository>((ref) {
  return UserBlockRepositoryImpl(
    dataSource: ref.watch(userBlockFirestoreDataSourceProvider),
  );
});

final sessionViewModelProvider =
    StateNotifierProvider<SessionViewModel, SessionViewState>((ref) {
      // 유지보수 포인트:
      // 인증/섬 상태 분기 책임은 SessionViewModel 하나로 집중합니다.
      return SessionViewModel(
        authRepository: ref.watch(authRepositoryProvider),
        islandRepository: ref.watch(islandRepositoryProvider),
      );
    });

final signInViewModelProvider =
    StateNotifierProvider<SignInViewModel, SignInViewState>((ref) {
      return SignInViewModel(authRepository: ref.watch(authRepositoryProvider));
    });

final createIslandViewModelProvider =
    StateNotifierProvider<CreateIslandViewModel, CreateIslandViewState>((ref) {
      return CreateIslandViewModel(
        islandRepository: ref.watch(islandRepositoryProvider),
      );
    });

final homeShellViewModelProvider =
    StateNotifierProvider<HomeShellViewModel, HomeShellViewState>((ref) {
      return HomeShellViewModel(telemetry: ref.watch(appTelemetryProvider));
    });

final catalogSearchViewModelProvider =
    StateNotifierProvider<CatalogSearchViewModel, CatalogSearchViewState>((
      ref,
    ) {
      return CatalogSearchViewModel(
        catalogRepository: ref.watch(catalogRepositoryProvider),
      );
    });

final catalogBindingViewModelProvider =
    StateNotifierProvider.family<
      CatalogBindingViewModel,
      Map<String, CatalogUserState>,
      ({String uid, String islandId})
    >((ref, args) {
      return CatalogBindingViewModel(
        catalogRepository: ref.watch(catalogRepositoryProvider),
        uid: args.uid,
        islandId: args.islandId,
      );
    });

final turnipViewModelProvider =
    StateNotifierProvider.family<
      TurnipViewModel,
      TurnipViewState,
      ({String uid, String islandId})
    >((ref, args) {
      return TurnipViewModel(
        repository: ref.watch(turnipRepositoryProvider),
        telemetry: ref.watch(appTelemetryProvider),
        uid: args.uid,
        islandId: args.islandId,
      );
    });

final marketViewModelProvider =
    StateNotifierProvider<MarketViewModel, MarketViewState>((ref) {
      return MarketViewModel(
        repository: ref.watch(marketRepositoryProvider),
        authRepository: ref.watch(authRepositoryProvider),
        userBlockRepository: ref.watch(userBlockRepositoryProvider),
      );
    });

final airportViewModelProvider =
    StateNotifierProvider.family<
      AirportViewModel,
      AirportViewState,
      ({String uid, String islandId})
    >((ref, args) {
      return AirportViewModel(
        repository: ref.watch(airportRepositoryProvider),
        userBlockRepository: ref.watch(userBlockRepositoryProvider),
        uid: args.uid,
        islandId: args.islandId,
      );
    });

final marketTradeCodeSessionProvider =
    StreamProvider.family<MarketTradeCodeSession?, String>((ref, offerId) {
      return ref.watch(marketRepositoryProvider).watchTradeCodeSession(offerId);
    });

final marketTradeRuleAgreementProvider =
    StreamProvider.family<bool, ({String offerId, String receiverUid})>((
      ref,
      args,
    ) {
      return ref
          .watch(marketRepositoryProvider)
          .watchTradeRuleAgreement(
            offerId: args.offerId,
            receiverUid: args.receiverUid,
          );
    });

final marketTradeProposalsProvider =
    StreamProvider.family<List<MarketTradeProposal>, String>((ref, offerId) {
      return ref.watch(marketRepositoryProvider).watchTradeProposals(offerId);
    });

final marketMyTradeProposalProvider =
    StreamProvider.family<
      MarketTradeProposal?,
      ({String offerId, String proposerUid})
    >((ref, args) {
      return ref
          .watch(marketRepositoryProvider)
          .watchMyTradeProposal(
            offerId: args.offerId,
            proposerUid: args.proposerUid,
          );
    });

final marketUserNotificationsProvider =
    StreamProvider.family<List<MarketUserNotification>, String>((ref, uid) {
      final normalizedUid = uid.trim();
      if (normalizedUid.isEmpty) {
        return Stream<List<MarketUserNotification>>.value(
          const <MarketUserNotification>[],
        );
      }

      final marketRepository = ref.watch(marketRepositoryProvider);
      final userBlockRepository = ref.watch(userBlockRepositoryProvider);
      late final StreamController<List<MarketUserNotification>> controller;
      StreamSubscription<List<MarketUserNotification>>?
      notificationSubscription;
      StreamSubscription<Set<String>>? invisibleUserSubscription;
      var latestNotifications = const <MarketUserNotification>[];
      var invisibleUserIds = const <String>{};

      void emit() {
        controller.add(
          latestNotifications
              .where((notification) {
                return !invisibleUserIds.contains(
                  notification.senderUid.trim(),
                );
              })
              .toList(growable: false),
        );
      }

      controller = StreamController<List<MarketUserNotification>>(
        onListen: () {
          notificationSubscription = marketRepository
              .watchUserNotifications(normalizedUid)
              .listen((notifications) {
                latestNotifications = notifications;
                emit();
              }, onError: controller.addError);
          invisibleUserSubscription = userBlockRepository
              .watchInvisibleUserIds(normalizedUid)
              .listen((ids) {
                invisibleUserIds = ids;
                emit();
              }, onError: controller.addError);
        },
        onCancel: () async {
          await notificationSubscription?.cancel();
          await invisibleUserSubscription?.cancel();
        },
      );

      ref.onDispose(() async {
        await notificationSubscription?.cancel();
        await invisibleUserSubscription?.cancel();
        await controller.close();
      });

      return controller.stream;
    });

final blockedUserSummariesProvider =
    StreamProvider.family<List<BlockedUserSummary>, String>((ref, uid) {
      return ref.watch(userBlockRepositoryProvider).watchBlockedUsers(uid);
    });

final settingsNotificationPreferencesProvider =
    StreamProvider.family<SettingsNotificationPreferences, String>((ref, uid) {
      return ref
          .watch(settingsRepositoryProvider)
          .watchNotificationPreferences(uid: uid);
    });

final settingsNoticesProvider = StreamProvider<List<SettingsNotice>>((ref) {
  return ref.watch(settingsRepositoryProvider).watchNotices();
});

final settingsDocumentProvider =
    StreamProvider.family<SettingsDocument, SettingsDocumentType>((ref, type) {
      return ref.watch(settingsRepositoryProvider).watchDocument(type);
    });

final settingsFaqItemsProvider = StreamProvider<List<SettingsFaqItem>>((ref) {
  return ref.watch(settingsRepositoryProvider).watchFaqItems();
});

final settingsInquiriesProvider =
    StreamProvider.family<List<SupportInquiry>, String>((ref, uid) {
      return ref.watch(settingsRepositoryProvider).watchInquiries(uid: uid);
    });

final currentAppVersionProvider = FutureProvider<String>((ref) {
  return ref.watch(appVersionPlatformDataSourceProvider).fetchCurrentVersion();
});

final appUpdateStatusProvider = StreamProvider<AppUpdateStatus>((ref) async* {
  final currentVersion = await ref.watch(currentAppVersionProvider.future);
  final repository = ref.watch(appVersionRepositoryProvider);
  final comparator = ref.watch(appVersionComparatorProvider);

  await for (final config in repository.watchConfig()) {
    final rawRemoteVersion = switch (defaultTargetPlatform) {
      TargetPlatform.android => config?.androidVersion,
      TargetPlatform.iOS => config?.iosVersion,
      _ => null,
    };
    final remoteVersion = rawRemoteVersion?.trim();
    final requiresUpdate =
        remoteVersion != null &&
        remoteVersion.isNotEmpty &&
        comparator.compare(currentVersion, remoteVersion) < 0;

    yield AppUpdateStatus(
      currentVersion: currentVersion,
      remoteVersion: remoteVersion,
      requiresUpdate: requiresUpdate,
    );
  }
});
