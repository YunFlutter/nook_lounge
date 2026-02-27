import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/island_profile_options.dart';
import 'package:nook_lounge_app/core/constants/settings_ui_tokens.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';

class SettingsIslandListSheet extends StatelessWidget {
  const SettingsIslandListSheet({
    required this.islands,
    required this.selectedIslandId,
    required this.onIslandTap,
    super.key,
  });

  final List<IslandProfile> islands;
  final String? selectedIslandId;
  final ValueChanged<IslandProfile> onIslandTap;

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.65;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        children: <Widget>[
          const SizedBox(height: SettingsUiTokens.verticalGap),
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.borderDefault,
              borderRadius: BorderRadius.circular(SettingsUiTokens.chipRadius),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SettingsUiTokens.horizontalPadding,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('나의 섬 목록', style: AppTextStyles.dialogTitleCompact),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: islands.isEmpty
                ? _emptyView()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      SettingsUiTokens.horizontalPadding,
                      0,
                      SettingsUiTokens.horizontalPadding,
                      SettingsUiTokens.horizontalPadding,
                    ),
                    itemBuilder: (context, index) {
                      final island = islands[index];
                      final isSelected = island.id == selectedIslandId;
                      final fruitEmoji =
                          IslandProfileOptions.fruitEmojiByName[island
                              .nativeFruit] ??
                          IslandProfileOptions.fallbackFruitEmoji;

                      return Semantics(
                        button: true,
                        label: '${island.islandName} 섬 상세',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            SettingsUiTokens.tileRadius,
                          ),
                          onTap: () => onIslandTap(island),
                          child: AnimatedContainer(
                            duration: SettingsUiTokens.shortAnimation,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(
                                SettingsUiTokens.tileRadius,
                              ),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentDeepOrange
                                    : AppColors.borderDefault,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                ClipOval(
                                  child: Container(
                                    width: 58,
                                    height: 58,
                                    color: AppColors.bgSecondary,
                                    child: _buildIslandImage(island.imageUrl),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        island.islandName,
                                        style: AppTextStyles.bodyWithSize(
                                          18,
                                          color: AppColors.textPrimary,
                                          weight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '대표: ${island.representativeName}     $fruitEmoji ${island.nativeFruit}',
                                        style: AppTextStyles.bodyWithSize(
                                          14,
                                          color: AppColors.textMuted,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary,
                                  size: 30,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: SettingsUiTokens.verticalGap),
                    itemCount: islands.length,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Text('등록된 섬이 없어요.', style: AppTextStyles.bodyMutedStrong),
    );
  }

  Widget _buildIslandImage(String? url) {
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
