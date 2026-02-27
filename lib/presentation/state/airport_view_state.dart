import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/airport_visit_request.dart';

const _airportNoValue = Object();

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
    // "다른 섬 방문 대기 현황"은 일반 방문 요청(비거래)만 노출합니다.
    // 거래 연동 요청은 waitingGuests로 분리합니다.
    final requests = incomingRequests
        .where((request) {
          return request.status == AirportVisitRequestStatus.pending &&
              !_isTradeLinked(request);
        })
        .toList(growable: false);
    requests.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return requests;
  }

  List<AirportVisitRequest> get invitedRequests {
    return incomingRequests
        .where((request) => request.status == AirportVisitRequestStatus.invited)
        .toList(growable: false);
  }

  // 유지보수 포인트:
  // 거래 연동(`sourceType == market_trade`) 요청은
  // 상태가 대기/초대/방문중(active)일 때 "내 섬에 방문 대기 중인 손님"으로 모읍니다.
  List<AirportVisitRequest> get waitingGuests {
    final guests = incomingRequests
        .where((request) {
          if (!_isTradeLinked(request)) {
            return false;
          }
          return request.status == AirportVisitRequestStatus.pending ||
              request.status == AirportVisitRequestStatus.invited ||
              request.status == AirportVisitRequestStatus.arrived;
        })
        .toList(growable: false);

    guests.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return guests;
  }

  List<AirportVisitRequest> get activeVisitors {
    final visitors = incomingRequests
        .where((request) {
          return request.status == AirportVisitRequestStatus.arrived;
        })
        .toList(growable: false);
    visitors.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return visitors;
  }

  List<AirportVisitRequest> get myActiveRequests {
    return myRequests
        .where((request) => request.isActive)
        .toList(growable: false);
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
