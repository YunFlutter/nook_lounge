import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/core/constants/market_report_constants.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';

typedef MarketReportDraft = ({String reason, String detail});

typedef _MarketReportCategory = ({
  String label,
  List<String> detailReasons,
  bool requiresCustomInput,
});

enum _MarketReportStep { category, detail }

class MarketReportReasonPage extends StatefulWidget {
  const MarketReportReasonPage({super.key});

  static Future<MarketReportDraft?> show(BuildContext context) {
    return Navigator.of(context).push<MarketReportDraft>(
      MaterialPageRoute<MarketReportDraft>(
        builder: (_) => const MarketReportReasonPage(),
      ),
    );
  }

  @override
  State<MarketReportReasonPage> createState() => _MarketReportReasonPageState();
}

class _MarketReportReasonPageState extends State<MarketReportReasonPage> {
  // 유지보수 포인트:
  // 신고 사유 정책이 바뀌면 아래 카테고리/상세 사유 목록만 수정하면
  // 1차/2차 선택 UI가 자동으로 동기화됩니다.
  static const List<_MarketReportCategory> _categories =
      <_MarketReportCategory>[
        (
          label: '사기/허위 내용',
          detailReasons: <String>[
            '게시 내용이 사실과 다름',
            '잘못된 방문코드 공유',
            '거래 조건을 임의로 변경',
            '거래 후 연락 두절',
          ],
          requiresCustomInput: false,
        ),
        (
          label: '욕설/비매너',
          detailReasons: <String>['공격적 표현', '불쾌감을 주는 언행', '방문 후 규칙 위반'],
          requiresCustomInput: false,
        ),
        (
          label: '부적절한 콘텐츠',
          detailReasons: <String>['음란 / 선정적 내용', '혐오 / 차별 표현', '개인정보 요구'],
          requiresCustomInput: false,
        ),
        (
          label: MarketReportConstants.otherReasonLabel,
          detailReasons: <String>[],
          requiresCustomInput: true,
        ),
      ];

  final TextEditingController _customReasonController = TextEditingController();

  _MarketReportStep _step = _MarketReportStep.category;
  int _selectedCategoryIndex = 0;
  int _selectedDetailIndex = 0;

  _MarketReportCategory get _selectedCategory =>
      _categories[_selectedCategoryIndex];

  bool get _isDetailStep => _step == _MarketReportStep.detail;

  bool get _isCustomCategory => _selectedCategory.requiresCustomInput;

  String get _screenTitle => _isDetailStep ? '신고 상세 사유 선택' : '신고 사유 선택';

  String get _primaryButtonLabel {
    if (_isDetailStep || _isCustomCategory) {
      return '신고 접수하기';
    }
    return '다음 단계로';
  }

  bool get _canSubmit {
    if (_isDetailStep) {
      return _selectedCategory.detailReasons.isNotEmpty;
    }
    if (_isCustomCategory) {
      return _customReasonController.text.trim().isNotEmpty;
    }
    return true;
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  void _onTapBack() {
    if (_isDetailStep) {
      setState(() {
        _step = _MarketReportStep.category;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  void _onTapPrimary() {
    if (_isDetailStep) {
      if (_selectedCategory.detailReasons.isEmpty) {
        return;
      }
      final detail = _selectedCategory.detailReasons[_selectedDetailIndex];
      _submit(reason: _selectedCategory.label, detail: detail);
      return;
    }

    if (_isCustomCategory) {
      final detail = _customReasonController.text.trim();
      if (detail.isEmpty) {
        return;
      }
      _submit(reason: _selectedCategory.label, detail: detail);
      return;
    }

    setState(() {
      _step = _MarketReportStep.detail;
      _selectedDetailIndex = 0;
    });
  }

  void _submit({required String reason, required String detail}) {
    Navigator.of(context).pop((reason: reason, detail: detail));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDetailStep,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !_isDetailStep) {
          return;
        }
        setState(() {
          _step = _MarketReportStep.category;
        });
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: _onTapBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          title: Text(_screenTitle, style: AppTextStyles.headingH2Secondary),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 12),
              _ReportStepIndicator(currentStepIndex: _isDetailStep ? 1 : 0),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    0,
                    AppSpacing.pageHorizontal,
                    16,
                  ),
                  children: <Widget>[
                    if (_isDetailStep)
                      ..._buildDetailReasonTiles()
                    else
                      ..._buildCategoryTiles(),
                    if (!_isDetailStep && _isCustomCategory) ...<Widget>[
                      const SizedBox(height: 10),
                      _buildCustomReasonField(),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  0,
                  AppSpacing.pageHorizontal,
                  12,
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 110,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.bgSecondary,
                          side: const BorderSide(
                            color: AppColors.borderDefault,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              SettingsUiTokens.actionButtonRadius,
                            ),
                          ),
                        ),
                        child: Text('취소', style: AppTextStyles.buttonSecondary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: _canSubmit ? _onTapPrimary : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.settingsPrimaryButton,
                            disabledBackgroundColor: AppColors.borderDefault,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                SettingsUiTokens.actionButtonRadius,
                              ),
                            ),
                          ),
                          child: Text(
                            _primaryButtonLabel,
                            style: AppTextStyles.buttonPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryTiles() {
    return List<Widget>.generate(_categories.length, (index) {
      final category = _categories[index];
      return Padding(
        padding: EdgeInsets.only(
          bottom: index == _categories.length - 1 ? 0 : 10,
        ),
        child: _ReportSelectableTile(
          prefix: '${index + 1}.',
          label: category.label,
          selected: _selectedCategoryIndex == index,
          onTap: () {
            setState(() {
              _selectedCategoryIndex = index;
              _selectedDetailIndex = 0;
            });
          },
        ),
      );
    });
  }

  List<Widget> _buildDetailReasonTiles() {
    final detailReasons = _selectedCategory.detailReasons;
    return List<Widget>.generate(detailReasons.length, (index) {
      final prefix = '${String.fromCharCode(97 + index)}.';
      return Padding(
        padding: EdgeInsets.only(
          bottom: index == detailReasons.length - 1 ? 0 : 10,
        ),
        child: _ReportSelectableTile(
          prefix: prefix,
          label: detailReasons[index],
          selected: _selectedDetailIndex == index,
          onTap: () {
            setState(() {
              _selectedDetailIndex = index;
            });
          },
        ),
      );
    });
  }

  Widget _buildCustomReasonField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: TextField(
        controller: _customReasonController,
        maxLength: MarketReportConstants.customReasonMaxLength,
        minLines: 5,
        maxLines: 5,
        style: AppTextStyles.bodySecondaryStrong,
        cursorColor: AppColors.settingsPrimaryButton,
        decoration: InputDecoration(
          hintText: '사유를 입력해주세요...',
          hintStyle: AppTextStyles.bodyHintStrong,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterStyle: AppTextStyles.captionHint,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (_) {
          setState(() {});
        },
      ),
    );
  }
}

class _ReportSelectableTile extends StatelessWidget {
  const _ReportSelectableTile({
    required this.prefix,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String prefix;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: SettingsUiTokens.shortAnimation,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? AppColors.accentOrange
                    : AppColors.borderDefault,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '$prefix $label',
                    style: AppTextStyles.headingH2Secondary,
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? AppColors.settingsPrimaryButton
                      : AppColors.borderDefault,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportStepIndicator extends StatelessWidget {
  const _ReportStepIndicator({required this.currentStepIndex});

  final int currentStepIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildStepDot(active: currentStepIndex == 0),
        const SizedBox(width: 8),
        _buildStepDot(active: currentStepIndex == 1),
      ],
    );
  }

  Widget _buildStepDot({required bool active}) {
    return AnimatedContainer(
      duration: SettingsUiTokens.shortAnimation,
      width: active ? 30 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? AppColors.settingsPrimaryButton
            : AppColors.borderDefault,
        borderRadius: BorderRadius.circular(SettingsUiTokens.chipRadius),
      ),
    );
  }
}
