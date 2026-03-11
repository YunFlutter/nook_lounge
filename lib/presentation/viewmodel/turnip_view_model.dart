import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry.dart';
import 'package:nook_lounge_app/core/telemetry/app_telemetry_events.dart';
import 'package:nook_lounge_app/domain/model/turnip_saved_data.dart';
import 'package:nook_lounge_app/domain/repository/turnip_repository.dart';
import 'package:nook_lounge_app/presentation/state/turnip_view_state.dart';

class TurnipViewModel extends StateNotifier<TurnipViewState> {
  TurnipViewModel({
    required TurnipRepository repository,
    required AppTelemetry telemetry,
    required String uid,
    required String islandId,
  }) : _repository = repository,
       _telemetry = telemetry,
       _uid = uid,
       _islandId = islandId,
       super(const TurnipViewState()) {
    if (islandId.isEmpty) {
      return;
    }
    unawaited(_loadSavedStateOnce());
  }

  final TurnipRepository _repository;
  final AppTelemetry _telemetry;
  final String _uid;
  final String _islandId;
  Timer? _saveDebounce;

  void reset() {
    state = const TurnipViewState();
    _scheduleSave(immediate: true);
    unawaited(_telemetry.logEvent(AppTelemetryEvents.turnipReset));
  }

  void setSundayBuyPrice(int value) {
    state = state.copyWith(
      sundayBuyPrice: _sanitize(value),
      errorMessage: null,
      prediction: null,
    );
    _scheduleSave();
  }

  void adjustSundayBuyPrice(int delta) {
    setSundayBuyPrice(state.sundayBuyPrice + delta);
  }

  void setActiveDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex > 5) {
      return;
    }
    if (state.activeDayIndex == dayIndex) {
      return;
    }
    state = state.copyWith(activeDayIndex: dayIndex);
  }

  void clearActiveDay(int dayIndex) {
    if (state.activeDayIndex != dayIndex) {
      return;
    }
    state = state.copyWith(activeDayIndex: -1);
  }

  void setWeekSlotPrice({required int index, required int? value}) {
    if (index < 0 || index >= state.weekSlots.length) {
      return;
    }

    final updated = List<int?>.from(state.weekSlots);
    updated[index] = value == null ? null : _sanitize(value);

    state = state.copyWith(
      weekSlots: updated,
      errorMessage: null,
      prediction: null,
    );
    _scheduleSave();
  }

  void adjustWeekSlotPrice({required int index, required int delta}) {
    if (index < 0 || index >= state.weekSlots.length) {
      return;
    }
    final current = state.weekSlots[index] ?? 0;
    setWeekSlotPrice(index: index, value: current + delta);
  }

  Future<void> calculate() async {
    final filter = state.buildFilter();
    if (filter.length < 3) {
      state = state.copyWith(errorMessage: '일요일 매수가와 월요일 오전/오후 가격을 먼저 입력해주세요.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final prediction = await _repository.predict(filter: filter);
      state = state.copyWith(
        isLoading: false,
        prediction: prediction,
        errorMessage: null,
      );
      _scheduleSave(immediate: true);
      unawaited(
        _telemetry.logEvent(
          AppTelemetryEvents.turnipCalculated,
          parameters: <String, Object>{
            'input_count': filter.length,
            'result_count': prediction.minMaxPattern.length,
          },
        ),
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '요청 시간이 초과되었어요. 잠시 후 다시 시도해주세요.',
      );
      unawaited(
        _telemetry.recordError(
          TimeoutException('turnip prediction timed out'),
          StackTrace.current,
          reason: 'turnip.calculate.timeout',
        ),
      );
    } on SocketException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '네트워크에 연결할 수 없어요. 인터넷 상태를 확인해주세요.',
      );
      unawaited(
        _telemetry.recordError(
          const SocketException('turnip prediction network error'),
          StackTrace.current,
          reason: 'turnip.calculate.socket',
        ),
      );
    } on HttpException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '서버 응답 오류가 발생했어요. (${error.message})',
      );
      unawaited(
        _telemetry.recordError(
          error,
          StackTrace.current,
          reason: 'turnip.calculate.http',
        ),
      );
    } on FormatException {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '예측 데이터 형식을 해석하지 못했어요. 잠시 후 다시 시도해주세요.',
      );
      unawaited(
        _telemetry.recordError(
          const FormatException('turnip prediction parse error'),
          StackTrace.current,
          reason: 'turnip.calculate.format',
        ),
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '예측 계산 중 알 수 없는 오류가 발생했어요. 다시 시도해주세요.',
      );
      unawaited(
        _telemetry.recordError(
          error,
          stackTrace,
          reason: 'turnip.calculate.unknown',
        ),
      );
    }
  }

  int _sanitize(int value) {
    if (value < 0) {
      return 0;
    }
    if (value > 9999) {
      return 9999;
    }
    return value;
  }

  Future<void> _loadSavedStateOnce() async {
    try {
      // 유지보수 포인트:
      // 무주식 계산은 로컬 입력값 기준으로 동작해야 하므로, Firestore는 앱 진입 시 1회 로드에만 사용합니다.
      final saved = await _repository
          .watchSavedState(uid: _uid, islandId: _islandId)
          .first
          .timeout(const Duration(seconds: 5));
      if (!mounted) {
        return;
      }
      _applySavedState(saved);
    } on TimeoutException {
      // 저장 데이터 첫 로드 타임아웃은 입력 기반 사용을 허용하기 위해 무시합니다.
    } catch (_) {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        errorMessage: '저장된 무주식 데이터를 불러오지 못했어요. 입력값으로 바로 계산할 수 있어요.',
      );
    }
  }

  void _applySavedState(TurnipSavedData? saved) {
    if (saved == null) {
      return;
    }

    state = state.copyWith(
      sundayBuyPrice: _sanitize(saved.sundayBuyPrice),
      weekSlots: List<int?>.from(saved.weekSlots),
      prediction: saved.prediction,
      errorMessage: null,
      activeDayIndex: -1,
    );
  }

  void _scheduleSave({bool immediate = false}) {
    if (_uid.isEmpty || _islandId.isEmpty) {
      return;
    }

    _saveDebounce?.cancel();
    if (immediate) {
      unawaited(_saveStateSilently());
      return;
    }

    _saveDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_saveStateSilently());
    });
  }

  Future<void> _saveStateSilently() async {
    final snapshot = TurnipSavedData(
      sundayBuyPrice: state.sundayBuyPrice,
      weekSlots: List<int?>.from(state.weekSlots),
      prediction: state.prediction,
    );

    try {
      await _repository.saveState(
        uid: _uid,
        islandId: _islandId,
        data: snapshot,
      );
    } catch (_) {
      // 유지보수 포인트:
      // 저장 실패는 계산 흐름을 막지 않고 다음 입력/계산에서 재시도합니다.
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    if (_uid.isNotEmpty && _islandId.isNotEmpty) {
      unawaited(_saveStateSilently());
    }
    super.dispose();
  }
}
