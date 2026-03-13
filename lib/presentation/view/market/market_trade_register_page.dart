import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nook_lounge_app/presentation/view/common/app_ink_well.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/core/utils/touching_item_tag_codec.dart';
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
  static const String _bellImageUrl =
      'https://dodo.ac/np/images/1/1e/99k_Bells_NH_Inv_Icon.png';
  static const String _nookMilesTicketImageUrl =
      'https://dodo.ac/np/images/f/f5/Nook_Miles_Ticket_NH_Icon.png';
  static const int _touchingPreviewLimit = 5;
  static const int _touchingCategoryBadgeThreshold = 5;
  static const List<MapEntry<String, String>> _touchingPickerCategories =
      <MapEntry<String, String>>[
        MapEntry<String, String>('all', '전체'),
        MapEntry<String, String>('furniture', '가구'),
        MapEntry<String, String>('wallpaper', '벽지'),
        MapEntry<String, String>('fashion', '의상'),
      ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  int _step = 0;
  MarketTradeType _tradeType = MarketTradeType.sharing;
  MarketMoveType _moveType = MarketMoveType.visitor;
  CatalogItem? _offeredItem;
  CatalogItem? _wantedItem;
  List<CatalogItem> _touchingItems = <CatalogItem>[];
  bool _isTouchingItemsExpanded = false;
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
  bool get _isOneWayTrade =>
      _tradeType == MarketTradeType.sharing ||
      _tradeType == MarketTradeType.touching;
  bool get _canUseOfferCurrency => _tradeType != MarketTradeType.crafting;
  bool get _isTouchingRequestFlow =>
      _tradeType == MarketTradeType.touching &&
      _moveType == MarketMoveType.visitor;

  bool get _canMoveFromOfferStep {
    if (_useOfferCurrency) {
      return _canUseOfferCurrency &&
          _isTradeTypeSupportedForCategory(
            tradeType: _tradeType,
            category: '재화',
          );
    }
    final offeredItem = _offeredItem;
    if (offeredItem == null) {
      return false;
    }
    return _isTradeTypeSupportedForCategory(
      tradeType: _tradeType,
      category: offeredItem.category,
    );
  }

  String get _offerItemPickerTitle {
    return switch (_tradeType) {
      MarketTradeType.touching =>
        _isTouchingRequestFlow ? '드릴 아이템 검색' : '입장료 아이템 검색',
      MarketTradeType.crafting => '레시피 검색',
      _ => '아이템 검색',
    };
  }

  String get _offerItemPickerInitialCategoryKey {
    return switch (_tradeType) {
      MarketTradeType.crafting => 'recipe',
      _ => 'all',
    };
  }

  List<String> get _offerItemPickerAllowedCategories {
    return switch (_tradeType) {
      MarketTradeType.crafting => const <String>['레시피'],
      _ => const <String>[],
    };
  }

  List<String> get _offerItemPickerExcludedCategories {
    return switch (_tradeType) {
      MarketTradeType.touching => const <String>['레시피', '주민'],
      _ => const <String>[],
    };
  }

  String get _touchingOfferTitle =>
      _isTouchingRequestFlow ? '드릴 보답을 설정해주세요.' : '입장료를 설정해주세요.';

  String get _touchingOfferGuide => _isTouchingRequestFlow
      ? '원하는 만지작 글이라면 드릴 아이템이나 재화를 먼저 정해보세요.'
      : '만지작을 열 때 받을 입장료를 현재 조건에 맞게 정해보세요.';

  String get _touchingOfferSearchLabel =>
      _isTouchingRequestFlow ? '드릴 아이템 검색하기' : '입장료 아이템 검색하기';

  String get _touchingTitleHint =>
      _isTouchingRequestFlow ? 'ex. 의상 만지작 구해요.' : 'ex. 의상 만지작 열어요.';

  String get _touchingSelectionTitle =>
      _isTouchingRequestFlow ? '원하는 만지작 아이템을 선택해주세요.' : '만지작할 아이템을 선택해주세요.';

  String get _touchingSelectionGuide => _isTouchingRequestFlow
      ? '상대가 만지작해 줄 아이템을 여러 개 선택할 수 있어요.'
      : '아이템을 여러 개 선택할 수 있어요.';

  String _defaultTouchingTitleForMoveType(MarketMoveType moveType) {
    return moveType == MarketMoveType.host ? '만지작 열어요' : '만지작 구해요';
  }

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

    final bool oneWayOffer = initialOffer.oneWayOffer || _isOneWayTrade;
    if (oneWayOffer) {
      _useCurrency = false;
      _wantedItem = null;
      _wantQuantity = 1;
      _wantStyle = '기본';
      if (!_useCurrency) {
        _currencyAmount = 1;
      }
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
      appBar: AppBar(
        title: Text(
          _isEditMode ? '거래 수정하기' : '거래를 등록하기',
          style: AppTextStyles.appBarHomeTitle,
        ),
      ),
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
    final VoidCallback? onPreviousPressed = hasPrevious
        ? () => setState(() {
            // 유지보수 포인트:
            // 나눔은 거래 상세(step3)를 건너뛰고 바로 최종 확인(step4)으로 이동하므로
            // "이전"도 드리는 것 선택(step2)으로 정확히 복귀시킵니다.
            if (_step == 3 && _tradeType == MarketTradeType.sharing) {
              _step = 1;
              return;
            }
            _step = _step - 1;
          })
        : null;

    final VoidCallback? onPrimaryPressed = switch (_step) {
      0 => () => setState(() => _step = 1),
      1 =>
        _canMoveFromOfferStep
            ? () => setState(() {
                // 유지보수 포인트:
                // 거래 유형을 먼저 고른 뒤에는 현재 타입 기준으로
                // 드리는 것(step2)을 검증한 후 다음 단계를 분기합니다.
                _step = _tradeType == MarketTradeType.sharing ? 3 : 2;
              })
            : null,
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
                      onPressed: onPreviousPressed,
                      style: OutlinedButton.styleFrom(
                        overlayColor: Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
                        backgroundColor: AppColors.navBackground,
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.borderDefault),
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
                        overlayColor: Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
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
                  overlayColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
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
    final guideText = switch (_tradeType) {
      MarketTradeType.crafting => '거래 유형을 먼저 고르면 다음 단계에서 레시피만 보여드려요.',
      MarketTradeType.touching => '만지작을 열지, 내가 구할지 먼저 정한 뒤 흐름에 맞게 입력할 수 있어요.',
      _ => '거래 유형에 맞춰 다음 단계의 선택지를 자동으로 조정해드릴게요.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '어떤 거래를 등록할까요?',
          style: AppTextStyles.bodyPrimaryHeavy.copyWith(fontSize: 24),
        ),
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
        ...MarketTradeType.values.map((type) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildTradeTypeTile(type),
          );
        }),
      ],
    );
  }

  Widget _buildStepTwo() {
    final isVillager = _isVillagerOffer;
    final isOfferCurrencySelected = _canUseOfferCurrency && _useOfferCurrency;
    final showTitleInStepTwo = switch (_tradeType) {
      MarketTradeType.touching => false,
      MarketTradeType.sharing => true,
      _ => !isOfferCurrencySelected,
    };
    final showExtraItemFields = !isOfferCurrencySelected && !isVillager;
    final showDetailSection = showTitleInStepTwo || showExtraItemFields;
    final titleText = switch (_tradeType) {
      MarketTradeType.sharing =>
        isVillager
            ? '어떤 주민을 나눔할까요?'
            : (isOfferCurrencySelected ? '어떤 재화를 나눔할까요?' : '무엇을 나눔할까요?'),
      MarketTradeType.exchange =>
        isVillager
            ? '어떤 주민을 거래하시겠어요?'
            : (isOfferCurrencySelected ? '어떤 재화를 드릴까요?' : '무엇을 드릴까요?'),
      MarketTradeType.touching => _touchingOfferTitle,
      MarketTradeType.crafting => '어떤 레시피를 제작 중인가요?',
    };
    final guideText = switch (_tradeType) {
      MarketTradeType.sharing =>
        isOfferCurrencySelected
            ? '보유한 재화를 나눔으로 등록할 수 있어요.'
            : isVillager
            ? '주민 검색을 통해 나눔할 주민을 선택해보세요.'
            : '아이템 검색을 통해 나눔할 항목을 선택해보세요.',
      MarketTradeType.exchange =>
        isOfferCurrencySelected
            ? '재화를 드리고 원하는 아이템이나 재화를 받아보세요.'
            : isVillager
            ? '주민 검색을 통해 거래할 주민을 선택해보세요.'
            : '아이템 검색을 통해 드릴 항목을 선택해보세요.',
      MarketTradeType.touching =>
        isOfferCurrencySelected
            ? _isTouchingRequestFlow
                  ? '재화를 보답으로 제안할 수 있고, 0으로 두면 무료 요청으로도 올릴 수 있어요.'
                  : '재화 수량을 0으로 두면 무료 입장으로도 등록할 수 있어요.'
            : _touchingOfferGuide,
      MarketTradeType.crafting => '현재 조건을 유지하기 위해 레시피만 선택할 수 있어요.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          titleText,
          style: AppTextStyles.bodyPrimaryHeavy.copyWith(fontSize: 24),
        ),
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
        if (_tradeType == MarketTradeType.touching) ...<Widget>[
          _buildTouchingDirectionSelector(),
          const SizedBox(height: 16),
        ],
        if (_canUseOfferCurrency) ...<Widget>[
          _buildOfferModeToggle(),
          const SizedBox(height: 14),
        ],
        if (isOfferCurrencySelected)
          _buildOfferCurrencyInput()
        else
          _buildSearchSelectBox(
            label:
                _offeredItem?.name ??
                (_tradeType == MarketTradeType.touching
                    ? _touchingOfferSearchLabel
                    : _tradeType == MarketTradeType.crafting
                    ? '레시피 검색하기'
                    : '아이템 검색하기'),
            selectedItem: _offeredItem,
            onTap: _openOfferItemPicker,
          ),
        if (showDetailSection) ...<Widget>[
          const SizedBox(height: 12),
          _buildSectionDivider('상세 정보'),
          const SizedBox(height: 12),
          if (showTitleInStepTwo)
            _buildTextField(
              label: '제목',
              hint: _tradeType == MarketTradeType.touching
                  ? _touchingTitleHint
                  : _tradeType == MarketTradeType.crafting
                  ? 'ex. 장미 침대 제작 중이에요.'
                  : 'ex. 아이언우드 수납장 교환해요.',
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

  Widget _buildStepThree() {
    if (_tradeType == MarketTradeType.touching) {
      return _buildTouchingStepThree();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _tradeType == MarketTradeType.crafting
              ? '무엇을 받고 싶으세요?'
              : '무엇과 교환할까요?',
          style: AppTextStyles.bodyPrimaryHeavy,
        ),
        const SizedBox(height: 10),
        Text(
          _tradeType == MarketTradeType.crafting
              ? '제작 보답으로 받을 아이템이나 재화를 선택해주세요.'
              : '구체적인 아이템이나 재화를 선택해주세요.',
          style: AppTextStyles.bodyHintStrong,
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

  Widget _buildTouchingStepThree() {
    final hasItems = _touchingItems.isNotEmpty;
    final touchingDisplayChips = _buildTouchingDisplayChips();
    final canExpandTouchingItems =
        touchingDisplayChips.length > _touchingPreviewLimit;
    final visibleTouchingDisplayChips =
        (_isTouchingItemsExpanded || !canExpandTouchingItems)
        ? touchingDisplayChips
        : touchingDisplayChips
              .take(_touchingPreviewLimit)
              .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _touchingSelectionTitle,
          style: AppTextStyles.bodyPrimaryHeavy.copyWith(fontSize: 24),
        ),

        const SizedBox(height: 18),
        Text(_touchingSelectionGuide, style: AppTextStyles.bodyHintStrong),
        const SizedBox(height: 20),
        _buildTextField(
          label: '제목',
          hint: _touchingTitleHint,
          controller: _titleController,
        ),
        const SizedBox(height: 20),

        Text('카테고리로 빠르게 추가', style: AppTextStyles.captionMuted),
        const SizedBox(height: 8),
        Row(
          spacing: 8,
          children: _touchingPickerCategories
              .map(
                (entry) => AppInkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () =>
                      _openTouchingItemPicker(initialCategoryKey: entry.key),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.catalogChipBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      entry.value,
                      style: AppTextStyles.captionPrimaryHeavy,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 14),
        AppInkWell(
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
                        children: visibleTouchingDisplayChips
                            .map(_buildTouchingSelectionChip)
                            .toList(growable: false),
                      ),
                      if (canExpandTouchingItems) ...<Widget>[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isTouchingItemsExpanded =
                                    !_isTouchingItemsExpanded;
                              });
                            },
                            icon: Icon(
                              _isTouchingItemsExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 18,
                              color: AppColors.accentDeepOrange,
                            ),
                            label: Text(
                              _isTouchingItemsExpanded
                                  ? '접기'
                                  : '더보기 (+${touchingDisplayChips.length - visibleTouchingDisplayChips.length}개)',
                              style: AppTextStyles.captionWithColor(
                                AppColors.accentDeepOrange,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
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
    final isTouchingSummary = _tradeType == MarketTradeType.touching;
    final offerName = _useOfferCurrency
        ? _formatCurrencyDisplay(
            label: _offerCurrencyLabel,
            amount: _offerCurrencyAmount,
          )
        : (_offeredItem?.name ?? '');
    final offerImage = _useOfferCurrency
        ? _resolveCurrencyImageUrl(_offerCurrencyLabel)
        : (_offeredItem?.imageUrl ?? '');
    final offerQuantity = _useOfferCurrency ? 1 : _offerQuantity;
    final offerTypeLabel = _resolveItemTypeLabel(
      category: _useOfferCurrency ? '재화' : _offeredItem?.category,
      imageUrl: offerImage,
      name: offerName,
    );

    final wantName = _useCurrency
        ? _formatCurrencyDisplay(label: _currencyLabel, amount: _currencyAmount)
        : (_wantedItem?.name ?? '');
    final wantImage = _useCurrency
        ? _resolveCurrencyImageUrl(_currencyLabel)
        : (_wantedItem?.imageUrl ?? '');
    final wantQuantity = _useCurrency ? 1 : _wantQuantity;
    final wantTypeLabel = _resolveItemTypeLabel(
      category: _useCurrency ? '재화' : _wantedItem?.category,
      imageUrl: wantImage,
      name: wantName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '마지막으로 확인해주세요.',
          style: AppTextStyles.bodyPrimaryHeavy.copyWith(fontSize: 24),
        ),
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
                  quantity: offerQuantity,
                  categoryLabel: offerTypeLabel,
                ),
              ),
              _buildTradeDirectionIndicator(),
              Expanded(
                child: isTouchingSummary
                    ? _buildTouchingSummaryItem()
                    : _buildSummaryItem(
                        imageUrl: wantImage,
                        name: wantName.isEmpty ? '-' : wantName,
                        quantity: wantQuantity,
                        categoryLabel: wantTypeLabel,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          isTouchingSummary ? '방문 방향을 확인해주세요.' : '어떻게 거래할까요?',
          style: AppTextStyles.bodyPrimaryHeavy,
        ),
        const SizedBox(height: 10),
        if (isTouchingSummary) ...<Widget>[
          Text(
            '만지작 열기/구하기에 따라 누가 코드를 보내는지 달라져요.',
            style: AppTextStyles.bodyHintStrong,
          ),
          const SizedBox(height: 10),
        ],
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
                    child: AppInkWell(
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
                            width: selected ? 3 : 1,
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
                            const SizedBox(height: 8),
                            Text(
                              _tradeType == MarketTradeType.touching
                                  ? (moveType == MarketMoveType.visitor
                                        ? '상대 섬에서 만지작해요'
                                        : '내 섬에서 만지작을 열어요')
                                  : (moveType == MarketMoveType.visitor
                                        ? '상대방 섬으로'
                                        : '나의 섬으로'),
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
        const SizedBox(height: 22),
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
    return AppInkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _applyTradeTypeSelection(type),
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
                  SizedBox(height: 7),
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

  Widget _buildTouchingDirectionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('만지작 방향', style: AppTextStyles.bodyPrimaryHeavy),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildTouchingDirectionTile(
                moveType: MarketMoveType.host,
                title: '만지작을 열어요',
                description: '내 섬을 열고 입장료를 받을게요.',
                icon: Icons.home_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTouchingDirectionTile(
                moveType: MarketMoveType.visitor,
                title: '만지작을 구해요',
                description: '상대 섬으로 가서 만지작을 받고 싶어요.',
                icon: Icons.flight_takeoff_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTouchingDirectionTile({
    required MarketMoveType moveType,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final selected = _moveType == moveType;
    return AppInkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _applyTouchingMoveTypeSelection(moveType),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 20,
              backgroundColor: selected
                  ? AppColors.badgeBlueBg
                  : AppColors.catalogChipBg,
              child: Icon(
                icon,
                color: selected ? AppColors.badgeBlueText : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.bodyPrimaryHeavy),
            const SizedBox(height: 8),
            Text(description, style: AppTextStyles.captionMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferModeToggle() {
    return _buildItemCurrencyToggle(
      isCurrencySelected: _canUseOfferCurrency && _useOfferCurrency,
      onSelect: (useCurrency) {
        if (_useOfferCurrency == useCurrency) {
          return;
        }
        setState(() {
          _useOfferCurrency = useCurrency;
        });
      },
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
                child: AppInkWell(
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
    return AppInkWell(
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
    return _buildItemCurrencyToggle(
      isCurrencySelected: _useCurrency,
      onSelect: (useCurrency) {
        if (_useCurrency == useCurrency) {
          return;
        }
        setState(() => _useCurrency = useCurrency);
      },
    );
  }

  Widget _buildItemCurrencyToggle({
    required bool isCurrencySelected,
    required ValueChanged<bool> onSelect,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.catalogSegmentBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth - 8;
          final highlightWidth = availableWidth > 0 ? availableWidth / 2 : 0.0;
          return Stack(
            children: <Widget>[
              AnimatedAlign(
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOutCubic,
                alignment: isCurrencySelected
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: highlightWidth,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        offset: Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildItemCurrencyModeButton(
                      label: '아이템',
                      selected: !isCurrencySelected,
                      onTap: () => onSelect(false),
                    ),
                  ),
                  Expanded(
                    child: _buildItemCurrencyModeButton(
                      label: '재화',
                      selected: isCurrencySelected,
                      onTap: () => onSelect(true),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemCurrencyModeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: AppColors.transparent,
        child: AppInkWell(
          borderRadius: BorderRadius.circular(999),
          splashFactory: NoSplash.splashFactory,
          highlightColor: AppColors.transparent,
          onTap: onTap,
          child: Center(
            // 유지보수 포인트:
            // 글자 스타일 전환은 즉시 반영해서 "이전/현재 탭 동시 깜빡임" 체감을 줄입니다.
            child: Text(
              label,
              style: AppTextStyles.labelWithColor(
                selected ? AppColors.textPrimary : AppColors.textMuted,
                weight: FontWeight.w800,
              ),
            ),
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
                child: AppInkWell(
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
    return AppInkWell(
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
    required int quantity,
    required String categoryLabel,
  }) {
    final displayName = name.trim().isEmpty ? '-' : name.trim();
    final displayQuantity = quantity <= 0 ? 0 : quantity;
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
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyPrimaryHeavy,
        ),
        const SizedBox(height: 8),
        _buildSummaryItemTypeBadge(categoryLabel),
        if (displayQuantity > 1) ...<Widget>[
          const SizedBox(height: 4),
          Text('X$displayQuantity', style: AppTextStyles.bodyPrimaryHeavy),
        ],
      ],
    );
  }

  Widget _buildSummaryItemTypeBadge(String label) {
    final normalized = label.trim();
    Color bgColor = AppColors.catalogChipBg;
    Color textColor = AppColors.textMuted;
    IconData icon = Icons.inventory_2_rounded;

    switch (normalized) {
      case '재화':
        bgColor = AppColors.marketBlueBadgeBg;
        textColor = AppColors.marketBlueBadgeText;
        icon = Icons.paid_rounded;
      case '레시피':
        bgColor = AppColors.badgeYellowBg;
        textColor = AppColors.badgeYellowText;
        icon = Icons.description_rounded;
      case '주민':
        bgColor = AppColors.badgeMintBg;
        textColor = AppColors.badgeMintText;
        icon = Icons.person_rounded;
      case '만지작':
        bgColor = AppColors.badgePurpleBg;
        textColor = AppColors.badgePurpleText;
        icon = Icons.touch_app_rounded;
      case '아이템':
      default:
        bgColor = AppColors.badgeBeigeBg;
        textColor = AppColors.badgeBeigeText;
        icon = Icons.inventory_2_rounded;
    }

    return IntrinsicWidth(
      child: Container(
        constraints: const BoxConstraints(minWidth: 60, minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 3),
            Text(
              normalized.isEmpty ? '아이템' : normalized,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.captionWithColor(
                textColor,
                weight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeDirectionIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        Icons.sync_alt_outlined,
        size: 30,
        color: AppColors.textAccent,
      ),
    );
  }

  Widget _buildTouchingSummaryItem() {
    final previewItems = _touchingItems.take(6).toList(growable: false);
    final hasOverflow = _touchingItems.length > previewItems.length;

    return Column(
      children: <Widget>[
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.catalogChipBg,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(6),
          child: previewItems.isEmpty
              ? const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textHint,
                )
              : GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: previewItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemBuilder: (context, index) {
                    final item = previewItems[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        color: AppColors.bgCard,
                        padding: const EdgeInsets.all(2),
                        child: _buildImage(item.imageUrl, fit: BoxFit.contain),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        Text(
          _isTouchingRequestFlow
              ? '원하는 만지작 ${_touchingItems.length}개'
              : '만지작 ${_touchingItems.length}개',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyPrimaryHeavy,
        ),
        const SizedBox(height: 4),
        _buildSummaryItemTypeBadge('아이템'),
        if (hasOverflow)
          Text(
            '+${_touchingItems.length - previewItems.length}',
            style: AppTextStyles.captionMuted,
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

    return AppInkWell(
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
                AppInkWell(
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
    return AppInkWell(
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
    return AppInkWell(
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
    return AppInkWell(
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
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        var focused = false;
        String? errorText;
        var inputValue = '$initialValue';

        void submit(StateSetter setModalState) {
          final parsed = int.tryParse(inputValue.trim());
          if (parsed == null) {
            setModalState(() {
              errorText = '숫자만 입력해 주세요.';
            });
            return;
          }
          if (parsed < min || parsed > max) {
            setModalState(() {
              errorText = '$min ~ $max 범위로 입력해 주세요.';
            });
            return;
          }
          Navigator.of(dialogContext).pop(parsed);
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            final borderColor = errorText != null
                ? AppColors.badgeRedText
                : focused
                ? AppColors.accentDeepOrange
                : AppColors.borderDefault;
            return Dialog(
              backgroundColor: AppColors.white,
              surfaceTintColor: AppColors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal + AppSpacing.modalOuter,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.modalInner,
                  AppSpacing.modalInner,
                  AppSpacing.modalInner,
                  18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppTextStyles.dialogTitleCompact),
                    const SizedBox(height: 8),
                    Text(
                      '$min ~ $max 범위로 입력해 주세요.',
                      style: AppTextStyles.captionMuted,
                    ),
                    const SizedBox(height: 12),
                    Focus(
                      onFocusChange: (hasFocus) {
                        setModalState(() {
                          focused = hasFocus;
                        });
                      },
                      child: Container(
                        height: 62,
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Center(
                          child: TextFormField(
                            initialValue: '$initialValue',
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            textInputAction: TextInputAction.done,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: AppTextStyles.bodyPrimaryHeavy,
                            decoration: InputDecoration(
                              hintText: '$initialValue',
                              hintStyle: AppTextStyles.bodyHintStrong,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (value) {
                              inputValue = value;
                              if (errorText == null) {
                                return;
                              }
                              setModalState(() {
                                errorText = null;
                              });
                            },
                            onFieldSubmitted: (_) => submit(setModalState),
                          ),
                        ),
                      ),
                    ),
                    if (errorText != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: AppTextStyles.captionWithColor(
                          AppColors.badgeRedText,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              overlayColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                              minimumSize: const Size.fromHeight(54),
                              side: const BorderSide(
                                color: AppColors.borderStrong,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              '취소',
                              style: AppTextStyles.dialogButtonOutline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => submit(setModalState),
                            style: FilledButton.styleFrom(
                              overlayColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                              backgroundColor: AppColors.modalPrimaryAction,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              '확인',
                              style: AppTextStyles.dialogButtonPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
        return '아이템 만지작을 열거나 구해요.';
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

  void _applyTradeTypeSelection(MarketTradeType type) {
    setState(() {
      final previousTradeType = _tradeType;
      _tradeType = type;

      // 유지보수 포인트:
      // 거래 유형을 먼저 고르는 구조로 바뀌었기 때문에,
      // 이후 단계에서 숨겨질 수 있는 입력값은 여기서 선제 정리합니다.
      if (type == MarketTradeType.sharing || type == MarketTradeType.touching) {
        _resetWantedSelection();
      }
      if (type == MarketTradeType.crafting) {
        _useOfferCurrency = false;
      }
      if (type == MarketTradeType.touching &&
          previousTradeType != MarketTradeType.touching) {
        // 유지보수 포인트:
        // 만지작은 기존 등록 플로우가 "열기" 기준이었으므로,
        // 처음 진입할 때는 호스트 플로우를 기본값으로 유지합니다.
        _moveType = MarketMoveType.host;
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = _defaultTouchingTitleForMoveType(_moveType);
        }
      }
      if (_offeredItem != null &&
          !_isTradeTypeSupportedForCategory(
            tradeType: type,
            category: _offeredItem!.category,
          )) {
        _resetOfferedItemSelection();
      }
    });
  }

  void _applyTouchingMoveTypeSelection(MarketMoveType moveType) {
    if (_tradeType != MarketTradeType.touching) {
      return;
    }
    if (_moveType == moveType) {
      return;
    }
    setState(() {
      final previousDefaultTitle = _defaultTouchingTitleForMoveType(_moveType);
      final currentTitle = _titleController.text.trim();
      _moveType = moveType;
      if (currentTitle.isEmpty || currentTitle == previousDefaultTitle) {
        _titleController.text = _defaultTouchingTitleForMoveType(moveType);
      }
    });
  }

  void _resetWantedSelection() {
    _useCurrency = false;
    _wantedItem = null;
    _wantQuantity = 1;
    _wantStyle = '기본';
    _currencyAmount = 1;
  }

  void _resetOfferedItemSelection() {
    _offeredItem = null;
    _offerQuantity = 1;
    _offerStyle = '기본';
  }

  bool _isTradeTypeSupportedForCategory({
    required MarketTradeType tradeType,
    required String? category,
  }) {
    return _availableTradeTypesForCategory(category).contains(tradeType);
  }

  String _suggestTitleForOfferedSelection(CatalogItem selected) {
    if (selected.category == '주민') {
      return _tradeType == MarketTradeType.sharing
          ? '${selected.name} 주민 나눔해요'
          : '${selected.name} 주민 거래해요';
    }
    return switch (_tradeType) {
      MarketTradeType.sharing => '${selected.name} 나눔해요',
      MarketTradeType.exchange => '${selected.name} 교환해요',
      MarketTradeType.touching => _defaultTouchingTitleForMoveType(_moveType),
      MarketTradeType.crafting => '${selected.name} 제작 중이에요',
    };
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
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        child: MarketItemPickerSheet(
          title: _offerItemPickerTitle,
          initialCategoryKey: _offerItemPickerInitialCategoryKey,
          allowedCategories: _offerItemPickerAllowedCategories,
          excludedCategories: _offerItemPickerExcludedCategories,
        ),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _useOfferCurrency = false;
      _offeredItem = selected;
      _offerStyle = _resolveInitialStyle(selected);
      _titleController.text = _suggestTitleForOfferedSelection(selected);
      if (selected.category == '주민') {
        _offerQuantity = 1;
        _offerStyle = '기본';
      }
    });
  }

  Future<void> _openTouchingItemPicker({
    String initialCategoryKey = 'all',
  }) async {
    final selected = await showModalBottomSheet<List<CatalogItem>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        child: MarketItemPickerSheet(
          title: _isTouchingRequestFlow ? '원하는 만지작 아이템 검색' : '만지작 아이템 검색',
          initialCategoryKey: initialCategoryKey,
          touchingOnlyCategories: true,
          multiSelectEnabled: true,
          initialSelectedItemIds: _touchingItems
              .map((item) => item.id)
              .toList(growable: false),
        ),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _touchingItems = selected;
      // 유지보수 포인트:
      // 선택 목록이 갱신될 때는 기본 5개 미리보기 상태로 되돌려
      // 긴 목록에서도 화면 높이가 갑자기 커지는 것을 방지합니다.
      _isTouchingItemsExpanded = false;
    });
  }

  void _removeTouchingItem(String itemId) {
    setState(() {
      _touchingItems = _touchingItems
          .where((item) => item.id != itemId)
          .toList(growable: false);
      if (_touchingItems.length <= _touchingPreviewLimit) {
        _isTouchingItemsExpanded = false;
      }
    });
  }

  List<
    ({String label, String? itemId, String categoryLabel, bool isCategoryBadge})
  >
  _buildTouchingDisplayChips() {
    // 유지보수 포인트:
    // 카테고리별 선택 수가 많아지면 개별 칩 대신 카테고리 배지 1개로 압축해
    // 긴 목록에서도 레이아웃이 과도하게 늘어나지 않도록 관리합니다.
    if (_touchingItems.isEmpty) {
      return <
        ({
          String label,
          String? itemId,
          String categoryLabel,
          bool isCategoryBadge,
        })
      >[];
    }

    final categoryCounts = <String, int>{};
    for (final item in _touchingItems) {
      final categoryLabel = _resolveTouchingCategoryBadgeLabel(item.category);
      categoryCounts[categoryLabel] = (categoryCounts[categoryLabel] ?? 0) + 1;
    }

    final renderedCategoryBadges = <String>{};
    final chips =
        <
          ({
            String label,
            String? itemId,
            String categoryLabel,
            bool isCategoryBadge,
          })
        >[];
    for (final item in _touchingItems) {
      final categoryLabel = _resolveTouchingCategoryBadgeLabel(item.category);
      final count = categoryCounts[categoryLabel] ?? 0;
      if (count > _touchingCategoryBadgeThreshold) {
        if (!renderedCategoryBadges.add(categoryLabel)) {
          continue;
        }
        chips.add((
          label: '$categoryLabel $count개',
          itemId: null,
          categoryLabel: categoryLabel,
          isCategoryBadge: true,
        ));
        continue;
      }
      chips.add((
        label: item.name,
        itemId: item.id,
        categoryLabel: categoryLabel,
        isCategoryBadge: false,
      ));
    }
    return chips;
  }

  Widget _buildTouchingSelectionChip(
    ({String label, String? itemId, String categoryLabel, bool isCategoryBadge})
    chip,
  ) {
    final isCategoryBadge = chip.isCategoryBadge;
    return Container(
      constraints: const BoxConstraints(minHeight: 28, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isCategoryBadge
            ? AppColors.catalogChipSelectedBg
            : AppColors.catalogChipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isCategoryBadge
              ? AppColors.accentDeepOrange
              : AppColors.borderDefault,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            chip.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: isCategoryBadge
                ? AppTextStyles.captionWithColor(
                    AppColors.accentDeepOrange,
                    weight: FontWeight.w800,
                  )
                : AppTextStyles.captionPrimaryHeavy,
          ),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (isCategoryBadge) {
                _removeTouchingCategoryItems(chip.categoryLabel);
                return;
              }
              final itemId = chip.itemId;
              if (itemId == null || itemId.isEmpty) {
                return;
              }
              _removeTouchingItem(itemId);
            },
            child: Icon(
              Icons.close_rounded,
              size: 15,
              color: isCategoryBadge
                  ? AppColors.accentDeepOrange
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _removeTouchingCategoryItems(String categoryLabel) {
    setState(() {
      _touchingItems = _touchingItems
          .where(
            (item) =>
                _resolveTouchingCategoryBadgeLabel(item.category) !=
                categoryLabel,
          )
          .toList(growable: false);
      if (_touchingItems.length <= _touchingPreviewLimit) {
        _isTouchingItemsExpanded = false;
      }
    });
  }

  String _resolveTouchingCategoryBadgeLabel(String category) {
    // 유지보수 포인트:
    // 만지작 카테고리 표시는 선택 UI/요약 UI/저장 태그가 서로 어긋나지 않도록
    // 단일 정규화 규칙으로 유지합니다.
    final normalizedCategory = category.replaceAll(' ', '');
    if (normalizedCategory.contains('가구')) {
      return '가구';
    }
    if (normalizedCategory.contains('벽지') ||
        normalizedCategory.contains('천장')) {
      return '벽지';
    }
    if (normalizedCategory.contains('바닥') ||
        normalizedCategory.contains('러그')) {
      return '바닥/러그';
    }
    if (normalizedCategory.contains('음악')) {
      return '음악/음향';
    }
    if (normalizedCategory.contains('패션') ||
        normalizedCategory.contains('의상')) {
      return '의상';
    }
    return category.trim().isEmpty ? '아이템' : category.trim();
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
                    title: Text(option, style: AppTextStyles.bodyPrimaryStrong),
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
    final bool oneWayOffer = _isOneWayTrade;
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
    final boardType = _mapBoardType(tradeType: _tradeType);
    final category = _mapCategory(
      catalogCategory: categorySource,
      tradeType: _tradeType,
    );
    final currentUid = ref.read(authRepositoryProvider).currentUserId ?? '';
    final selectedIsland = await _loadSelectedIslandForOwner(currentUid);
    final ownerName = _resolveOwnerName(selectedIsland);
    final ownerAvatarUrl = (selectedIsland?.imageUrl ?? '').trim();
    final title = _titleController.text.trim().isEmpty
        ? (_tradeType == MarketTradeType.touching
              ? _defaultTouchingTitleForMoveType(_moveType)
              : '$offeredName 거래')
        : _titleController.text.trim();
    final mergedCoverImage = _proofImagePath.trim().isNotEmpty
        ? _proofImagePath.trim()
        : (widget.initialOffer?.coverImageUrl ?? '');
    final entryFeeText = _resolveEntryFeeTextForSave();
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
        entryFeeText: entryFeeText,
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
        entryFeeText: entryFeeText,
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

  MarketBoardType _mapBoardType({required MarketTradeType tradeType}) {
    if (tradeType == MarketTradeType.touching) {
      return MarketBoardType.touching;
    }
    // 유지보수 포인트:
    // 만지작 보드 여부는 아이템 카테고리(가구/벽지 등)가 아니라
    // 사용자가 선택한 거래 타입으로만 결정해야 의도치 않은 분류를 막을 수 있습니다.
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
    return _bellImageUrl;
  }

  String _formatCurrencyDisplay({required String label, required int amount}) {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) {
      return '재화 * $amount';
    }
    return '$normalizedLabel * $amount';
  }

  String _resolveEntryFeeTextForSave() {
    if (_tradeType != MarketTradeType.touching) {
      return '무료';
    }
    if (_useOfferCurrency) {
      if (_offerCurrencyAmount <= 0) {
        return '무료';
      }
      return _formatCurrencyDisplay(
        label: _offerCurrencyLabel,
        amount: _offerCurrencyAmount,
      );
    }
    if (_offeredItem == null) {
      return '무료';
    }
    final quantity = _offerQuantity <= 0 ? 1 : _offerQuantity;
    return quantity > 1
        ? '${_offeredItem!.name} * $quantity'
        : _offeredItem!.name;
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
    final seenItemKeys = <String>{};
    for (final tag in tags) {
      final decoded = decodeTouchingItemTag(tag);
      if (decoded != null) {
        final itemId = decoded.id.isEmpty
            ? 'touching_${decoded.name.hashCode}'
            : decoded.id;
        if (!seenItemKeys.add(itemId)) {
          continue;
        }
        items.add(
          CatalogItem(
            id: itemId,
            category: decoded.category.isEmpty
                ? _touchingCategoryFromTag(decoded.name)
                : decoded.category,
            name: decoded.name,
            imageUrl: decoded.imageUrl,
            tags: const <String>[],
          ),
        );
        continue;
      }

      for (final token in tag.split(',')) {
        final normalized = token.trim();
        if (normalized.isEmpty) {
          continue;
        }
        final fallbackId = 'touching_${normalized.hashCode}';
        if (!seenItemKeys.add(fallbackId)) {
          continue;
        }
        items.add(
          CatalogItem(
            id: fallbackId,
            category: _touchingCategoryFromTag(normalized),
            name: normalized,
            imageUrl: '',
            tags: const <String>[],
          ),
        );
      }
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
    final tags = <String>[];
    final seenItemKeys = <String>{};
    for (final item in _touchingItems) {
      final itemId = item.id.trim().isEmpty
          ? 'touching_${item.name.hashCode}'
          : item.id.trim();
      if (!seenItemKeys.add(itemId)) {
        continue;
      }
      final encoded = encodeTouchingItemTag(
        id: itemId,
        name: item.name,
        imageUrl: item.imageUrl,
        category: item.category,
      );
      if (encoded.isNotEmpty) {
        tags.add(encoded);
        continue;
      }

      final fallbackName = item.name.trim();
      if (fallbackName.isNotEmpty) {
        tags.add(fallbackName);
      }
    }
    return tags;
  }
}
