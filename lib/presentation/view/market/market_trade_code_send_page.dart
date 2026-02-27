import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/domain/model/market_trade_code_session.dart';
import 'package:nook_lounge_app/presentation/view/market/market_trade_code_view_page.dart';
import 'package:nook_lounge_app/di/app_providers.dart';

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
  String _seedCode = '';
  bool _hasUserEditedCode = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.session.hasCode
        ? widget.session.code
        : _generateFiveDigits();
    _seedCode = initial.trim().toUpperCase();
    _codeController = TextEditingController(text: initial);
    _codeController.addListener(() {
      final normalized = _codeController.text.trim().toUpperCase();
      if (normalized != _seedCode) {
        _hasUserEditedCode = true;
      }
    });
    unawaited(_hydrateCodeFromAirportIfAvailable());
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.read(marketViewModelProvider.notifier);
    final currentUid = viewModel.currentUserId;
    final bool isSender = widget.session.isCodeSender(currentUid);

    return Scaffold(
      appBar: AppBar(title: const Text('도도 코드 보내기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.s10,
          AppSpacing.pageHorizontal,
          110,
        ),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('거래 제목', style: AppTextStyles.captionMuted),
                const SizedBox(height: 4),
                Text(widget.offer.title, style: AppTextStyles.bodyPrimaryHeavy),
                const SizedBox(height: 10),
                Text(
                  '거래 이동 방식: ${widget.offer.moveType.label}',
                  style: AppTextStyles.captionSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  _receiverGuideLabel(isSender: isSender),
                  style: AppTextStyles.captionWithColor(
                    AppColors.badgeBlueText,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '비행장에 미리 등록된 도도 코드가 있으면 해당 코드가 우선 전송돼요.',
            style: AppTextStyles.captionMuted,
          ),
          const SizedBox(height: 16),
          Text('도도 코드', style: AppTextStyles.bodyPrimaryHeavy),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: TextField(
              controller: _codeController,
              keyboardType: TextInputType.visiblePassword,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(5),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final upper = newValue.text.toUpperCase();
                  return newValue.copyWith(
                    text: upper,
                    selection: TextSelection.collapsed(offset: upper.length),
                    composing: TextRange.empty,
                  );
                }),
              ],
              style: AppTextStyles.bodyWithSize(
                28,
                color: AppColors.textPrimary,
                weight: FontWeight.w800,
                letterSpacing: 6,
              ),
              textAlign: TextAlign.center,
              cursorColor: AppColors.accentDeepOrange,
              decoration: const InputDecoration(
                hintText: 'AB12C',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                final generated = _generateFiveDigits();
                _hasUserEditedCode = true;
                _seedCode = generated;
                _codeController.text = generated;
              },
              child: Text(
                '새 코드 생성',
                style: AppTextStyles.captionWithColor(
                  AppColors.badgeBlueText,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (!isSender)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '현재 계정은 코드 발송 대상이 아니에요. 코드 확인 화면으로 이동해 주세요.',
                style: AppTextStyles.captionWithColor(
                  AppColors.badgeRedText,
                  weight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            10,
            AppSpacing.pageHorizontal,
            12,
          ),
          child: FilledButton(
            onPressed: (!isSender || _isSending)
                ? null
                : () => _sendCode(context, ref),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              backgroundColor: AppColors.accentDeepOrange,
              disabledBackgroundColor: AppColors.catalogChipBg,
            ),
            child: Text(
              _isSending ? '코드 전송 중...' : '코드 보내기',
              style: AppTextStyles.buttonPrimary,
            ),
          ),
        ),
      ),
    );
  }

  String _receiverGuideLabel({required bool isSender}) {
    final target = widget.session.codeReceiverUid == widget.offer.ownerUid
        ? '판매자'
        : '구매자';
    if (isSender) {
      return '$target에게 5자리 코드를 보낼 수 있어요.';
    }
    return '$target이 코드를 보내면 확인할 수 있어요.';
  }

  Future<void> _sendCode(BuildContext context, WidgetRef ref) async {
    final code = _codeController.text.trim();
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

    setState(() => _isSending = true);
    try {
      await ref
          .read(marketViewModelProvider.notifier)
          .sendTradeCode(
            offer: widget.offer,
            receiverUid: widget.session.codeReceiverUid,
            code: code,
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
      MaterialPageRoute<void>(
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

    final current = _codeController.text.trim().toUpperCase();
    if (current.isNotEmpty && current != _seedCode) {
      return;
    }

    _seedCode = normalizedPreset;
    _codeController.value = _codeController.value.copyWith(
      text: normalizedPreset,
      selection: TextSelection.collapsed(offset: normalizedPreset.length),
      composing: TextRange.empty,
    );
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
