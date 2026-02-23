import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/di/app_providers.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';
import 'package:nook_lounge_app/presentation/view/animated_fade_slide.dart';
import 'package:nook_lounge_app/presentation/view/catalog/catalog_collection_page.dart';

class GuestBrowsePage extends ConsumerStatefulWidget {
  const GuestBrowsePage({required this.uid, super.key});

  final String uid;

  @override
  ConsumerState<GuestBrowsePage> createState() => _GuestBrowsePageState();
}

class _GuestBrowsePageState extends ConsumerState<GuestBrowsePage> {
  static const String _guestIslandId = 'guest_readonly';

  static const List<String> _museumCategories = <String>[
    '곤충',
    '물고기',
    '해산물',
    '화석',
    '미술품',
  ];

  static const List<String> _collectionCategories = <String>[
    '주민',
    '패션',
    '레시피',
    '가구',
    '아이템',
  ];

  bool _isLoading = true;
  String? _errorMessage;
  List<CatalogItem> _items = const <CatalogItem>[];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await ref.read(catalogRepositoryProvider).loadAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '도감 데이터를 불러오지 못했어요.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비회원 둘러보기'),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              ref.read(sessionViewModelProvider.notifier).exitGuestBrowseMode();
            },
            child: Text(
              '로그인하기',
              style: AppTextStyles.bodyWithSize(
                14,
                color: AppColors.textPrimary,
                weight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCatalog,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.s10,
            AppSpacing.pageHorizontal,
            AppSpacing.s10 * 2,
          ),
          children: <Widget>[
            const AnimatedFadeSlide(child: _GuestIntroCard()),
            const SizedBox(height: AppSpacing.s10 * 2),
            if (_isLoading)
              const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: AppTextStyles.bodySecondaryStrong,
              )
            else ...<Widget>[
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 40),
                child: _buildCategorySection(
                  title: '박물관 도감',
                  categories: _museumCategories,
                ),
              ),
              const SizedBox(height: AppSpacing.s10 * 2),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 80),
                child: _buildCategorySection(
                  title: '수집 도감',
                  categories: _collectionCategories,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required List<String> categories,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: AppTextStyles.bodyWithSize(
            22,
            color: AppColors.textPrimary,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.s10),
        ...categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final count = _items
              .where((item) => item.category == category)
              .length;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == categories.length - 1 ? 0 : 8,
            ),
            child: AnimatedFadeSlide(
              delay: Duration(milliseconds: 20 + (index * 24)),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openCategory(category),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.catalogCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        _iconByCategory(category),
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _labelByCategory(category),
                          style: AppTextStyles.bodyPrimaryHeavy,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.catalogChipBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$count개',
                          style: AppTextStyles.captionSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _openCategory(String category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CatalogCollectionPage(
          uid: widget.uid,
          islandId: _guestIslandId,
          title: '${_labelByCategory(category)} 도감',
          category: category,
          allItems: _items,
          readOnly: true,
        ),
      ),
    );
  }

  IconData _iconByCategory(String category) {
    switch (category) {
      case '곤충':
        return Icons.bug_report_rounded;
      case '물고기':
        return Icons.set_meal_rounded;
      case '해산물':
        return Icons.waves_rounded;
      case '화석':
        return Icons.terrain_rounded;
      case '미술품':
        return Icons.palette_outlined;
      case '주민':
        return Icons.people_alt_rounded;
      case '패션':
        return Icons.checkroom_rounded;
      case '레시피':
        return Icons.menu_book_rounded;
      case '가구':
        return Icons.chair_alt_rounded;
      case '아이템':
        return Icons.widgets_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  String _labelByCategory(String category) {
    if (category == '아이템') {
      return '벽지 등';
    }
    return category;
  }
}

class _GuestIntroCard extends StatelessWidget {
  const _GuestIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.catalogChipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Text(
        '비회원 둘러보기 모드입니다.\n도감 리스트/상세 조회만 가능하며 상태 저장은 지원하지 않아요.',
        style: AppTextStyles.bodyWithSize(
          13,
          color: AppColors.textSecondary,
          weight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}
