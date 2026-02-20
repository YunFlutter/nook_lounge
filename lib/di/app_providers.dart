import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nook_lounge_app/data/datasource/firebase_auth_data_source.dart';
import 'package:nook_lounge_app/data/datasource/island_firestore_data_source.dart';
import 'package:nook_lounge_app/data/datasource/local_catalog_data_source.dart';
import 'package:nook_lounge_app/data/repository/auth_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/catalog_repository_impl.dart';
import 'package:nook_lounge_app/data/repository/island_repository_impl.dart';
import 'package:nook_lounge_app/domain/repository/auth_repository.dart';
import 'package:nook_lounge_app/domain/repository/catalog_repository.dart';
import 'package:nook_lounge_app/domain/repository/island_repository.dart';
import 'package:nook_lounge_app/presentation/state/catalog_search_view_state.dart';
import 'package:nook_lounge_app/presentation/state/create_island_view_state.dart';
import 'package:nook_lounge_app/presentation/state/home_shell_view_state.dart';
import 'package:nook_lounge_app/presentation/state/session_view_state.dart';
import 'package:nook_lounge_app/presentation/state/sign_in_view_state.dart';
import 'package:nook_lounge_app/presentation/viewmodel/catalog_search_view_model.dart';
import 'package:nook_lounge_app/presentation/viewmodel/create_island_view_model.dart';
import 'package:nook_lounge_app/presentation/viewmodel/home_shell_view_model.dart';
import 'package:nook_lounge_app/presentation/viewmodel/session_view_model.dart';
import 'package:nook_lounge_app/presentation/viewmodel/sign_in_view_model.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final islandFirestoreDataSourceProvider = Provider<IslandFirestoreDataSource>((
  ref,
) {
  return IslandFirestoreDataSource(firestore: ref.watch(firestoreProvider));
});

final localCatalogDataSourceProvider = Provider<LocalCatalogDataSource>((ref) {
  return LocalCatalogDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dataSource: ref.watch(firebaseAuthDataSourceProvider),
  );
});

final islandRepositoryProvider = Provider<IslandRepository>((ref) {
  return IslandRepositoryImpl(
    dataSource: ref.watch(islandFirestoreDataSourceProvider),
  );
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(
    dataSource: ref.watch(localCatalogDataSourceProvider),
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
