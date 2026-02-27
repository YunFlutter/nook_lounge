import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/island_profile_options.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';
import 'package:nook_lounge_app/presentation/view/settings/settings_dialogs.dart';

class SettingsIslandEditPage extends ConsumerStatefulWidget {
  const SettingsIslandEditPage({
    required this.uid,
    required this.island,
    super.key,
  });

  final String uid;
  final IslandProfile island;

  @override
  ConsumerState<SettingsIslandEditPage> createState() =>
      _SettingsIslandEditPageState();
}

class _SettingsIslandEditPageState
    extends ConsumerState<SettingsIslandEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _islandNameController = TextEditingController();
  final _representativeController = TextEditingController();
  final _imagePicker = ImagePicker();

  late String _selectedHemisphere;
  late String _selectedFruit;
  String? _localImagePath;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _islandNameController.text = widget.island.islandName;
    _representativeController.text = widget.island.representativeName;
    _selectedHemisphere = widget.island.hemisphere;
    _selectedFruit = widget.island.nativeFruit;
    _islandNameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _islandNameController.dispose();
    _representativeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitle = _islandNameController.text.trim().isEmpty
        ? widget.island.islandName
        : _islandNameController.text.trim();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: '뒤로가기',
        ),
        title: Text(appBarTitle),
        actions: <Widget>[
          IconButton(
            onPressed: _isSaving || _isDeleting ? null : _deleteIsland,
            icon: const Icon(Icons.delete_rounded),
            tooltip: '섬 삭제',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.verticalGap,
          SettingsUiTokens.horizontalPadding,
          SettingsUiTokens.horizontalPadding,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('섬 정보 수정', style: AppTextStyles.headingH2),
              const SizedBox(height: 10),
              Center(
                child: Semantics(
                  button: true,
                  label: '섬 이미지 수정',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(80),
                    onTap: _isSaving || _isDeleting ? null : _pickImage,
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: 124,
                          height: 124,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.bgSecondary,
                            border: Border.all(color: AppColors.borderDefault),
                          ),
                          child: ClipOval(child: _buildIslandImage()),
                        ),
                        const SizedBox(height: 10),
                        Text('이미지 수정', style: AppTextStyles.bodyHintStrong),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('섬 이름', style: AppTextStyles.bodyPrimaryStrong),
              const SizedBox(height: 6),
              TextFormField(
                controller: _islandNameController,
                enabled: !_isSaving && !_isDeleting,
                decoration: _inputDecoration(hintText: '섬 이름'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '섬 이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text('대표 주민 이름', style: AppTextStyles.bodyPrimaryStrong),
              const SizedBox(height: 6),
              TextFormField(
                controller: _representativeController,
                enabled: !_isSaving && !_isDeleting,
                decoration: _inputDecoration(hintText: '대표 주민 이름'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '대표 주민 이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Text('반구 선택', style: AppTextStyles.bodyPrimaryStrong),
              const SizedBox(height: 10),
              Row(
                children: IslandProfileOptions.hemispheres
                    .map((hemisphere) {
                      final assetPath =
                          IslandProfileOptions
                              .hemisphereAssetByName[hemisphere] ??
                          '';
                      final selected = _selectedHemisphere == hemisphere;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right:
                                hemisphere ==
                                    IslandProfileOptions.northHemisphere
                                ? 10
                                : 0,
                          ),
                          child: InkWell(
                            onTap: _isSaving || _isDeleting
                                ? null
                                : () => setState(
                                    () => _selectedHemisphere = hemisphere,
                                  ),
                            borderRadius: BorderRadius.circular(22),
                            child: AnimatedContainer(
                              duration: SettingsUiTokens.shortAnimation,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.accentDeepOrange
                                      : AppColors.borderDefault,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Image.asset(
                                    assetPath,
                                    height: 74,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    hemisphere,
                                    style: AppTextStyles.bodyWithSize(
                                      18,
                                      color: AppColors.textSecondary,
                                      weight: FontWeight.w800,
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
              const SizedBox(height: 14),
              Text('특산물', style: AppTextStyles.bodyPrimaryStrong),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: IslandProfileOptions.fruits
                    .map((fruit) {
                      final emoji =
                          IslandProfileOptions.fruitEmojiByName[fruit] ??
                          IslandProfileOptions.fallbackFruitEmoji;
                      final selected = _selectedFruit == fruit;
                      return InkWell(
                        onTap: _isSaving || _isDeleting
                            ? null
                            : () => setState(() => _selectedFruit = fruit),
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedContainer(
                          duration: SettingsUiTokens.shortAnimation,
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
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving || _isDeleting ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentDeepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(_isSaving ? '수정 중...' : '수정 완료'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );

    if (!mounted || pickedFile == null) {
      return;
    }

    setState(() {
      _localImagePath = pickedFile.path;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = widget.island.copyWith(
        islandName: _islandNameController.text.trim(),
        representativeName: _representativeController.text.trim(),
        hemisphere: _selectedHemisphere,
        nativeFruit: _selectedFruit,
      );

      await ref
          .read(islandRepositoryProvider)
          .updateIslandProfile(
            uid: widget.uid,
            profile: updated,
            passportImagePath: _localImagePath,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('섬 정보를 수정했어요.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('수정에 실패했어요.\n$error')));
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteIsland() async {
    final confirmed = await SettingsDialogs.showIslandDeleteConfirm(
      context: context,
      islandName: widget.island.islandName,
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await ref
          .read(islandRepositoryProvider)
          .deleteIsland(uid: widget.uid, islandId: widget.island.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('섬을 삭제했어요.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('삭제에 실패했어요.\n$error')));
      setState(() {
        _isDeleting = false;
      });
    }
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      errorStyle: AppTextStyles.bodyWithSize(
        12,
        color: AppColors.accentDeepOrange,
        weight: FontWeight.w700,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.accentDeepOrange,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.accentDeepOrange,
          width: 1.6,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.accentDeepOrange,
          width: 1.8,
        ),
      ),
    );
  }

  Widget _buildIslandImage() {
    if (_localImagePath != null && _localImagePath!.trim().isNotEmpty) {
      return Image.file(File(_localImagePath!), fit: BoxFit.cover);
    }

    final url = widget.island.imageUrl;
    if (url == null || url.trim().isEmpty) {
      return Image.asset(
        'assets/images/icon_raccoon_character.png',
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/icon_raccoon_character.png',
          fit: BoxFit.cover,
        );
      },
    );
  }
}
