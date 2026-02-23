import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';
import 'package:nook_lounge_app/domain/model/market_offer.dart';
import 'package:nook_lounge_app/presentation/view/market/market_item_picker_sheet.dart';

final _marketTradeRegisterIslandsProvider = StreamProvider.autoDispose
    .family<List<IslandProfile>, String>((ref, uid) {
      return ref.watch(islandRepositoryProvider).watchIslands(uid);
    });

final _marketTradeRegisterPrimaryIslandIdProvider = StreamProvider.autoDispose
    .family<String?, String>((ref, uid) {
      return ref.watch(islandRepositoryProvider).watchPrimaryIslandId(uid);
    });

IslandProfile? _resolveSelectedIslandForMarketTrade({
  required List<IslandProfile> islands,
  required String? primaryIslandId,
}) {
  if (islands.isEmpty) {
    return null;
  }
  if (primaryIslandId == null || primaryIslandId.isEmpty) {
    return islands.first;
  }
  for (final island in islands) {
    if (island.id == primaryIslandId) {
      return island;
    }
  }
  return islands.first;
}

class MarketTradeRegisterPage extends ConsumerStatefulWidget {
  const MarketTradeRegisterPage({this.initialOffer, super.key});

  final MarketOffer? initialOffer;

  @override
  ConsumerState<MarketTradeRegisterPage> createState() =>
      _MarketTradeRegisterPageState();
}

class _MarketTradeRegisterPageState
    extends ConsumerState<MarketTradeRegisterPage> {
  static const String _nookMilesTicketImageUrl =
      'https://dodo.ac/np/images/f/f5/Nook_Miles_Ticket_NH_Icon.png';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  int _step = 0;
  MarketTradeType _tradeType = MarketTradeType.sharing;
  MarketMoveType _moveType = MarketMoveType.visitor;
  CatalogItem? _offeredItem;
  CatalogItem? _wantedItem;
  List<CatalogItem> _touchingItems = <CatalogItem>[];
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

  bool get _isEditMode => widget.initialOffer != null;
  bool get _isVillagerOffer => _offeredItem?.category == '주민';

  List<MarketTradeType> get _availableTradeTypes =>
      _availableTradeTypesForCategory(
        _useOfferCurrency ? '재화' : _offeredItem?.category,
      );

  void _initializeWithInitialOffer() {
    final initialOffer = widget.initialOffer;
    if (initialOffer == null) {
      return;
    }

    _tradeType = initialOffer.tradeType;
    _moveType = initialOffer.moveType;
    _titleController.text = initialOffer.title;
    _memoController.text = initialOffer.description;
    _proofImagePath = initialOffer.coverImageUrl;
    _touchingItems = _buildTouchingItemsFromTags(initialOffer.touchingTags);

    _useOfferCurrency = _isCurrencySelection(
      typeLabel: initialOffer.offerItemCategory,
      name: initialOffer.offerItemName,
      imageUrl: initialOffer.offerItemImageUrl,
    );
    if (_useOfferCurrency) {
      final parsed = _parseCurrencyDisplay(
        source: initialOffer.offerItemName,
        fallbackLabel: initialOffer.offerItemVariant,
        fallbackAmount: _sanitizeCount(
          initialOffer.offerItemQuantity,
          min: 1,
          max: 9999999,
        ),
      );
      _offerCurrencyLabel = parsed.label;
      _offerCurrencyAmount = parsed.amount;
      _offeredItem = null;
      _offerQuantity = 1;
      _offerStyle = '기본';
    } else {
      _offeredItem = _buildCatalogItemFromOffer(
        name: initialOffer.offerItemName,
        imageUrl: initialOffer.offerItemImageUrl,
        typeLabel: initialOffer.offerItemCategory,
        variant: initialOffer.offerItemVariant,
      );
      _offerQuantity = _sanitizeCount(initialOffer.offerItemQuantity);
      _offerStyle = _resolveInitialVariant(
        preferred: initialOffer.offerItemVariant,
        item: _offeredItem,
      );
    }

    final bool oneWayOffer =
        initialOffer.oneWayOffer ||
        _tradeType == MarketTradeType.sharing ||
        _tradeType == MarketTradeType.touching;
    if (oneWayOffer) {
      _useCurrency = false;
      _wantedItem = null;
      _wantQuantity = 1;
      _wantStyle = '기본';
      _currencyAmount = 1;
      return;
    }

    _useCurrency = _isCurrencySelection(
      typeLabel: initialOffer.wantItemCategory,
      name: initialOffer.wantItemName,
      imageUrl: initialOffer.wantItemImageUrl,
    );
    if (_useCurrency) {
      final parsed = _parseCurrencyDisplay(
        source: initialOffer.wantItemName,
        fallbackLabel: initialOffer.wantItemVariant,
        fallbackAmount: _sanitizeCount(
          initialOffer.wantItemQuantity,
          min: 1,
          max: 9999999,
        ),
      );
      _currencyLabel = parsed.label;
      _currencyAmount = parsed.amount;
      _wantedItem = null;
      _wantQuantity = 1;
      _wantStyle = '기본';
    } else {
      _wantedItem = _buildCatalogItemFromOffer(
        name: initialOffer.wantItemName,
        imageUrl: initialOffer.wantItemImageUrl,
        typeLabel: initialOffer.wantItemCategory,
        variant: initialOffer.wantItemVariant,
      );
      _wantQuantity = _sanitizeCount(initialOffer.wantItemQuantity);
      _wantStyle = _resolveInitialVariant(
        preferred: initialOffer.wantItemVariant,
        item: _wantedItem,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeWithInitialOffer();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? '거래 수정하기' : '거래를 등록하기')),
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
      3 =>
        _isSubmitting
            ? (_isEditMode ? '수정중...' : '등록중...')
            : (_isEditMode ? '거래를 수정하기' : '거래를 등록하기'),
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
        Text(titleText, style: AppTextStyles.bodyPrimaryHeavy),
        const SizedBox(height: 10),
        Text(
          guideText,
          style: AppTextStyles.labelWithColor(
            AppColors.textHint,
            weight: FontWeight.w700,
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
        Text('아이템 인증샷', style: AppTextStyles.bodyPrimaryHeavy),
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
        Text('거래 타입을 선택해주세요.', style: AppTextStyles.bodyPrimaryHeavy),
        const SizedBox(height: 10),
        Text(
          showCraftingHint
              ? '레시피의 경우 제작 중 타입을 선택할 수 있어요.'
              : '거래 목적에 맞는 타입을 선택해주세요.',
          style: AppTextStyles.labelWithColor(
            AppColors.textHint,
            weight: FontWeight.w700,
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
    if (_tradeType == MarketTradeType.touching) {
      return _buildTouchingStepThree();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('무엇과 교환할까요?', style: AppTextStyles.bodyPrimaryHeavy),
        const SizedBox(height: 10),
        Text('구체적인 아이템이나 재화를 선택해주세요.', style: AppTextStyles.bodyHintStrong),
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

  Widget _buildTouchingStepThree() {
    final hasItems = _touchingItems.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('만지작할 아이템을 선택해주세요.', style: AppTextStyles.bodyPrimaryHeavy),
        const SizedBox(height: 10),
        Text('아이템을 여러 개 선택할 수 있어요.', style: AppTextStyles.bodyHintStrong),
        const SizedBox(height: 14),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _openTouchingItemPicker,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: hasItems
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            '선택된 아이템',
                            style: AppTextStyles.bodyPrimaryHeavy,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _openTouchingItemPicker,
                            icon: const Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: AppColors.accentDeepOrange,
                            ),
                            label: Text(
                              '추가',
                              style: AppTextStyles.captionWithColor(
                                AppColors.accentDeepOrange,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _touchingItems
                            .map(
                              (item) => Container(
                                constraints: const BoxConstraints(
                                  minHeight: 32,
                                  maxWidth: 220,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.catalogChipBg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.borderDefault,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.captionPrimaryHeavy,
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _removeTouchingItem(item.id),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 15,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.catalogChipBg,
                        child: Icon(
                          Icons.touch_app_rounded,
                          color: AppColors.textHint,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('만지작 아이템 선택하기', style: AppTextStyles.bodyHintStrong),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepFour() {
    final offerName = _useOfferCurrency
        ? _formatCurrencyDisplay(
            label: _offerCurrencyLabel,
            amount: _offerCurrencyAmount,
          )
        : (_offeredItem?.name ?? '');
    final offerImage = _useOfferCurrency
        ? _resolveCurrencyImageUrl(_offerCurrencyLabel)
        : (_offeredItem?.imageUrl ?? '');
    final offerDescription = _useOfferCurrency
        ? '재화'
        : _isVillagerOffer
        ? '주민 1명'
        : '아이템 $_offerQuantity개';

    final wantName = _useCurrency
        ? _formatCurrencyDisplay(label: _currencyLabel, amount: _currencyAmount)
        : (_wantedItem?.name ?? '');
    final wantImage = _useCurrency
        ? _resolveCurrencyImageUrl(_currencyLabel)
        : (_wantedItem?.imageUrl ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('마지막으로 확인해주세요.', style: AppTextStyles.bodyPrimaryHeavy),
        const SizedBox(height: 10),
        Text(
          '게시하기 전에 아이템과 거래 방법을\n다시 한 번 확인하세요.',
          style: AppTextStyles.labelWithColor(
            AppColors.textHint,
            weight: FontWeight.w700,
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
        Text('어떻게 거래할까요?', style: AppTextStyles.bodyPrimaryHeavy),
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
                              style: AppTextStyles.labelWithColor(
                                selected
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                weight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              moveType == MarketMoveType.visitor
                                  ? '상대방 섬으로'
                                  : '나의 섬으로',
                              style: AppTextStyles.labelWithColor(
                                AppColors.textMuted,
                                weight: FontWeight.w700,
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
        Text('방문객 안내 사항(선택)', style: AppTextStyles.bodyPrimaryHeavy),
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
      onTap: () => setState(() {
        _tradeType = type;
        // 유지보수 포인트:
        // 만지작 선택 직후 바로 다중 선택이 가능하도록 현재 등록 아이템을
        // 기본 선택 목록에 자동으로 한 번만 추가합니다.
        if (type == MarketTradeType.touching &&
            _offeredItem != null &&
            !_touchingItems.any((item) => item.id == _offeredItem!.id)) {
          _touchingItems = <CatalogItem>[..._touchingItems, _offeredItem!];
        }
      }),
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
                  Text(type.label, style: AppTextStyles.bodyPrimaryHeavy),
                  Text(
                    _tradeTypeDescription(type),
                    style: AppTextStyles.bodyMutedStrong,
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
          style: AppTextStyles.labelWithColor(
            selected ? AppColors.textPrimary : AppColors.textMuted,
            weight: FontWeight.w800,
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
                '마일 이용권',
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
                    style: AppTextStyles.bodyPrimaryHeavy,
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
            Text(label, style: AppTextStyles.bodyPrimaryHeavy),
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
          style: AppTextStyles.labelWithColor(
            selected ? AppColors.textPrimary : AppColors.textMuted,
            weight: FontWeight.w800,
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
                '마일 이용권',
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
                    style: AppTextStyles.bodyPrimaryHeavy,
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
            Text(label, style: AppTextStyles.bodyPrimaryHeavy),
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
          style: AppTextStyles.bodyPrimaryHeavy,
        ),
        Text(description, style: AppTextStyles.bodyMutedStrong),
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
                              style: AppTextStyles.bodyPrimaryHeavy,
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
                                style: AppTextStyles.captionSecondary,
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
                    style: AppTextStyles.labelWithColor(
                      label.contains('검색')
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                      weight: FontWeight.w800,
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
            style: AppTextStyles.labelWithColor(
              AppColors.textMuted,
              weight: FontWeight.w700,
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
              style: AppTextStyles.labelWithColor(
                AppColors.textSecondary,
                weight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.bodyPrimaryStrong,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                hintText: hint,
                hintStyle: AppTextStyles.bodyHintStrong,
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
            style: AppTextStyles.labelWithColor(
              AppColors.textSecondary,
              weight: FontWeight.w800,
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
                      style: AppTextStyles.bodyPrimaryHeavy,
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
              style: AppTextStyles.labelWithColor(
                AppColors.textSecondary,
                weight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: AppTextStyles.labelWithColor(
                AppColors.accentDeepOrange,
                weight: FontWeight.w800,
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
    final source = _proofImagePath.trim();
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
        child: source.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.catalogChipBg,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.textHint,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('스크린샷 추가하기', style: AppTextStyles.bodyHintStrong),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child:
                    source.startsWith('http://') ||
                        source.startsWith('https://')
                    ? Image.network(
                        source,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textHint,
                          );
                        },
                      )
                    : Image.file(
                        File(source),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textHint,
                          );
                        },
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
      if (_tradeType == MarketTradeType.touching) {
        return _touchingItems.isNotEmpty;
      }
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
      if (_tradeType == MarketTradeType.touching &&
          !_touchingItems.any((item) => item.id == selected.id)) {
        _touchingItems = <CatalogItem>[..._touchingItems, selected];
      }
    });
  }

  Future<void> _openTouchingItemPicker() async {
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
        child: MarketItemPickerSheet(
          title: '만지작 아이템 검색',
          touchingOnlyCategories: true,
        ),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      final exists = _touchingItems.any((item) => item.id == selected.id);
      if (!exists) {
        _touchingItems = <CatalogItem>[..._touchingItems, selected];
      }
    });
  }

  void _removeTouchingItem(String itemId) {
    setState(() {
      _touchingItems = _touchingItems
          .where((item) => item.id != itemId)
          .toList(growable: false);
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

  bool _isCurrencySelection({
    required String typeLabel,
    required String name,
    required String imageUrl,
  }) {
    final normalizedType = typeLabel.replaceAll(' ', '');
    if (normalizedType.contains('재화')) {
      return true;
    }
    return _isCurrencyLike(name: name, imageUrl: imageUrl);
  }

  CatalogItem _buildCatalogItemFromOffer({
    required String name,
    required String imageUrl,
    required String typeLabel,
    required String variant,
  }) {
    final normalizedType = typeLabel.replaceAll(' ', '');
    final category = normalizedType.contains('주민')
        ? '주민'
        : normalizedType.contains('레시피') || normalizedType.contains('DIY')
        ? '레시피'
        : '아이템';
    final tags = <String>[
      if (variant.trim().isNotEmpty) '스타일:${variant.trim()}',
    ];
    return CatalogItem(
      id: 'prefill_${category}_${name.hashCode}_${imageUrl.hashCode}_${variant.hashCode}',
      category: category,
      name: name,
      imageUrl: imageUrl,
      tags: tags,
    );
  }

  String _resolveInitialVariant({
    required String preferred,
    required CatalogItem? item,
  }) {
    final normalized = preferred.trim();
    final options = _extractStyleOptions(item);
    if (normalized.isNotEmpty) {
      return normalized;
    }
    if (options.contains('기본')) {
      return '기본';
    }
    return options.first;
  }

  ({String label, int amount}) _parseCurrencyDisplay({
    required String source,
    required String fallbackLabel,
    required int fallbackAmount,
  }) {
    final normalizedSource = source.trim();
    final starPattern = RegExp(r'^(.+?)\s*\*\s*(\d+)$');
    final starMatch = starPattern.firstMatch(normalizedSource);
    if (starMatch != null) {
      final label = starMatch.group(1)?.trim() ?? '';
      final amount = int.tryParse(starMatch.group(2) ?? '');
      if (label.isNotEmpty && amount != null && amount > 0) {
        return (label: label, amount: amount);
      }
    }

    final legacyPattern = RegExp(r'^(\d+)\s*(.+)$');
    final legacyMatch = legacyPattern.firstMatch(normalizedSource);
    if (legacyMatch != null) {
      final amount = int.tryParse(legacyMatch.group(1) ?? '');
      final label = legacyMatch.group(2)?.trim() ?? '';
      if (label.isNotEmpty && amount != null && amount > 0) {
        return (label: label, amount: amount);
      }
    }

    final fallback = fallbackLabel.trim().isEmpty
        ? '벨(덩)'
        : fallbackLabel.trim();
    return (
      label: fallback,
      amount: _sanitizeCount(fallbackAmount, min: 1, max: 9999999),
    );
  }

  int _sanitizeCount(int value, {int fallback = 1, int min = 1, int max = 99}) {
    if (value <= 0) {
      return fallback.clamp(min, max).toInt();
    }
    return value.clamp(min, max).toInt();
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
        ? _formatCurrencyDisplay(
            label: _offerCurrencyLabel,
            amount: _offerCurrencyAmount,
          )
        : _offeredItem!.name;
    final offeredImageUrl = _useOfferCurrency
        ? _resolveCurrencyImageUrl(_offerCurrencyLabel)
        : _offeredItem!.imageUrl;
    final offeredQuantity = _useOfferCurrency ? 1 : _offerQuantity;
    final offeredVariant = _useOfferCurrency
        ? _offerCurrencyLabel
        : _offerStyle;
    final bool oneWayOffer =
        _tradeType == MarketTradeType.sharing ||
        _tradeType == MarketTradeType.touching;
    final offeredTypeLabel = _resolveItemTypeLabel(
      category: _useOfferCurrency ? '재화' : _offeredItem!.category,
      imageUrl: offeredImageUrl,
      name: offeredName,
    );
    final wantedName = oneWayOffer
        ? ''
        : _useCurrency
        ? _formatCurrencyDisplay(label: _currencyLabel, amount: _currencyAmount)
        : (_wantedItem?.name ?? '');
    final wantedImageUrl = oneWayOffer
        ? ''
        : _useCurrency
        ? _resolveCurrencyImageUrl(_currencyLabel)
        : (_wantedItem?.imageUrl ?? '');
    final wantedTypeLabel = oneWayOffer
        ? ''
        : _resolveItemTypeLabel(
            category: _useCurrency ? '재화' : _wantedItem?.category,
            imageUrl: wantedImageUrl,
            name: wantedName,
          );
    final boardType = _mapBoardType(
      catalogCategory: categorySource,
      tradeType: _tradeType,
    );
    final category = _mapCategory(
      catalogCategory: categorySource,
      tradeType: _tradeType,
    );
    final currentUid = ref.read(authRepositoryProvider).currentUserId ?? '';
    final selectedIsland = await _loadSelectedIslandForOwner(currentUid);
    final ownerName = _resolveOwnerName(selectedIsland);
    final ownerAvatarUrl = (selectedIsland?.imageUrl ?? '').trim();
    final title = _titleController.text.trim().isEmpty
        ? '$offeredName 거래'
        : _titleController.text.trim();
    final mergedCoverImage = _proofImagePath.trim().isNotEmpty
        ? _proofImagePath.trim()
        : (widget.initialOffer?.coverImageUrl ?? '');
    final notifier = ref.read(marketViewModelProvider.notifier);
    final initialOffer = widget.initialOffer;

    if (initialOffer == null) {
      final offer = MarketOffer(
        id: '',
        ownerUid: '',
        category: category,
        boardType: boardType,
        lifecycle: MarketLifecycleTab.ongoing,
        status: MarketOfferStatus.open,
        ownerName: ownerName,
        ownerAvatarUrl: ownerAvatarUrl,
        title: title,
        offerHeaderLabel: oneWayOffer ? '나눔' : '드려요',
        offerItemName: offeredName,
        offerItemImageUrl: offeredImageUrl,
        offerItemQuantity: offeredQuantity,
        offerItemCategory: offeredTypeLabel,
        offerItemVariant: offeredVariant,
        wantHeaderLabel: oneWayOffer ? '' : '받아요',
        wantItemName: wantedName,
        wantItemImageUrl: wantedImageUrl,
        wantItemQuantity: oneWayOffer ? 0 : (_useCurrency ? 1 : _wantQuantity),
        wantItemCategory: wantedTypeLabel,
        wantItemVariant: _wantStyle,
        touchingTags: _tradeType == MarketTradeType.touching
            ? _buildTouchingTagsForSave()
            : const <String>[],
        entryFeeText: '무료',
        isMine: true,
        dimmed: false,
        description: _memoController.text.trim(),
        tradeType: _tradeType,
        moveType: _moveType,
        oneWayOffer: oneWayOffer,
        coverImageUrl: mergedCoverImage,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await notifier.createOffer(offer);
    } else {
      final offer = initialOffer.copyWith(
        category: category,
        boardType: boardType,
        ownerName: ownerName,
        ownerAvatarUrl: ownerAvatarUrl,
        title: title,
        offerHeaderLabel: oneWayOffer ? '나눔' : '드려요',
        offerItemName: offeredName,
        offerItemImageUrl: offeredImageUrl,
        offerItemQuantity: offeredQuantity,
        offerItemCategory: offeredTypeLabel,
        offerItemVariant: offeredVariant,
        wantHeaderLabel: oneWayOffer ? '' : '받아요',
        wantItemName: wantedName,
        wantItemImageUrl: wantedImageUrl,
        wantItemQuantity: oneWayOffer ? 0 : (_useCurrency ? 1 : _wantQuantity),
        wantItemCategory: wantedTypeLabel,
        wantItemVariant: _wantStyle,
        touchingTags: _tradeType == MarketTradeType.touching
            ? _buildTouchingTagsForSave()
            : const <String>[],
        entryFeeText: '무료',
        isMine: true,
        dimmed: false,
        description: _memoController.text.trim(),
        tradeType: _tradeType,
        moveType: _moveType,
        oneWayOffer: oneWayOffer,
        coverImageUrl: mergedCoverImage,
        updatedAt: DateTime.now(),
      );
      await notifier.updateOffer(offer);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
    });
    Navigator.of(context).pop(true);
  }

  Future<IslandProfile?> _loadSelectedIslandForOwner(String uid) async {
    if (uid.isEmpty) {
      return null;
    }
    try {
      final islands = await ref.read(
        _marketTradeRegisterIslandsProvider(uid).future,
      );
      final primaryIslandId = await ref.read(
        _marketTradeRegisterPrimaryIslandIdProvider(uid).future,
      );
      return _resolveSelectedIslandForMarketTrade(
        islands: islands,
        primaryIslandId: primaryIslandId,
      );
    } catch (_) {
      // 유지보수 포인트:
      // 섬 조회 실패 시에도 거래 등록은 막지 않고 안전한 기본값으로 저장합니다.
      return null;
    }
  }

  String _resolveOwnerName(IslandProfile? selectedIsland) {
    final representativeName = (selectedIsland?.representativeName ?? '')
        .trim();
    if (representativeName.isNotEmpty) {
      return representativeName;
    }

    final islandName = (selectedIsland?.islandName ?? '').trim();
    if (islandName.isNotEmpty) {
      return islandName;
    }
    return '대표 주민';
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
    // 유지보수 포인트:
    // 주민/레시피(문자열 변형 포함)에서는 만지작을 숨기고,
    // 나머지(아이템/벽지/패션/재화 등)에서는 만지작을 노출합니다.
    if (!isVillagerCategory && !isRecipeCategory) {
      types.add(MarketTradeType.touching);
    }

    if (isRecipeCategory) {
      types.add(MarketTradeType.crafting);
    }
    return types;
  }

  String _resolveItemTypeLabel({
    required String? category,
    required String imageUrl,
    required String name,
  }) {
    if (_isCurrencyLike(name: name, imageUrl: imageUrl)) {
      return '재화';
    }
    final normalized = (category ?? '').replaceAll(' ', '');
    if (normalized.contains('주민')) {
      return '주민';
    }
    if (normalized.contains('레시피') || normalized.contains('DIY')) {
      return '레시피';
    }
    return '아이템';
  }

  bool _isCurrencyLike({required String name, required String imageUrl}) {
    if (imageUrl.contains('icon_recipe_scroll')) {
      return true;
    }
    if (imageUrl.contains('Nook_Miles_Ticket')) {
      return true;
    }
    return name.contains('벨') ||
        name.contains('마일 여행권') ||
        name.contains('마일 이용권');
  }

  String _resolveCurrencyImageUrl(String label) {
    final normalizedLabel = label.trim();
    if (normalizedLabel == '마일 여행권' || normalizedLabel == '마일 이용권') {
      return _nookMilesTicketImageUrl;
    }
    return 'assets/images/icon_recipe_scroll.png';
  }

  String _formatCurrencyDisplay({required String label, required int amount}) {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) {
      return '재화 * $amount';
    }
    return '$normalizedLabel * $amount';
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

  List<CatalogItem> _buildTouchingItemsFromTags(List<String> tags) {
    final items = <CatalogItem>[];
    for (final tag in tags) {
      final normalized = tag.trim();
      if (normalized.isEmpty) {
        continue;
      }
      items.add(
        CatalogItem(
          id: 'touching_${normalized.hashCode}',
          category: _touchingCategoryFromTag(normalized),
          name: normalized,
          imageUrl: '',
          tags: const <String>[],
        ),
      );
    }
    return items;
  }

  String _touchingCategoryFromTag(String tag) {
    if (tag.contains('가구')) {
      return '가구';
    }
    if (tag.contains('벽지') || tag.contains('천장')) {
      return '벽지';
    }
    if (tag.contains('바닥') || tag.contains('러그')) {
      return '바닥/러그';
    }
    if (tag.contains('음악')) {
      return '음악/음향';
    }
    if (tag.contains('패션') || tag.contains('의류')) {
      return '패션';
    }
    return '아이템';
  }

  List<String> _buildTouchingTagsForSave() {
    final tags = <String>{};
    for (final item in _touchingItems) {
      final normalizedCategory = item.category.replaceAll(' ', '');
      if (normalizedCategory.contains('가구')) {
        tags.add('가구');
        continue;
      }
      if (normalizedCategory.contains('벽지') ||
          normalizedCategory.contains('천장')) {
        tags.add('벽지/천장');
        continue;
      }
      if (normalizedCategory.contains('바닥') ||
          normalizedCategory.contains('러그')) {
        tags.add('바닥/러그');
        continue;
      }
      if (normalizedCategory.contains('음악')) {
        tags.add('음악/음향');
        continue;
      }
      if (normalizedCategory.contains('패션') ||
          normalizedCategory.contains('의상')) {
        tags.add('패션/의류');
        continue;
      }
      final fallback = item.name.trim();
      if (fallback.isNotEmpty) {
        tags.add(fallback);
      }
    }
    return tags.toList(growable: false);
  }
}
