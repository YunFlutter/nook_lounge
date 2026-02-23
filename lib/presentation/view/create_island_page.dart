import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/create_island_draft.dart';
import 'package:nook_lounge_app/presentation/state/create_island_view_state.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/passport_issued_page.dart';

class CreateIslandPage extends ConsumerStatefulWidget {
  const CreateIslandPage({
    required this.uid,
    super.key,
    this.onIslandEntered,
    this.popToDashboardOnEnter = false,
  });

  final String uid;
  final Future<void> Function(String islandId)? onIslandEntered;
  final bool popToDashboardOnEnter;

  @override
  ConsumerState<CreateIslandPage> createState() => _CreateIslandPageState();
}

class _CreateIslandPageState extends ConsumerState<CreateIslandPage> {
  static const _fruits = <String>['사과', '체리', '오렌지', '복숭아', '배'];
  static const _fruitEmojiByName = <String, String>{
    '사과': '🍎',
    '체리': '🍒',
    '오렌지': '🍊',
    '복숭아': '🍑',
    '배': '🍐',
  };

  final _formKey = GlobalKey<FormState>();
  final _islandNameController = TextEditingController();
  final _representativeController = TextEditingController();
  final _imagePicker = ImagePicker();

  String _hemisphere = '북반구';
  String _nativeFruit = '복숭아';
  CreateIslandDraft? _lastSubmittedDraft;
  String? _lastCreatedIslandId;
  bool _openingIssuedPage = false;

  ProviderSubscription<CreateIslandViewState>? _createSubscription;

  @override
  void initState() {
    super.initState();
    final createIslandViewModel = ref.read(
      createIslandViewModelProvider.notifier,
    );
    final sessionViewModel = ref.read(sessionViewModelProvider.notifier);

    _createSubscription = ref.listenManual<CreateIslandViewState>(
      createIslandViewModelProvider,
      (previous, next) async {
        if (!mounted) {
          return;
        }

        if (next.errorMessage != null &&
            next.errorMessage != previous?.errorMessage) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));

          createIslandViewModel.clearError();
          return;
        }

        if (next.submitSuccess && previous?.submitSuccess != true) {
          if (_openingIssuedPage) {
            return;
          }

          final submittedDraft = _lastSubmittedDraft;
          if (submittedDraft == null) {
            createIslandViewModel.resetSubmitState();
            return;
          }

          _openingIssuedPage = true;

          final entered = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => PassportIssuedPage(
                draft: submittedDraft,
                imagePath: next.selectedImagePath,
                onEnterIsland: () async {
                  await sessionViewModel.refresh();
                  final islandId = _lastCreatedIslandId;
                  if (islandId != null && widget.onIslandEntered != null) {
                    await widget.onIslandEntered!(islandId);
                  }
                },
              ),
            ),
          );

          if (!mounted) {
            return;
          }
          _openingIssuedPage = false;
          createIslandViewModel.resetSubmitState();
          if (entered == true && widget.popToDashboardOnEnter && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _createSubscription?.close();
    _islandNameController.dispose();
    _representativeController.dispose();
    super.dispose();
  }

  Future<void> _pickPassportImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );

    if (pickedFile == null || !mounted) {
      return;
    }

    ref
        .read(createIslandViewModelProvider.notifier)
        .setSelectedImagePath(pickedFile.path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createIslandViewModelProvider);
    final viewModel = ref.read(createIslandViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('여권 만들기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.s10,
          AppSpacing.pageHorizontal,
          AppSpacing.s10 * 3,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AnimatedFadeSlide(
                child: Text(
                  '나만의 여권을\n등록해볼까요?',
                  style: AppTextStyles.bodyWithSize(
                    20,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s10),
              AnimatedFadeSlide(
                delay: Duration(milliseconds: 30),
                child: Text(
                  '당신의 섬 정보를 입력해 주세요.',
                  style: AppTextStyles.bodyWithSize(
                    14,
                    color: AppColors.textMuted,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s10 * 2),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 60),
                child: Center(
                  child: Semantics(
                    button: true,
                    label: '사진 업로드',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(60),
                      onTap: state.isSubmitting ? null : _pickPassportImage,
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: AppColors.bgSecondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.borderDefault,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: state.selectedImagePath == null
                                ? const Icon(
                                    Icons.photo_camera_outlined,
                                    size: 42,
                                    color: AppColors.textMuted,
                                  )
                                : ClipOval(
                                    child: Image.file(
                                      File(state.selectedImagePath!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.s10),
                          Text(
                            '사진 업로드',
                            style: AppTextStyles.bodyWithSize(
                              13,
                              color: AppColors.textMuted,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s10 * 2),
              Text(
                '섬 이름',
                style: AppTextStyles.bodyPrimaryStrong,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _islandNameController,
                cursorColor: AppColors.accentDeepOrange,
                decoration: _fieldDecoration(hintText: '예: 너굴섬'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '섬 이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.s10),
              Text(
                '대표 주민 이름',
                style: AppTextStyles.bodyPrimaryStrong,
              ),
              const SizedBox(height: AppSpacing.s10),
              TextFormField(
                controller: _representativeController,
                cursorColor: AppColors.accentDeepOrange,
                decoration: _fieldDecoration(hintText: '예: 너굴팬'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '대표 주민 이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.s10),
              Text(
                '반구 선택',
                style: AppTextStyles.bodyPrimaryStrong,
              ),
              const SizedBox(height: AppSpacing.s10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _HemisphereCard(
                      title: '북반구',
                      imagePath:
                          'assets/images/icon_northern_hemisphere_compass.png',
                      selected: _hemisphere == '북반구',
                      onTap: () => setState(() => _hemisphere = '북반구'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s10),
                  Expanded(
                    child: _HemisphereCard(
                      title: '남반구',
                      imagePath:
                          'assets/images/icon_southern_hemisphere_compass.png',
                      selected: _hemisphere == '남반구',
                      onTap: () => setState(() => _hemisphere = '남반구'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s10 + 6),
              Text(
                '특산물',
                style: AppTextStyles.bodyPrimaryStrong,
              ),
              const SizedBox(height: AppSpacing.s10),
              Wrap(
                spacing: AppSpacing.s10,
                runSpacing: AppSpacing.s10,
                children: _fruits
                    .map(
                      (fruit) => _FruitCircleButton(
                        emoji: _fruitEmojiByName[fruit] ?? '🍀',
                        selected: _nativeFruit == fruit,
                        onTap: () => setState(() => _nativeFruit = fruit),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: AppSpacing.s10 * 2),
              FilledButton(
                onPressed: state.isSubmitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }

                        final draft = CreateIslandDraft(
                          islandName: _islandNameController.text.trim(),
                          representativeName: _representativeController.text
                              .trim(),
                          hemisphere: _hemisphere,
                          nativeFruit: _nativeFruit,
                        );

                        _lastSubmittedDraft = draft;
                        _lastCreatedIslandId = await viewModel.createIsland(
                          uid: widget.uid,
                          draft: draft,
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentDeepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(state.isSubmitting ? '등록 중...' : '섬 등록하고 시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hintText}) {
    const borderRadius = BorderRadius.all(Radius.circular(14));
    return InputDecoration(
      hintText: hintText,
      errorStyle: AppTextStyles.bodyWithSize(
        12,
        color: AppColors.accentDeepOrange,
        weight: FontWeight.w700,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: AppColors.borderDefault),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: AppColors.accentDeepOrange, width: 1.8),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: AppColors.accentDeepOrange, width: 1.5),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: AppColors.accentDeepOrange, width: 1.8),
      ),
    );
  }
}

class _HemisphereCard extends StatelessWidget {
  const _HemisphereCard({
    required this.title,
    required this.imagePath,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String imagePath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.accentDeepOrange
                : AppColors.borderDefault,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            Image.asset(imagePath, height: 64, fit: BoxFit.contain),
            const SizedBox(height: AppSpacing.s10),
            Text(
              title,
              style: AppTextStyles.bodyWithSize(
                18,
                color: AppColors.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FruitCircleButton extends StatelessWidget {
  const _FruitCircleButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? AppColors.accentDeepOrange
                : AppColors.borderDefault,
            width: selected ? 2.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: AppTextStyles.bodyWithSize(
            24,
            color: AppColors.textPrimary,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
