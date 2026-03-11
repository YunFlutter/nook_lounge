import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';

const _airportNoValue = Object();
const _tradeRequestIdPrefix = 'trade_';

class AirportViewState {
  const AirportViewState({
    this.isInitializing = true,
    this.isSubmitting = false,
    this.session,
    this.incomingRequests = const <AirportVisitRequest>[],
    this.myRequests = const <AirportVisitRequest>[],
    this.openSessions = const <AirportSession>[],
    this.selectedRequestIds = const <String>{},
    this.errorMessage,
    this.infoMessage,
  });

  final bool isInitializing;
  final bool isSubmitting;
  final AirportSession? session;
  final List<AirportVisitRequest> incomingRequests;
  final List<AirportVisitRequest> myRequests;
  final List<AirportSession> openSessions;
  final Set<String> selectedRequestIds;
  final String? errorMessage;
  final String? infoMessage;

  List<AirportVisitRequest> get pendingRequests {
    // 유지보수 포인트:
    // 줄서기/거래 연동 여부와 무관하게 "아직 승낙 전" 요청은
    // 모두 동일한 대기열로 취급하되, 동일 손님의 최신 활성 상태가
    // 초대 완료/방문 중이면 pending에서 빠져야 UI가 중복되지 않습니다.
    final requests = _resolvedIncomingActiveRequests
        .where((request) => request.status == AirportVisitRequestStatus.pending)
        .toList(growable: false);
    requests.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return requests;
  }

  List<AirportVisitRequest> get invitedRequests {
    final requests = _resolvedIncomingActiveRequests
        .where((request) => request.status == AirportVisitRequestStatus.invited)
        .toList(growable: false);
    requests.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return requests;
  }

  // 유지보수 포인트:
  // "내 섬에 방문 대기 중인 손님"은 아직 입장 전(pending/invited) 손님만 보여줍니다.
  // 동일 거래에 arrived 상태가 생기면 이 목록에서는 빠지고 방문객 명단으로만 이동해야 합니다.
  List<AirportVisitRequest> get waitingGuests {
    final guests = _resolvedIncomingActiveRequests
        .where((request) {
          return request.status == AirportVisitRequestStatus.pending ||
              request.status == AirportVisitRequestStatus.invited;
        })
        .toList(growable: false);
    guests.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return guests;
  }

  List<AirportVisitRequest> get activeVisitors {
    final visitors = _resolvedIncomingActiveRequests
        .where((request) => request.status == AirportVisitRequestStatus.arrived)
        .toList(growable: false);
    visitors.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return visitors;
  }

  List<AirportVisitRequest> get approvedRequests {
    final requests = _resolvedIncomingActiveRequests
        .where((request) {
          return request.status == AirportVisitRequestStatus.invited ||
              request.status == AirportVisitRequestStatus.arrived;
        })
        .toList(growable: false);
    requests.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return requests;
  }

  List<AirportVisitRequest> get myActiveRequests {
    return _dedupeRequests(
      myRequests.where((request) => request.isActive),
    ).toList(growable: false);
  }

  Iterable<AirportVisitRequest> _dedupeRequests(
    Iterable<AirportVisitRequest> requests,
  ) {
    final requestsByKey = <String, AirportVisitRequest>{};
    for (final request in requests) {
      final key = _requestKey(request);
      final existing = requestsByKey[key];
      if (existing == null || _shouldReplaceRequest(existing, request)) {
        requestsByKey[key] = request;
      }
    }
    return requestsByKey.values;
  }

  Iterable<AirportVisitRequest> get _resolvedIncomingActiveRequests {
    return _dedupeRequests(
      incomingRequests.where((request) {
        return request.status == AirportVisitRequestStatus.pending ||
            request.status == AirportVisitRequestStatus.invited ||
            request.status == AirportVisitRequestStatus.arrived;
      }),
    );
  }

  String _requestKey(AirportVisitRequest request) {
    if (!_isTradeLinked(request)) {
      return request.id;
    }
    final sourceOfferId = request.sourceOfferId?.trim() ?? '';
    final requesterUid = request.requesterUid.trim();
    if (sourceOfferId.isNotEmpty) {
      return requesterUid.isEmpty
          ? 'trade:$sourceOfferId'
          : 'trade:$sourceOfferId:$requesterUid';
    }
    final requestId = request.id.trim();
    if (requestId.startsWith(_tradeRequestIdPrefix)) {
      final legacyKey = requestId.substring(_tradeRequestIdPrefix.length);
      return requesterUid.isEmpty
          ? 'trade:$legacyKey'
          : 'trade:$legacyKey:$requesterUid';
    }
    return requestId;
  }

  bool _shouldReplaceRequest(
    AirportVisitRequest current,
    AirportVisitRequest next,
  ) {
    final currentRank = _requestStatusRank(current.status);
    final nextRank = _requestStatusRank(next.status);
    if (nextRank != currentRank) {
      return nextRank < currentRank;
    }
    return next.updatedAt.isAfter(current.updatedAt);
  }

  int _requestStatusRank(AirportVisitRequestStatus status) {
    switch (status) {
      case AirportVisitRequestStatus.arrived:
        return 0;
      case AirportVisitRequestStatus.invited:
        return 1;
      case AirportVisitRequestStatus.pending:
        return 2;
      case AirportVisitRequestStatus.cancelled:
        return 3;
      case AirportVisitRequestStatus.completed:
        return 4;
    }
  }

  AirportViewState copyWith({
    bool? isInitializing,
    bool? isSubmitting,
    Object? session = _airportNoValue,
    List<AirportVisitRequest>? incomingRequests,
    List<AirportVisitRequest>? myRequests,
    List<AirportSession>? openSessions,
    Set<String>? selectedRequestIds,
    Object? errorMessage = _airportNoValue,
    Object? infoMessage = _airportNoValue,
  }) {
    return AirportViewState(
      isInitializing: isInitializing ?? this.isInitializing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      session: session == _airportNoValue
          ? this.session
          : session as AirportSession?,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      myRequests: myRequests ?? this.myRequests,
      openSessions: openSessions ?? this.openSessions,
      selectedRequestIds: selectedRequestIds ?? this.selectedRequestIds,
      errorMessage: errorMessage == _airportNoValue
          ? this.errorMessage
          : errorMessage as String?,
      infoMessage: infoMessage == _airportNoValue
          ? this.infoMessage
          : infoMessage as String?,
    );
  }

  bool _isTradeLinked(AirportVisitRequest request) {
    return request.sourceType == 'market_trade';
  }
}
