import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/core/telemetry/app_page_route.dart';
import 'package:nook_lounge_app/core/telemetry/app_screen_names.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/airport_session.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/presentation/view/airport/airport_dodo_code_input_sheet.dart';
import 'package:nook_lounge_app/presentation/view/common/home_style_app_bar_title.dart';
import 'package:nook_lounge_app/presentation/view/market/market_offer_card.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_code_view_page.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_rules_edit_sheet.dart';

class MarketTradeCodeSendPage extends ConsumerStatefulWidget {
  const MarketTradeCodeSendPage({
    required this.offer,
    required this.session,
    super.key,
  });

  final MarketOffer offer;
  final MarketTradeCodeSession session;

  @override
  ConsumerState<MarketTradeCodeSendPage> createState() =>
      _MarketTradeCodeSendPageState();
}

class _MarketTradeCodeSendPageState
    extends ConsumerState<MarketTradeCodeSendPage> {
  static final RegExp _dodoCodePattern = RegExp(
    r'^(?=.*[A-Z])(?=.*\d)[A-Z\d]{5}$',
  );

  late final TextEditingController _codeController;
  late final TextEditingController _rulesController;
  String _seedCode = '';
  String _seedRules = '';
  bool _hasUserEditedCode = false;
  bool _hasUserEditedRules = false;
  bool _isSending = false;

  String get _normalizedCode => _codeController.text.trim().toUpperCase();
  String get _normalizedRules => _rulesController.text.trim();

  @override
  void initState() {
    super.initState();
    final initialCode = widget.session.hasCode
        ? widget.session.code
        : _generateFiveDigits();
    _seedCode = initialCode.trim().toUpperCase();
    _codeController = TextEditingController(text: _seedCode);

    final initialRules = widget.session.normalizedSenderIslandRules.isNotEmpty
        ? widget.session.normalizedSenderIslandRules
        : AirportSession.defaultRules;
    _seedRules = initialRules;
    _rulesController = TextEditingController(text: initialRules);

    unawaited(_hydrateCodeFromAirportIfAvailable());
    unawaited(_hydrateRulesFromAirportIfAvailable());
  }

  @override
  void dispose() {
    _codeController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.read(marketViewModelProvider.notifier);
    final currentUid = viewModel.currentUserId;
    final isSender = widget.session.isCodeSender(currentUid);
    final canEdit = isSender && !_isSending;
    final canSend =
        canEdit &&
        _dodoCodePattern.hasMatch(_normalizedCode) &&
        _normalizedRules.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const HomeStyleAppBarTitle('도도 코드 보내기'),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.s12,
            AppSpacing.pageHorizontal,
            AppSpacing.s24,
          ),
          children: <Widget>[
            Center(
              child: _buildStatusPill(
                label: _statusLabel(isSender: isSender),
                dotColor: _statusDotColor(isSender: isSender),
              ),
            ),
            const SizedBox(height: AppSpacing.s22),
            Text(
              _headlineText(isSender: isSender),
              textAlign: TextAlign.center,
              style: AppTextStyles.dialogTitleWithSize(24),
            ),
            const SizedBox(height: AppSpacing.s20),
            Text(
              _headlineCaption(isSender: isSender),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondaryStrong.copyWith(fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.s20),
            Center(
              child: Image.asset(
                'assets/images/code_airplane.png',
                width: min(MediaQuery.sizeOf(context).width * 0.52, 220),
                fit: BoxFit.contain,
                semanticLabel: '도도 코드 전송 준비 비행기 일러스트',
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            _buildTradeSummary(),
            const SizedBox(height: AppSpacing.s24),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildSectionTitle('도도 코드'),
            ),
            const SizedBox(height: AppSpacing.s10),
            _buildCodeCard(context: context, canEdit: canEdit),
            const SizedBox(height: AppSpacing.s10),
            // Text(
            //   '비행장에 미리 등록된 도도 코드가 있으면 자동으로 먼저 불러와요.',
            //   textAlign: TextAlign.center,
            //   style: AppTextStyles.captionMuted,
            // ),
            const SizedBox(height: AppSpacing.s20),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildSectionTitle('섬 방문 규칙'),
            ),
            const SizedBox(height: AppSpacing.s10),
            _buildRulesCard(context: context, canEdit: canEdit),
            const SizedBox(height: AppSpacing.s10),
            Text(
              '상대는 규칙을 읽고 동의한 뒤 코드를 확인할 수 있어요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.captionWithColor(
                AppColors.badgeBlueText,
                weight: FontWeight.w800,
              ),
            ),
            if (!isSender) ...<Widget>[
              const SizedBox(height: AppSpacing.s12),
              Text(
                '현재 계정은 코드 발송 대상이 아니에요. 코드 확인 화면으로 이동해 주세요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.captionWithColor(
                  AppColors.badgeRedText,
                  weight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s24),
            DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: canSend ? () => _sendCode(context, ref) : null,
                style: FilledButton.styleFrom(
                  overlayColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: AppColors.modalPrimaryAction,
                  disabledBackgroundColor: AppColors.catalogChipBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  _isSending ? '코드 전송 중...' : '코드 보내기',
                  style: AppTextStyles.buttonPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: OutlinedButton(
                onPressed: _isSending
                    ? null
                    : () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  overlayColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.white,
                  side: const BorderSide(
                    color: AppColors.borderDefault,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text('나중에 보낼게요', style: AppTextStyles.buttonSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: AppTextStyles.headingH3,
    );
  }

  Widget _buildStatusPill({required String label, required Color dotColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(label, style: AppTextStyles.captionSecondary),
        ],
      ),
    );
  }

  Widget _buildTradeSummary() {
    return IgnorePointer(
      child: MarketOfferCard(
        offer: widget.offer,
        showActionArea: false,
        onTap: () {},
        onActionTap: () {},
      ),
    );
  }

  Widget _buildCodeCard({
    required BuildContext context,
    required bool canEdit,
  }) {
    final displayedCode = _normalizedCode.isEmpty ? '-----' : _normalizedCode;
    final helperText = canEdit
        ? '카드를 눌러 코드를 수정할 수 있어요.'
        : '전송 권한이 있는 사용자만 코드를 수정할 수 있어요.';

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: canEdit ? () => _openCodeSheet(context) : null,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s18,
            AppSpacing.s22,
            AppSpacing.s18,
            AppSpacing.s18,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              Text(
                displayedCode,
                style: _normalizedCode.isEmpty
                    ? AppTextStyles.bodyWithSize(
                        32,
                        color: AppColors.textMuted,
                        weight: FontWeight.w800,
                        letterSpacing: 6,
                      )
                    : AppTextStyles.marketCodeDisplay,
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                helperText,
                textAlign: TextAlign.center,
                style: AppTextStyles.captionSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRulesCard({
    required BuildContext context,
    required bool canEdit,
  }) {
    final rulesPreview = _normalizedRules.isEmpty
        ? '아직 섬 방문 규칙이 없어요.\n카드를 눌러 먼저 규칙을 입력해 주세요.'
        : _normalizedRules;
    final helperText = canEdit
        ? '카드를 눌러 방문 규칙을 수정할 수 있어요.'
        : '전송 권한이 있는 사용자만 방문 규칙을 수정할 수 있어요.';

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: canEdit ? () => _openRulesSheet(context) : null,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s18),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.borderDefault),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: Text(
                  rulesPreview,
                  style: _normalizedRules.isEmpty
                      ? AppTextStyles.bodyHintStrong
                      : AppTextStyles.bodySecondaryStrong.copyWith(
                    height: 1.5
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                helperText,
                textAlign: TextAlign.center,
                style: AppTextStyles.captionSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel({required bool isSender}) {
    if (_isSending) {
      return '코드 전송 중';
    }
    if (!isSender) {
      return '코드 확인 대기';
    }
    if (_normalizedRules.isEmpty) {
      return '코드 발송 준비 중';
    }
    return '코드 발송 준비 완료';
  }

  Color _statusDotColor({required bool isSender}) {
    if (_isSending) {
      return AppColors.accentDeepOrange;
    }
    if (!isSender) {
      return AppColors.textMuted;
    }
    if (_normalizedRules.isEmpty) {
      return AppColors.badgeRedText;
    }
    return AppColors.modalPrimaryAction;
  }

  String _headlineText({required bool isSender}) {
    return isSender ? '비행기 띄울 준비 해주세요!' : '코드가 도착하길 기다려주세요!';
  }

  String _headlineCaption({required bool isSender}) {
    return isSender
        ? '상대가 바로 확인할 수 있게 도도 코드와 방문 규칙을 정리해 주세요.'
        : '코드 발송자가 준비를 마치면 확인 화면에서 바로 볼 수 있어요.';
  }

  Future<void> _openCodeSheet(BuildContext context) async {
    final nextCode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: AirportDodoCodeInputSheet(initialCode: _normalizedCode),
          ),
        );
      },
    );

    if (!mounted || nextCode == null) {
      return;
    }

    _hasUserEditedCode = true;
    _seedCode = nextCode;
    _codeController.text = nextCode;
    setState(() {});
  }

  Future<void> _openRulesSheet(BuildContext context) async {
    final nextRules = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: MarketTradeRulesEditSheet(initialRules: _normalizedRules),
          ),
        );
      },
    );

    if (!mounted || nextRules == null) {
      return;
    }

    _hasUserEditedRules = true;
    _seedRules = nextRules;
    _rulesController.text = nextRules;
    setState(() {});
  }

  Future<void> _sendCode(BuildContext context, WidgetRef ref) async {
    final code = _normalizedCode;
    final rules = _normalizedRules;
    if (!_dodoCodePattern.hasMatch(code)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('코드는 영문 대문자+숫자 조합 5자리로 입력해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    if (rules.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('섬 규칙을 한 줄 이상 입력해 주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref
          .read(marketViewModelProvider.notifier)
          .sendTradeCode(
            offer: widget.offer,
            receiverUid: widget.session.codeReceiverUid,
            code: code,
            islandRules: rules,
          );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = _resolveSendCodeErrorMessage(error);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      setState(() => _isSending = false);
      return;
    }

    if (!context.mounted) {
      return;
    }
    setState(() => _isSending = false);
    await Navigator.of(context).pushReplacement(
      AppPageRoute<void>(
        screenName: AppScreenNames.marketTradeCodeView,
        builder: (_) => MarketTradeCodeViewPage(offer: widget.offer),
      ),
    );
  }

  String _resolveSendCodeErrorMessage(Object error) {
    if (error is StateError) {
      switch (error.message) {
        case 'invalid_trade_code_format':
          return '코드는 영문 대문자+숫자 조합 5자리로 입력해 주세요.';
        case 'invalid_code_receiver':
          return '코드 수신 대상을 찾지 못했어요. 다시 시도해 주세요.';
        case 'invalid_trade_code_payload':
          return '코드 전송 정보가 올바르지 않아요. 다시 시도해 주세요.';
        case 'invalid_trade_rules':
          return '섬 규칙을 한 줄 이상 입력해 주세요.';
      }
    }
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return '코드 전송 권한이 없어요. 다시 로그인 후 시도해 주세요.';
      }
      if (error.code == 'unavailable') {
        return '네트워크가 불안정해요. 잠시 후 다시 시도해 주세요.';
      }
    }
    return '코드 전송에 실패했어요. 다시 시도해 주세요.';
  }

  Future<void> _hydrateCodeFromAirportIfAvailable() async {
    final viewModel = ref.read(marketViewModelProvider.notifier);
    final currentUid = viewModel.currentUserId.trim();
    if (!widget.session.isCodeSender(currentUid) || widget.session.hasCode) {
      return;
    }

    final preset = await viewModel.fetchPreferredTradeDodoCode(
      offerId: widget.offer.id,
    );
    final normalizedPreset = (preset ?? '').trim().toUpperCase();
    if (!mounted ||
        normalizedPreset.isEmpty ||
        !_dodoCodePattern.hasMatch(normalizedPreset) ||
        _hasUserEditedCode) {
      return;
    }

    final current = _normalizedCode;
    if (current.isNotEmpty && current != _seedCode) {
      return;
    }

    _seedCode = normalizedPreset;
    _codeController.text = normalizedPreset;
    setState(() {});
  }

  Future<void> _hydrateRulesFromAirportIfAvailable() async {
    final viewModel = ref.read(marketViewModelProvider.notifier);
    final currentUid = viewModel.currentUserId.trim();
    if (!widget.session.isCodeSender(currentUid) || widget.session.hasCode) {
      return;
    }

    final preset = await viewModel.fetchPreferredTradeIslandRules(
      offerId: widget.offer.id,
    );
    final normalizedPreset = (preset ?? '').trim();
    if (!mounted || normalizedPreset.isEmpty || _hasUserEditedRules) {
      return;
    }

    final current = _normalizedRules;
    if (current.isNotEmpty && current != _seedRules) {
      return;
    }

    _seedRules = normalizedPreset;
    _rulesController.text = normalizedPreset;
    setState(() {});
  }

  String _generateFiveDigits() {
    final random = Random();
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    const pool = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final chars = List<String>.generate(5, (_) {
      return pool[random.nextInt(pool.length)];
    });

    // 유지보수 포인트:
    // 도도 코드는 영문 대문자/숫자 혼합 규칙을 강제합니다.
    if (!chars.any((char) => digits.contains(char))) {
      chars[random.nextInt(chars.length)] =
          digits[random.nextInt(digits.length)];
    }
    if (!chars.any((char) => letters.contains(char))) {
      chars[random.nextInt(chars.length)] =
          letters[random.nextInt(letters.length)];
    }
    return chars.join();
  }
}
