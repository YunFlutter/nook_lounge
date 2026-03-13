import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
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

    test('만지작 거래글은 목록에서 숨긴다', () async {
      marketRepository.hiddenOfferIdsController.add(const <String>{});
      userBlockRepository.invisibleUserIdsController.add(const <String>{});
      marketRepository.offersController.add(<MarketOffer>[
        _buildOffer(id: 'visible', ownerUid: 'visible-user'),
        _buildOffer(
          id: 'legacy-touching',
          ownerUid: 'touching-user',
          category: MarketFilterCategory.touching,
          boardType: MarketBoardType.touching,
          tradeType: MarketTradeType.touching,
        ),
      ]);

      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state.offers.map((offer) => offer.id), <String>[
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

    test('내가 제안 중인 거래는 거래 제안중 목록에 포함한다', () async {
      viewModel.ensureProposalTracking();
      marketRepository.hiddenOfferIdsController.add(const <String>{});
      userBlockRepository.invisibleUserIdsController.add(const <String>{});
      marketRepository.activeProposalOfferIdsController.add(const <String>{
        'proposal',
      });
      marketRepository.offersController.add(<MarketOffer>[
        _buildOffer(id: 'mine', ownerUid: 'me'),
        _buildOffer(id: 'proposal', ownerUid: 'other-user'),
        _buildOffer(
          id: 'completed-proposal',
          ownerUid: 'other-user',
          lifecycle: MarketLifecycleTab.completed,
        ),
        _buildOffer(id: 'other', ownerUid: 'someone-else'),
      ]);

      await Future<void>.delayed(Duration.zero);

      expect(viewModel.myOffers.map((offer) => offer.id), <String>['mine']);
      expect(viewModel.proposalOffers.map((offer) => offer.id), <String>[
        'proposal',
      ]);
    });

    test('진행중 거래 목록은 내 거래와 제안중 거래를 함께 포함한다', () async {
      viewModel.ensureProposalTracking();
      marketRepository.hiddenOfferIdsController.add(const <String>{});
      userBlockRepository.invisibleUserIdsController.add(const <String>{});
      marketRepository.activeProposalOfferIdsController.add(const <String>{
        'proposal',
      });
      marketRepository.offersController.add(<MarketOffer>[
        _buildOffer(id: 'mine', ownerUid: 'me'),
        _buildOffer(
          id: 'proposal',
          ownerUid: 'other-user',
          status: MarketOfferStatus.waiting,
        ),
        _buildOffer(
          id: 'cancelled',
          ownerUid: 'me',
          lifecycle: MarketLifecycleTab.cancelled,
        ),
      ]);

      await Future<void>.delayed(Duration.zero);

      expect(viewModel.ongoingTradeCount, 2);
      expect(
        viewModel.ongoingTradeOffers.map((offer) => offer.id).toSet(),
        <String>{'mine', 'proposal'},
      );
    });

    test('거래 제안을 보내면 제안중 목록에 즉시 반영한다', () async {
      viewModel.ensureProposalTracking();
      marketRepository.hiddenOfferIdsController.add(const <String>{});
      userBlockRepository.invisibleUserIdsController.add(const <String>{});
      marketRepository.offersController.add(<MarketOffer>[
        _buildOffer(id: 'proposal', ownerUid: 'other-user'),
      ]);

      await Future<void>.delayed(Duration.zero);

      expect(viewModel.proposalOffers, isEmpty);

      await viewModel.sendTradeProposal(
        offer: _buildOffer(id: 'proposal', ownerUid: 'other-user'),
      );

      expect(viewModel.proposalOffers.map((offer) => offer.id), <String>[
        'proposal',
      ]);
    });

    test('내 제안을 취소하면 제안중 목록에서 즉시 빠진다', () async {
      viewModel.ensureProposalTracking();
      marketRepository.hiddenOfferIdsController.add(const <String>{});
      userBlockRepository.invisibleUserIdsController.add(const <String>{});
      marketRepository.activeProposalOfferIdsController.add(const <String>{
        'proposal',
      });
      marketRepository.offersController.add(<MarketOffer>[
        _buildOffer(id: 'proposal', ownerUid: 'other-user'),
      ]);

      await Future<void>.delayed(Duration.zero);

      expect(viewModel.proposalOffers.map((offer) => offer.id), <String>[
        'proposal',
      ]);

      await viewModel.cancelTrade(
        offer: _buildOffer(id: 'proposal', ownerUid: 'other-user'),
      );

      expect(viewModel.proposalOffers, isEmpty);
    });

    test('상대방이 없어도 내 거래를 완료할 수 있다', () async {
      marketRepository.hiddenOfferIdsController.add(const <String>{});
      userBlockRepository.invisibleUserIdsController.add(const <String>{});
      marketRepository.offersController.add(<MarketOffer>[
        _buildOffer(id: 'mine', ownerUid: 'me'),
      ]);

      await Future<void>.delayed(Duration.zero);

      await viewModel.completeTrade(
        offer: _buildOffer(id: 'mine', ownerUid: 'me'),
      );

      expect(marketRepository.completeTradeCallCount, 1);
      expect(marketRepository.completedOfferId, 'mine');
      expect(marketRepository.completedRequesterUid, 'me');
      expect(
        viewModel.state.offers.single.lifecycle,
        MarketLifecycleTab.completed,
      );
      expect(viewModel.state.offers.single.status, MarketOfferStatus.closed);
      expect(viewModel.state.errorMessage, isNull);
    });

    test('상대 정보를 확인할 수 없으면 완료 실패 메시지를 갱신한다', () async {
      marketRepository.completeTradeError = StateError(
        'trade_complete_no_active_proposal',
      );
      final offer = _buildOffer(id: 'mine', ownerUid: 'me');
      marketRepository.hiddenOfferIdsController.add(const <String>{});
      userBlockRepository.invisibleUserIdsController.add(const <String>{});
      marketRepository.offersController.add(<MarketOffer>[offer]);

      await Future<void>.delayed(Duration.zero);

      await expectLater(
        () => viewModel.completeTrade(offer: offer),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'trade_complete_no_active_proposal',
          ),
        ),
      );

      expect(
        viewModel.state.offers.single.lifecycle,
        MarketLifecycleTab.ongoing,
      );
      expect(viewModel.state.offers.single.status, MarketOfferStatus.open);
      expect(viewModel.state.errorMessage, '거래 상태를 확인할 수 없어 완료할 수 없어요.');
    });

    test('같은 거래 승낙은 동시에 한 번만 처리한다', () async {
      final completer = Completer<MarketTradeCodeSession>();
      marketRepository.acceptTradeProposalCompleter = completer;
      final offer = _buildOffer(id: 'touching-offer', ownerUid: 'me');

      final firstCall = viewModel.acceptTradeProposalAsOwner(
        offer: offer,
        proposerUid: 'guest-a',
      );
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        () => viewModel.acceptTradeProposalAsOwner(
          offer: offer,
          proposerUid: 'guest-b',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'trade_accept_in_progress',
          ),
        ),
      );

      completer.complete(_buildCodeSession(offerId: offer.id));
      await firstCall;

      expect(marketRepository.acceptTradeProposalCallCount, 1);
      expect(viewModel.state.errorMessage, isNull);
    });

    test('같은 거래 코드는 동시에 한 번만 전송한다', () async {
      final completer = Completer<void>();
      marketRepository.sendTradeCodeCompleter = completer;
      final offer = _buildOffer(id: 'touching-offer', ownerUid: 'me');

      final firstCall = viewModel.sendTradeCode(
        offer: offer,
        receiverUid: 'guest-a',
        code: 'AB123',
        islandRules: '꽃은 뛰지 말아 주세요.',
      );
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        () => viewModel.sendTradeCode(
          offer: offer,
          receiverUid: 'guest-a',
          code: 'AB123',
          islandRules: '꽃은 뛰지 말아 주세요.',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'trade_code_send_in_progress',
          ),
        ),
      );

      completer.complete();
      await firstCall;

      expect(marketRepository.sendTradeCodeCallCount, 1);
      expect(viewModel.state.errorMessage, isNull);
    });
  });
}

MarketOffer _buildOffer({
  required String id,
  required String ownerUid,
  MarketLifecycleTab lifecycle = MarketLifecycleTab.ongoing,
  MarketOfferStatus status = MarketOfferStatus.open,
  MarketFilterCategory category = MarketFilterCategory.item,
  MarketBoardType boardType = MarketBoardType.exchange,
  MarketTradeType tradeType = MarketTradeType.exchange,
}) {
  final now = DateTime(2026, 3, 10, 12);
  return MarketOffer(
    id: id,
    ownerUid: ownerUid,
    category: category,
    boardType: boardType,
    lifecycle: lifecycle,
    status: status,
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
    tradeType: tradeType,
    moveType: MarketMoveType.host,
    createdAt: now,
    updatedAt: now,
  );
}

MarketTradeCodeSession _buildCodeSession({required String offerId}) {
  final now = DateTime(2026, 3, 10, 12);
  return MarketTradeCodeSession(
    offerId: offerId,
    ownerUid: 'me',
    proposerUid: 'guest-a',
    moveType: MarketMoveType.host,
    code: '',
    codeSenderUid: 'me',
    codeReceiverUid: 'guest-a',
    senderIslandRules: '',
    acceptedAt: now,
    updatedAt: now,
  );
}

class _FakeMarketRepository implements MarketRepository {
  final StreamController<List<MarketOffer>> offersController =
      StreamController<List<MarketOffer>>.broadcast();
  final StreamController<Set<String>> hiddenOfferIdsController =
      StreamController<Set<String>>.broadcast();
  final StreamController<Set<String>> activeProposalOfferIdsController =
      StreamController<Set<String>>.broadcast();
  int sendTradeProposalCallCount = 0;
  int completeTradeCallCount = 0;
  int acceptTradeProposalCallCount = 0;
  int sendTradeCodeCallCount = 0;
  Object? completeTradeError;
  String? completedOfferId;
  String? completedRequesterUid;
  String? completedOfferTitle;
  Completer<MarketTradeCodeSession>? acceptTradeProposalCompleter;
  Completer<void>? sendTradeCodeCompleter;

  Future<void> dispose() async {
    await offersController.close();
    await hiddenOfferIdsController.close();
    await activeProposalOfferIdsController.close();
  }

  @override
  Stream<List<MarketOffer>> watchOffers() => offersController.stream;

  @override
  Stream<Set<String>> watchHiddenOfferIds(String uid) {
    return hiddenOfferIdsController.stream;
  }

  @override
  Stream<Set<String>> watchMyActiveProposalOfferIds(String proposerUid) {
    return activeProposalOfferIdsController.stream;
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
  Future<void> cancelTrade({
    required String offerId,
    required String ownerUid,
    required String requesterUid,
    required String offerTitle,
  }) async {}

  @override
  Future<void> completeTrade({
    required String offerId,
    required String requesterUid,
    required String offerTitle,
  }) async {
    completeTradeCallCount += 1;
    completedOfferId = offerId;
    completedRequesterUid = requesterUid;
    completedOfferTitle = offerTitle;
    final error = completeTradeError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<MarketTradeCodeSession> acceptTradeProposal({
    required String offerId,
    required String ownerUid,
    required String proposerUid,
    required MarketMoveType moveType,
    required String offerTitle,
  }) async {
    acceptTradeProposalCallCount += 1;
    final completer = acceptTradeProposalCompleter;
    if (completer != null) {
      return completer.future;
    }
    return _buildCodeSession(offerId: offerId);
  }

  @override
  Future<void> sendTradeCode({
    required String offerId,
    required String senderUid,
    required String receiverUid,
    required String code,
    required String islandRules,
    required String offerTitle,
  }) async {
    sendTradeCodeCallCount += 1;
    final completer = sendTradeCodeCompleter;
    if (completer != null) {
      await completer.future;
    }
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
