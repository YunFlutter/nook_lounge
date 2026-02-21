import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/domain/model/island_profile.dart';

class IslandSwitchSheet extends StatelessWidget {
  const IslandSwitchSheet({
    required this.islands,
    required this.selectedIslandId,
    required this.onSelectIsland,
    required this.onAddIsland,
    super.key,
  });

  final List<IslandProfile> islands;
  final String? selectedIslandId;
  final Future<void> Function(String islandId) onSelectIsland;
  final Future<void> Function() onAddIsland;

  static const Map<String, String> _fruitEmojiByName = <String, String>{
    '사과': '🍎',
    '체리': '🍒',
    '오렌지': '🍊',
    '복숭아': '🍑',
    '배': '🍐',
  };

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.7;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.modalOuter),
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.borderDefault,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpacing.modalOuter),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.modalInner),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '섬 선택하기',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.modalOuter),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.modalInner,
                0,
                AppSpacing.modalInner,
                AppSpacing.modalInner,
              ),
              itemCount: islands.length + 1,
              separatorBuilder: (_, index) =>
                  const SizedBox(height: AppSpacing.modalOuter),
              itemBuilder: (context, index) {
                if (index == islands.length) {
                  return _buildAddTile(context);
                }

                final island = islands[index];
                final selected = island.id == selectedIslandId;
                final fruitEmoji =
                    _fruitEmojiByName[island.nativeFruit] ?? '🍑';

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onSelectIsland(island.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.catalogSuccessBg
                          : AppColors.catalogCardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryDefault
                            : AppColors.borderDefault,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        ClipOval(
                          child: Container(
                            width: 58,
                            height: 58,
                            color: AppColors.bgSecondary,
                            child: _buildNetworkImage(island.imageUrl),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                island.islandName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '대표: ${island.representativeName}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$fruitEmoji ${island.nativeFruit}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: selected
                              ? Container(
                                  key: const ValueKey<String>('selected'),
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryDefault,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: AppColors.white,
                                  ),
                                )
                              : Container(
                                  key: const ValueKey<String>('normal'),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.borderDefault,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTile(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onAddIsland,
      child: Container(
        height: 124,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.catalogChipBg,
              child: Icon(
                Icons.add_rounded,
                size: 28,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '새 섬 추가하기',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String? url) {
    if (url == null || url.isEmpty) {
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
