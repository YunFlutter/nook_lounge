import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/repository/auth_repository.dart';
import 'package:nook_lounge_app/domain/repository/market_repository.dart';
import 'package:nook_lounge_app/domain/repository/user_block_repository.dart';
import 'package:nook_lounge_app/presentation/viewmodel/market_view_model.dart';

void main() {
  group('MarketViewModel', () {
    late _FakeMarketRepository marketRepository;
    late _FakeAuthRepository authRepository;
    late _FakeUserBlockRepository userBlockRepository;
    late MarketViewModel viewModel;

    setUp(() {
      marketRepository = _FakeMarketRepository();
      authRepository = _FakeAuthRepository(currentUserId: 'me');
      userBlockRepository = _FakeUserBlockRepository();
      viewModel = MarketViewModel(
        repository: marketRepository,
        authRepository: authRepository,
        userBlockRepository: userBlockRepository,
      );
    });

    tearDown(() async {
      viewModel.dispose();
      await marketRepository.dispose();
      await authRepository.dispose();
      await userBlockRepository.dispose();
    });

    test('나를 차단한 유저의 거래글도 목록에서 숨긴다', () async {
      marketRepository.hiddenOfferIdsController.add(const <String>{});
      userBlockRepository.invisibleUserIdsController.add(const <String>{
        'blocked-user',
      });
      marketRepository.offersController.add(<MarketOffer>[
        _buildOffer(id: 'mine', ownerUid: 'me'),
        _buildOffer(id: 'visible', ownerUid: 'visible-user'),
        _buildOffer(id: 'blocked', ownerUid: 'blocked-user'),
      ]);

      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state.offers.map((offer) => offer.id), <String>[
        'mine',
        'visible',
      ]);
    });

    test('차단 관계인 유저에게는 거래 제안을 보내지 않는다', () async {
      final blockedOffer = _buildOffer(id: 'blocked', ownerUid: 'blocked-user');
      userBlockRepository.hasBlockRelationshipResult = true;

      await expectLater(
        () => viewModel.sendTradeProposal(offer: blockedOffer),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'blocked_user',
          ),
        ),
      );
      expect(viewModel.state.errorMessage, '차단된 유저와는 거래 제안을 할 수 없어요.');
      expect(marketRepository.sendTradeProposalCallCount, 0);
    });
  });
}

MarketOffer _buildOffer({required String id, required String ownerUid}) {
  final now = DateTime(2026, 3, 10, 12);
  return MarketOffer(
    id: id,
    ownerUid: ownerUid,
    category: MarketFilterCategory.item,
    boardType: MarketBoardType.exchange,
    lifecycle: MarketLifecycleTab.ongoing,
    status: MarketOfferStatus.open,
    ownerName: ownerUid,
    ownerAvatarUrl: '',
    title: '$id title',
    offerHeaderLabel: '드려요',
    offerItemName: '사과',
    offerItemImageUrl: '',
    offerItemQuantity: 1,
    wantHeaderLabel: '받아요',
    wantItemName: '배',
    wantItemImageUrl: '',
    wantItemQuantity: 1,
    touchingTags: const <String>[],
    entryFeeText: '무료',
    description: '설명',
    tradeType: MarketTradeType.exchange,
    moveType: MarketMoveType.host,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeMarketRepository implements MarketRepository {
  final StreamController<List<MarketOffer>> offersController =
      StreamController<List<MarketOffer>>.broadcast();
  final StreamController<Set<String>> hiddenOfferIdsController =
      StreamController<Set<String>>.broadcast();
  int sendTradeProposalCallCount = 0;

  Future<void> dispose() async {
    await offersController.close();
    await hiddenOfferIdsController.close();
  }

  @override
  Stream<List<MarketOffer>> watchOffers() => offersController.stream;

  @override
  Stream<Set<String>> watchHiddenOfferIds(String uid) {
    return hiddenOfferIdsController.stream;
  }

  @override
  Future<void> sendTradeProposalNotification({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required String offerTitle,
  }) async {
    sendTradeProposalCallCount += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.currentUserId});

  final StreamController<String?> userIdController =
      StreamController<String?>.broadcast();

  @override
  final String? currentUserId;

  Future<void> dispose() async {
    await userIdController.close();
  }

  @override
  Stream<String?> watchUserId() => userIdController.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserBlockRepository implements UserBlockRepository {
  final StreamController<Set<String>> invisibleUserIdsController =
      StreamController<Set<String>>.broadcast();
  bool hasBlockRelationshipResult = false;

  Future<void> dispose() async {
    await invisibleUserIdsController.close();
  }

  @override
  Stream<Set<String>> watchInvisibleUserIds(String uid) {
    return invisibleUserIdsController.stream;
  }

  @override
  Future<bool> hasBlockRelationship({
    required String uid,
    required String otherUid,
  }) async {
    return hasBlockRelationshipResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
