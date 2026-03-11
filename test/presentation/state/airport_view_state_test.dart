import 'package:flutter_test/flutter_test.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';
import 'package:nook_lounge_app/presentation/state/airport_view_state.dart';

void main() {
  group('AirportViewState', () {
    test('거래 손님 목록은 같은 거래의 중복 요청을 한 건만 노출한다', () {
      final baseTime = DateTime(2026, 3, 11, 9);
      final state = AirportViewState(
        incomingRequests: <AirportVisitRequest>[
          _buildTradeRequest(
            id: 'trade_offer-1',
            status: AirportVisitRequestStatus.pending,
            updatedAt: baseTime.subtract(const Duration(minutes: 3)),
          ),
          _buildTradeRequest(
            id: 'request-invited',
            sourceOfferId: 'offer-1',
            status: AirportVisitRequestStatus.invited,
            updatedAt: baseTime.subtract(const Duration(minutes: 2)),
          ),
          _buildTradeRequest(
            id: 'request-arrived',
            sourceOfferId: 'offer-1',
            status: AirportVisitRequestStatus.arrived,
            updatedAt: baseTime.subtract(const Duration(minutes: 1)),
          ),
          _buildTradeRequest(
            id: 'request-other',
            sourceOfferId: 'offer-2',
            status: AirportVisitRequestStatus.invited,
            updatedAt: baseTime,
          ),
          _buildTradeRequest(
            id: 'request-cancelled',
            sourceOfferId: 'offer-3',
            status: AirportVisitRequestStatus.cancelled,
            updatedAt: baseTime.add(const Duration(minutes: 1)),
          ),
        ],
      );

      expect(
        state.waitingGuests.map((request) => request.id).toList(),
        <String>['request-other', 'request-arrived'],
      );
    });

    test('내 방문 현황은 레거시 거래 요청까지 묶고 취소 요청은 제외한다', () {
      final baseTime = DateTime(2026, 3, 11, 10);
      final state = AirportViewState(
        myRequests: <AirportVisitRequest>[
          _buildTradeRequest(
            id: 'trade_offer-legacy',
            status: AirportVisitRequestStatus.pending,
            updatedAt: baseTime.subtract(const Duration(minutes: 5)),
          ),
          _buildTradeRequest(
            id: 'request-current',
            sourceOfferId: 'offer-legacy',
            status: AirportVisitRequestStatus.invited,
            updatedAt: baseTime,
          ),
          _buildTradeRequest(
            id: 'request-cancelled',
            sourceOfferId: 'offer-cancelled',
            status: AirportVisitRequestStatus.cancelled,
            updatedAt: baseTime.add(const Duration(minutes: 1)),
          ),
          _buildRequest(
            id: 'regular-request',
            sourceType: null,
            sourceOfferId: null,
            status: AirportVisitRequestStatus.pending,
            updatedAt: baseTime.subtract(const Duration(minutes: 1)),
          ),
        ],
      );

      expect(state.myActiveRequests, hasLength(2));
      expect(
        state.myActiveRequests.map((request) => request.id),
        containsAll(<String>['request-current', 'regular-request']),
      );
    });
  });
}

AirportVisitRequest _buildTradeRequest({
  required String id,
  required AirportVisitRequestStatus status,
  required DateTime updatedAt,
  String? sourceOfferId,
}) {
  return _buildRequest(
    id: id,
    sourceType: 'market_trade',
    sourceOfferId: sourceOfferId,
    status: status,
    updatedAt: updatedAt,
  );
}

AirportVisitRequest _buildRequest({
  required String id,
  required AirportVisitRequestStatus status,
  required DateTime updatedAt,
  required String? sourceType,
  required String? sourceOfferId,
}) {
  return AirportVisitRequest(
    id: id,
    islandId: 'island-1',
    hostUid: 'host-1',
    hostName: 'host',
    hostIslandName: 'host island',
    hostIslandImageUrl: '',
    requesterUid: 'guest-1',
    requesterName: 'guest',
    requesterAvatarUrl: '',
    requesterIslandName: 'guest island',
    requesterIslandImageUrl: '',
    message: 'message',
    purpose: AirportVisitPurpose.touching,
    status: status,
    requestedAt: updatedAt.subtract(const Duration(minutes: 10)),
    updatedAt: updatedAt,
    sourceType: sourceType,
    sourceOfferId: sourceOfferId,
  );
}
