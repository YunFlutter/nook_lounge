import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nook_lounge_app/data/datasource/catalog_state_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/firebase_auth_data_source.dart';
import 'package:nook_lounge_app/data/datasource/island_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/island_storage_data_source.dart';
import 'package:nook_lounge_app/data/datasource/local_catalog_data_source.dart';
import 'package:nook_lounge_app/data/datasource/market_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/turnip_api_data_source.dart';
import 'package:nook_lounge_app/data/datasource/turnip_firestore_data_source.dart';
import 'package:nook_lounge_app/data/repository/auth_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/catalog_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/island_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/market_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/turnip_repository_impl.dart';
import 'package:nook_lounge_app/domain/repository/auth_repository.dart';
import 'package:nook_lounge_app/domain/repository/catalog_repository.dart';
import 'package:nook_lounge_app/domain/repository/island_repository.dart';
import 'package:nook_lounge_app/domain/repository/market_repository.dart';
import 'package:nook_lounge_app/domain/repository/turnip_repository.dart';
import 'package:nook_lounge_app/domain/model/catalog_user_state.dart';
import 'package:nook_lounge_app/presentation/state/catalog_search_view_state.dart';
import 'package:nook_lounge_app/presentation/state/create_island_view_state.dart';
import 'package:nook_lounge_app/presentation/state/home_shell_view_state.dart';
import 'package:nook_lounge_app/presentation/state/market_view_state.dart';
import 'package:nook_lounge_app/presentation/state/session_view_state.dart';
import 'package:nook_lounge_app/presentation/state/sign_in_view_state.dart';
import 'package:nook_lounge_app/presentation/state/turnip_view_state.dart';
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

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dataSource: ref.watch(firebaseAuthDataSourceProvider),
  );
});

final islandRepositoryProvider = Provider<IslandRepository>((ref) {
  return IslandRepositoryImpl(
    firestoreDataSource: ref.watch(islandFirestoreDataSourceProvider),
    storageDataSource: ref.watch(islandStorageDataSourceProvider),
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
      return HomeShellViewModel();
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
        uid: args.uid,
        islandId: args.islandId,
      );
    });

final marketViewModelProvider =
    StateNotifierProvider<MarketViewModel, MarketViewState>((ref) {
      return MarketViewModel(
        repository: ref.watch(marketRepositoryProvider),
        authRepository: ref.watch(authRepositoryProvider),
      );
    });
