import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/presentation/view/market/market_item_picker_sheet.dart';

class MarketTradeRegisterPage extends ConsumerStatefulWidget {
  const MarketTradeRegisterPage({super.key});

  @override
  ConsumerState<MarketTradeRegisterPage> createState() =>
      _MarketTradeRegisterPageState();
}

class _MarketTradeRegisterPageState
    extends ConsumerState<MarketTradeRegisterPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  int _step = 0;
  MarketTradeType _tradeType = MarketTradeType.sharing;
  MarketMoveType _moveType = MarketMoveType.visitor;
  CatalogItem? _offeredItem;
  CatalogItem? _wantedItem;
  int _offerQuantity = 1;
  int _wantQuantity = 1;
  bool _useOfferCurrency = false;
  bool _useCurrency = false;
  bool _isSubmitting = false;
  String _offerCurrencyLabel = '벨(덩)';
  int _offerCurrencyAmount = 1;
  String _currencyLabel = '벨(덩)';
  int _currencyAmount = 1;
  String _offerStyle = '기본';
  String _wantStyle = '기본';
  String _proofImagePath = '';

  bool get _isVillagerOffer => _offeredItem?.category == '주민';

  List<MarketTradeType> get _availableTradeTypes =>
      _availableTradeTypesForCategory(
        _useOfferCurrency ? '재화' : _offeredItem?.category,
      );

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('거래를 등록하기')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.s10,
                AppSpacing.pageHorizontal,
                AppSpacing.s10,
              ),
              children: <Widget>[
                _buildStepIndicator(),
                const SizedBox(height: 16),
                if (_step == 0) _buildStepOne(),
                if (_step == 1) _buildStepTwo(),
                if (_step == 2) _buildStepThree(),
                if (_step == 3) _buildStepFour(),
              ],
            ),
          ),
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final hasPrevious = _step > 0;

    final VoidCallback? onPrimaryPressed = switch (_step) {
      0 =>
        (_useOfferCurrency || _offeredItem != null)
            ? () => setState(() => _step = 1)
            : null,
      1 => () => setState(() => _step = 2),
      2 => _canMoveFromStepThree() ? () => setState(() => _step = 3) : null,
      3 => _isSubmitting ? null : _submit,
      _ => null,
    };

    final String primaryLabel = switch (_step) {
      3 => _isSubmitting ? '등록중...' : '거래를 등록하기',
      _ => '다음 단계로 ->',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.s10,
        AppSpacing.pageHorizontal,
        AppSpacing.s10,
      ),
      child: SafeArea(
        top: false,
        child: hasPrevious
            ? Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step = _step - 1),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _buildBottomButtonLabel('이전'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onPrimaryPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentDeepOrange,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _buildBottomButtonLabel(primaryLabel),
                    ),
                  ),
                ],
              )
            : FilledButton(
                onPressed: onPrimaryPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentDeepOrange,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _buildBottomButtonLabel(primaryLabel),
              ),
      ),
    );
  }

  Widget _buildBottomButtonLabel(String text) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(4, (index) {
        final selected = index == _step;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: selected ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentDeepOrange
                : AppColors.borderDefault,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }

  Widget _buildStepOne() {
    final isVillager = _isVillagerOffer;
    final showTitleInStepOne = !_useOfferCurrency;
    final showExtraItemFields = !_useOfferCurrency && !isVillager;
    final showDetailSection = showTitleInStepOne || showExtraItemFields;
    final titleText = isVillager ? '어떤 주민을 거래하시겠어요?' : '무엇을 거래하시겠어요?';
    final guideText = _useOfferCurrency
        ? '재화 선택을 통해\n보유한 재화를 등록해보세요.'
        : isVillager
        ? '주민 검색을 통해\n거래할 주민을 등록해보세요.'
        : '아이템 검색을 통해\n보유한 아이템을 등록해보세요.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          titleText,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          guideText,
          style: TextStyle(
            color: AppColors.textHint,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        _buildOfferModeToggle(),
        const SizedBox(height: 14),
        if (_useOfferCurrency)
          _buildOfferCurrencyInput()
        else
          _buildSearchSelectBox(
            label: _offeredItem?.name ?? '아이템 검색하기',
            selectedItem: _offeredItem,
            onTap: _openOfferItemPicker,
          ),
        if (showDetailSection) ...<Widget>[
          const SizedBox(height: 12),
          _buildSectionDivider('상세 정보'),
          const SizedBox(height: 12),
          if (showTitleInStepOne)
            _buildTextField(
              label: '제목',
              hint: 'ex. 아이언우드 수납장 교환해요.',
              controller: _titleController,
            ),
          if (showExtraItemFields) ...<Widget>[
            const SizedBox(height: 10),
            _buildStepperField(
              label: '수량',
              value: _offerQuantity,
              onMinus: () => setState(() {
                _offerQuantity = (_offerQuantity - 1).clamp(1, 99);
              }),
              onPlus: () => setState(() {
                _offerQuantity = (_offerQuantity + 1).clamp(1, 99);
              }),
              onDirectInput: (value) => setState(() {
                _offerQuantity = value.clamp(1, 99);
              }),
            ),
            const SizedBox(height: 10),
            _buildDropdownField(
              label: '색상/스타일',
              value: _offerStyle,
              onTap: () => _showStylePicker(isOffer: true),
            ),
          ],
        ],
        const SizedBox(height: 18),
        const Text(
          '아이템 인증샷',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _buildProofImageBox(),
      ],
    );
  }

  Widget _buildStepTwo() {
    final showCraftingHint =
        !_useOfferCurrency && _offeredItem?.category == '레시피';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '거래 타입을 선택해주세요.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          showCraftingHint
              ? '레시피의 경우 제작 중 타입을 선택할 수 있어요.'
              : '거래 목적에 맞는 타입을 선택해주세요.',
          style: const TextStyle(
            color: AppColors.textHint,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ..._availableTradeTypes.map((type) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildTradeTypeTile(type),
          );
        }),
      ],
    );
  }

  Widget _buildStepThree() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '무엇과 교환할까요?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '구체적인 아이템이나 재화를 선택해주세요.',
          style: TextStyle(
            color: AppColors.textHint,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _buildReceiveModeToggle(),
        const SizedBox(height: 14),
        if (_useCurrency)
          _buildCurrencyInput()
        else ...<Widget>[
          _buildSearchSelectBox(
            label: _wantedItem?.name ?? '아이템 검색하기',
            selectedItem: _wantedItem,
            onTap: _openWantItemPicker,
          ),
          if (_useOfferCurrency) ...<Widget>[
            const SizedBox(height: 12),
            _buildSectionDivider('게시 정보'),
            const SizedBox(height: 12),
            _buildTextField(
              label: '제목',
              hint: 'ex. 아이언우드 수납장 교환해요.',
              controller: _titleController,
            ),
          ],
          const SizedBox(height: 12),
          _buildSectionDivider('상세 정보'),
          const SizedBox(height: 12),
          _buildStepperField(
            label: '수량',
            value: _wantQuantity,
            onMinus: () => setState(() {
              _wantQuantity = (_wantQuantity - 1).clamp(1, 99);
            }),
            onPlus: () => setState(() {
              _wantQuantity = (_wantQuantity + 1).clamp(1, 99);
            }),
            onDirectInput: (value) => setState(() {
              _wantQuantity = value.clamp(1, 99);
            }),
          ),
          const SizedBox(height: 10),
          _buildDropdownField(
            label: '색상/스타일',
            value: _wantStyle,
            onTap: () => _showStylePicker(isOffer: false),
          ),
        ],
        if (_useOfferCurrency && _useCurrency) ...<Widget>[
          const SizedBox(height: 12),
          _buildSectionDivider('게시 정보'),
          const SizedBox(height: 12),
          _buildTextField(
            label: '제목',
            hint: 'ex. 벨(덩) 교환해요.',
            controller: _titleController,
          ),
        ],
      ],
    );
  }

  Widget _buildStepFour() {
    final offerName = _useOfferCurrency
        ? '$_offerCurrencyAmount $_offerCurrencyLabel'
        : (_offeredItem?.name ?? '');
    final offerImage = _useOfferCurrency
        ? 'assets/images/icon_recipe_scroll.png'
        : (_offeredItem?.imageUrl ?? '');
    final offerDescription = _useOfferCurrency
        ? '재화'
        : _isVillagerOffer
        ? '주민 1명'
        : '아이템 $_offerQuantity개';

    final wantName = _useCurrency
        ? '$_currencyAmount $_currencyLabel'
        : (_wantedItem?.name ?? '');
    final wantImage = _useCurrency
        ? 'assets/images/icon_recipe_scroll.png'
        : (_wantedItem?.imageUrl ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '마지막으로 확인해주세요.',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '게시하기 전에 아이템과 거래 방법을\n다시 한 번 확인하세요.',
          style: TextStyle(
            color: AppColors.textHint,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _buildSummaryItem(
                  imageUrl: offerImage,
                  name: offerName.isEmpty ? '-' : offerName,
                  description: offerDescription,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.swap_vert_rounded,
                  color: AppColors.textAccent,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  imageUrl: wantImage,
                  name: wantName.isEmpty ? '-' : wantName,
                  description: _useCurrency ? '재화' : '아이템',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '어떻게 거래할까요?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: MarketMoveType.values
              .map((moveType) {
                final selected = moveType == _moveType;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: moveType == MarketMoveType.visitor ? 8 : 0,
                      left: moveType == MarketMoveType.host ? 8 : 0,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => setState(() => _moveType = moveType),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 152,
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selected
                                ? AppColors.badgeBlueText
                                : AppColors.borderDefault,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              moveType == MarketMoveType.visitor
                                  ? Icons.flight_takeoff_rounded
                                  : Icons.home_rounded,
                              color: selected
                                  ? AppColors.badgeBlueText
                                  : AppColors.textHint,
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              moveType.label,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              moveType == MarketMoveType.visitor
                                  ? '상대방 섬으로'
                                  : '나의 섬으로',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 18),
        const Text(
          '방문객 안내 사항(선택)',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _memoController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: '구체적인 거래 방법이나 게시글 내용을 남겨주세요...',
          ),
        ),
      ],
    );
  }

  Widget _buildTradeTypeTile(MarketTradeType type) {
    final selected = _tradeType == type;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _tradeType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.badgeBlueText : AppColors.borderDefault,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _tradeTypeColor(type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(_tradeTypeIcon(type), color: _tradeTypeColor(type)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    type.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _tradeTypeDescription(type),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected
                  ? AppColors.badgeBlueText
                  : AppColors.borderDefault,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferModeToggle() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.catalogSegmentBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: _buildOfferModeButton(useCurrency: false)),
          Expanded(child: _buildOfferModeButton(useCurrency: true)),
        ],
      ),
    );
  }

  Widget _buildOfferModeButton({required bool useCurrency}) {
    final selected = _useOfferCurrency == useCurrency;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() {
        _useOfferCurrency = useCurrency;
        final availableTypes = _availableTradeTypes;
        if (!availableTypes.contains(_tradeType)) {
          _tradeType = MarketTradeType.exchange;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.bgCard : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          useCurrency ? '재화' : '아이템',
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCurrencyInput() {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _buildOfferQuickCurrency('벨(덩)', Icons.paid_rounded),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildOfferQuickCurrency(
                '마일 여행권',
                Icons.airplane_ticket_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderDefault),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: <Widget>[
              _buildCircleButton(
                icon: Icons.remove_rounded,
                onTap: () => setState(() {
                  _offerCurrencyAmount = (_offerCurrencyAmount - 1).clamp(
                    0,
                    9999999,
                  );
                }),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final directInput = await _showNumberInputDialog(
                      title: '등록 재화 수량 입력',
                      initialValue: _offerCurrencyAmount,
                      min: 0,
                      max: 9999999,
                    );
                    if (directInput == null || !mounted) {
                      return;
                    }
                    setState(() {
                      _offerCurrencyAmount = directInput;
                    });
                  },
                  child: Text(
                    '$_offerCurrencyAmount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              _buildCircleButton(
                icon: Icons.add_rounded,
                isAccent: true,
                onTap: () => setState(() {
                  _offerCurrencyAmount = (_offerCurrencyAmount + 1).clamp(
                    0,
                    9999999,
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfferQuickCurrency(String label, IconData icon) {
    final selected = _offerCurrencyLabel == label;
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () => setState(() => _offerCurrencyLabel = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 108,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected ? AppColors.badgeBlueText : AppColors.borderDefault,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 19,
              backgroundColor: selected
                  ? AppColors.badgeBlueBg
                  : AppColors.catalogChipBg,
              child: Icon(icon, color: AppColors.textPrimary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiveModeToggle() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.catalogSegmentBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: _buildReceiveModeButton(useCurrency: false)),
          Expanded(child: _buildReceiveModeButton(useCurrency: true)),
        ],
      ),
    );
  }

  Widget _buildReceiveModeButton({required bool useCurrency}) {
    final selected = _useCurrency == useCurrency;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _useCurrency = useCurrency),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.bgCard : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          useCurrency ? '재화' : '아이템',
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyInput() {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _buildQuickCurrency('벨(덩)', Icons.paid_rounded)),
            const SizedBox(width: 14),
            Expanded(
              child: _buildQuickCurrency(
                '마일 여행권',
                Icons.airplane_ticket_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderDefault),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: <Widget>[
              _buildCircleButton(
                icon: Icons.remove_rounded,
                onTap: () => setState(() {
                  _currencyAmount = (_currencyAmount - 1).clamp(0, 9999999);
                }),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final directInput = await _showNumberInputDialog(
                      title: '재화 수량 입력',
                      initialValue: _currencyAmount,
                      min: 0,
                      max: 9999999,
                    );
                    if (directInput == null || !mounted) {
                      return;
                    }
                    setState(() {
                      _currencyAmount = directInput;
                    });
                  },
                  child: Text(
                    '$_currencyAmount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              _buildCircleButton(
                icon: Icons.add_rounded,
                isAccent: true,
                onTap: () => setState(() {
                  _currencyAmount = (_currencyAmount + 1).clamp(0, 9999999);
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCurrency(String label, IconData icon) {
    final selected = _currencyLabel == label;
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () => setState(() => _currencyLabel = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 108,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected ? AppColors.badgeBlueText : AppColors.borderDefault,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 19,
              backgroundColor: selected
                  ? AppColors.badgeBlueBg
                  : AppColors.catalogChipBg,
              child: Icon(icon, color: AppColors.textPrimary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String imageUrl,
    required String name,
    required String description,
  }) {
    return Column(
      children: <Widget>[
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.catalogChipBg,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(8),
          child: _buildImage(imageUrl, fit: BoxFit.contain),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          description,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSelectBox({
    required String label,
    required CatalogItem? selectedItem,
    required VoidCallback onTap,
  }) {
    final hasItem = selectedItem != null;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: hasItem ? 116 : 144),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderDefault,
            style: BorderStyle.solid,
          ),
        ),
        child: hasItem
            ? Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.catalogChipBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: _buildImage(
                            selectedItem.imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              selectedItem.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              alignment: Alignment.topLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.catalogChipBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                selectedItem.category,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: SizedBox()),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.catalogChipBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_right_rounded,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.catalogChipBg,
                    child: Icon(
                      Icons.search_rounded,
                      color: AppColors.textHint,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: label.contains('검색')
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionDivider(String label) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider(color: AppColors.borderDefault)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderDefault)),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperField({
    required String label,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required ValueChanged<int> onDirectInput,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Row(
              children: <Widget>[
                _buildCircleButton(icon: Icons.remove_rounded, onTap: onMinus),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final directInput = await _showNumberInputDialog(
                      title: '$label 입력',
                      initialValue: value,
                      min: 1,
                      max: 99,
                    );
                    if (directInput == null) {
                      return;
                    }
                    onDirectInput(directInput);
                  },
                  child: SizedBox(
                    width: 64,
                    child: Text(
                      '$value',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                _buildCircleButton(
                  icon: Icons.add_rounded,
                  isAccent: true,
                  onTap: onPlus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.accentDeepOrange,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.accentDeepOrange,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofImageBox() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _pickProofImage,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderDefault,
            style: BorderStyle.solid,
          ),
        ),
        child: _proofImagePath.isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.catalogChipBg,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.textHint,
                      size: 26,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '스크린샷 추가하기',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(_proofImagePath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isAccent ? AppColors.accentOrange : AppColors.catalogChipBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isAccent ? AppColors.accentDeepOrange : AppColors.textMuted,
        ),
      ),
    );
  }

  Future<int?> _showNumberInputDialog({
    required String title,
    required int initialValue,
    required int min,
    required int max,
  }) async {
    var inputText = '$initialValue';
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextFormField(
            initialValue: inputText,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) => inputText = value,
            decoration: InputDecoration(hintText: '$min ~ $max'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(inputText.trim());
                if (parsed == null) {
                  Navigator.of(dialogContext).pop();
                  return;
                }
                Navigator.of(dialogContext).pop(parsed.clamp(min, max).toInt());
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentDeepOrange,
              ),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
    return result;
  }

  IconData _tradeTypeIcon(MarketTradeType tradeType) {
    switch (tradeType) {
      case MarketTradeType.sharing:
        return Icons.volunteer_activism_rounded;
      case MarketTradeType.exchange:
        return Icons.swap_horiz_rounded;
      case MarketTradeType.touching:
        return Icons.touch_app_rounded;
      case MarketTradeType.crafting:
        return Icons.construction_rounded;
    }
  }

  Color _tradeTypeColor(MarketTradeType tradeType) {
    switch (tradeType) {
      case MarketTradeType.sharing:
        return AppColors.primaryDefault;
      case MarketTradeType.exchange:
        return AppColors.navActive;
      case MarketTradeType.touching:
        return AppColors.badgePurpleText;
      case MarketTradeType.crafting:
        return AppColors.badgeRedText;
    }
  }

  String _tradeTypeDescription(MarketTradeType tradeType) {
    switch (tradeType) {
      case MarketTradeType.sharing:
        return '좋은 분께 무료로 보내요.';
      case MarketTradeType.exchange:
        return '원하는 아이템과 교환해요.';
      case MarketTradeType.touching:
        return '아이템 만지작을 열어요.';
      case MarketTradeType.crafting:
        return '주민이 제작하고 있어요.';
    }
  }

  bool _canMoveFromStepThree() {
    if (_tradeType == MarketTradeType.sharing ||
        _tradeType == MarketTradeType.touching) {
      return true;
    }
    if (_useCurrency) {
      return _currencyAmount > 0;
    }
    return _wantedItem != null;
  }

  Future<void> _openOfferItemPicker() async {
    final selected = await showModalBottomSheet<CatalogItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.88,
        child: MarketItemPickerSheet(title: '아이템 검색'),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _useOfferCurrency = false;
      _offeredItem = selected;
      final availableTypes = _availableTradeTypesForCategory(selected.category);
      if (!availableTypes.contains(_tradeType)) {
        _tradeType = MarketTradeType.exchange;
      }
      _offerStyle = _resolveInitialStyle(selected);
      // 유지보수 포인트:
      // 거래 대상이 주민이면 주민 거래 문구를 사용해 의도를 명확히 합니다.
      _titleController.text = selected.category == '주민'
          ? '${selected.name} 주민 거래해요'
          : '${selected.name} 교환해요';
      if (selected.category == '주민') {
        _offerQuantity = 1;
        _offerStyle = '기본';
      }
    });
  }

  Future<void> _openWantItemPicker() async {
    final selected = await showModalBottomSheet<CatalogItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.88,
        child: MarketItemPickerSheet(title: '교환 받을 아이템 검색'),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _wantedItem = selected;
      _wantStyle = _resolveInitialStyle(selected);

      // 유지보수 포인트:
      // 내가 '재화'를 드리는 모드라면, 제목도 받을 아이템 기준으로 자동 보정합니다.
      // (사용자가 직접 제목을 바꾼 경우엔 이후 자유롭게 수정 가능)
      if (_useOfferCurrency) {
        _titleController.text = '${selected.name} 구해요';
      }
    });
  }

  Future<void> _showStylePicker({required bool isOffer}) async {
    final targetItem = isOffer ? _offeredItem : _wantedItem;
    final options = _extractStyleOptions(targetItem);
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: options
                .map((option) {
                  return ListTile(
                    title: Text(option),
                    onTap: () => Navigator.of(context).pop(option),
                  );
                })
                .toList(growable: false),
          ),
        );
      },
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      if (isOffer) {
        _offerStyle = selected;
      } else {
        _wantStyle = selected;
      }
    });
  }

  String _resolveInitialStyle(CatalogItem item) {
    final options = _extractStyleOptions(item);
    if (options.contains('기본')) {
      return '기본';
    }
    return options.first;
  }

  List<String> _extractStyleOptions(CatalogItem? item) {
    if (item == null) {
      return const <String>['기본'];
    }

    final options = <String>{};
    for (final tag in item.tags) {
      if (tag.startsWith('색상옵션:')) {
        final value = tag.replaceFirst('색상옵션:', '').trim();
        if (value.isNotEmpty) {
          options.add(value);
        }
        continue;
      }
      if (tag.startsWith('스타일:')) {
        final value = tag.replaceFirst('스타일:', '').trim();
        if (value.isNotEmpty) {
          options.add(value);
        }
      }
    }

    if (options.isEmpty) {
      return const <String>['기본'];
    }
    return options.toList(growable: false);
  }

  Future<void> _pickProofImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _proofImagePath = picked.path;
    });
  }

  Future<void> _submit() async {
    if (!_useOfferCurrency && _offeredItem == null) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });

    // 유지보수 포인트:
    // 내가 재화를 드리는 경우, 마켓 분류 카테고리는 '받을 아이템' 기준으로 잡아야
    // 상단 탭(아이템/레시피/주민/만지작)에서 정상 필터링됩니다.
    final categorySource = _useOfferCurrency
        ? (_useCurrency ? '아이템' : (_wantedItem?.category ?? '아이템'))
        : _offeredItem!.category;
    final offeredName = _useOfferCurrency
        ? '$_offerCurrencyAmount $_offerCurrencyLabel'
        : _offeredItem!.name;
    final offeredImageUrl = _useOfferCurrency
        ? 'assets/images/icon_recipe_scroll.png'
        : _offeredItem!.imageUrl;
    final offeredQuantity = _useOfferCurrency ? 1 : _offerQuantity;
    final offeredVariant = _useOfferCurrency
        ? _offerCurrencyLabel
        : _offerStyle;
    final bool oneWayOffer =
        _tradeType == MarketTradeType.sharing ||
        _tradeType == MarketTradeType.touching;
    final boardType = _mapBoardType(
      catalogCategory: categorySource,
      tradeType: _tradeType,
    );
    final category = _mapCategory(
      catalogCategory: categorySource,
      tradeType: _tradeType,
    );
    final offer = MarketOffer(
      id: '',
      ownerUid: '',
      category: category,
      boardType: boardType,
      lifecycle: MarketLifecycleTab.ongoing,
      status: MarketOfferStatus.open,
      ownerName: '내 섬',
      ownerAvatarUrl: '',
      createdAtLabel: '방금 전',
      title: _titleController.text.trim().isEmpty
          ? '$offeredName 거래'
          : _titleController.text.trim(),
      offerHeaderLabel: oneWayOffer ? '나눔' : '드려요',
      offerItemName: offeredName,
      offerItemImageUrl: offeredImageUrl,
      offerItemQuantity: offeredQuantity,
      offerItemVariant: offeredVariant,
      wantHeaderLabel: oneWayOffer ? '' : '받아요',
      wantItemName: oneWayOffer
          ? ''
          : _useCurrency
          ? '$_currencyAmount $_currencyLabel'
          : (_wantedItem?.name ?? ''),
      wantItemImageUrl: oneWayOffer
          ? ''
          : _useCurrency
          ? 'assets/images/icon_recipe_scroll.png'
          : (_wantedItem?.imageUrl ?? ''),
      wantItemQuantity: oneWayOffer ? 0 : (_useCurrency ? 1 : _wantQuantity),
      wantItemVariant: _wantStyle,
      touchingTags: _tradeType == MarketTradeType.touching
          ? <String>['가구', '벽지/천장']
          : const <String>[],
      entryFeeText: '무료',
      actionLabel: _tradeType == MarketTradeType.touching ? '줄서기' : '거래제안',
      isMine: true,
      dimmed: false,
      description: _memoController.text.trim(),
      tradeType: _tradeType,
      moveType: _moveType,
      oneWayOffer: oneWayOffer,
      coverImageUrl: _proofImagePath,
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    );

    await ref.read(marketViewModelProvider.notifier).createOffer(offer);

    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
    });
    Navigator.of(context).pop();
  }

  MarketFilterCategory _mapCategory({
    required String catalogCategory,
    required MarketTradeType tradeType,
  }) {
    if (tradeType == MarketTradeType.touching) {
      return MarketFilterCategory.touching;
    }
    if (catalogCategory == '레시피') {
      return MarketFilterCategory.recipe;
    }
    if (catalogCategory == '주민') {
      return MarketFilterCategory.villager;
    }
    if (catalogCategory == '아이템' ||
        catalogCategory == '벽지' ||
        catalogCategory == '가구' ||
        catalogCategory == '패션') {
      return MarketFilterCategory.item;
    }
    return MarketFilterCategory.all;
  }

  MarketBoardType _mapBoardType({
    required String catalogCategory,
    required MarketTradeType tradeType,
  }) {
    if (tradeType == MarketTradeType.touching) {
      return MarketBoardType.touching;
    }
    if (catalogCategory == '가구') {
      return MarketBoardType.touching;
    }
    return MarketBoardType.exchange;
  }

  List<MarketTradeType> _availableTradeTypesForCategory(String? category) {
    final types = <MarketTradeType>[
      MarketTradeType.sharing,
      MarketTradeType.exchange,
    ];
    final normalizedCategory = (category ?? '').replaceAll(' ', '');
    final isVillagerCategory = normalizedCategory.contains('주민');
    final isRecipeCategory =
        normalizedCategory.contains('레시피') ||
        normalizedCategory.contains('DIY');
    final isTouchingCategory =
        normalizedCategory.contains('가구') ||
        normalizedCategory.contains('아이템') ||
        normalizedCategory.contains('패션') ||
        normalizedCategory.contains('벽지') ||
        normalizedCategory.contains('의상');

    // 유지보수 포인트:
    // 주민/레시피(문자열 변형 포함)에서는 만지작을 숨기고,
    // 레시피에서만 제작 중을 노출합니다.
    if (isTouchingCategory && !isVillagerCategory && !isRecipeCategory) {
      types.add(MarketTradeType.touching);
    }

    if (isRecipeCategory) {
      types.add(MarketTradeType.crafting);
    }
    return types;
  }

  Widget _buildImage(String source, {required BoxFit fit}) {
    if (source.isEmpty) {
      return const SizedBox.shrink();
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image_rounded, color: AppColors.textHint),
      );
    }
    return Image.asset(
      source,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        if (source.startsWith('/')) {
          return Image.file(
            File(source),
            fit: fit,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textHint,
            ),
          );
        }
        return const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textHint,
        );
      },
    );
  }
}
