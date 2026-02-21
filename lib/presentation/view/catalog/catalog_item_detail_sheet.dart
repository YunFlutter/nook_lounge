import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/core/constants/app_spacing.dart';
import 'package:nook_lounge_app/domain/model/catalog_item.dart';

class CatalogItemDetailSheet extends StatefulWidget {
  const CatalogItemDetailSheet({
    required this.item,
    required this.isCompleted,
    required this.isFavorite,
    required this.isDonationMode,
    required this.onCompletedChanged,
    required this.onFavoriteChanged,
    super.key,
  });

  final CatalogItem item;
  final bool isCompleted;
  final bool isFavorite;
  final bool isDonationMode;
  final Future<void> Function(bool) onCompletedChanged;
  final Future<void> Function(bool) onFavoriteChanged;

  @override
  State<CatalogItemDetailSheet> createState() => _CatalogItemDetailSheetState();
}

class _CatalogItemDetailSheetState extends State<CatalogItemDetailSheet> {
  static const Set<String> _imageTagPrefixes = <String>{
    '주민사진URL',
    '아이콘URL',
    '집내부URL',
    '집외부URL',
    '옵션이미지URL',
  };

  static const List<String> _detailPriorityOrder = <String>[
    '성격',
    '성격세부',
    '종',
    '성별',
    '생일',
    '별자리',
    '말버릇',
    '좌우명',
    '취미',
    '의상',
    '선호색상',
    '선호스타일',
    '인테리어BGM',
    '우산',
    '집 벽지',
    '집 바닥',
    '인테리어 음악노트',
    '이전 말버릇',
    '판매가',
    '구매가',
    '출현시간',
    '북반구',
    '남반구',
    '서식처',
    '희귀도',
    '획득처',
    '재료',
    '리폼',
    '스타일',
    '그룹',
  ];

  late bool _isFavorite;
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _isCompleted = widget.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.70;
    final detailRows = _buildDetailRows();
    final detailImages = _buildDetailImages();

    return SizedBox(
      width: double.infinity,
      height: sheetHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              const SizedBox(height: AppSpacing.s10),
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.borderDefault,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s10),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.modalInner,
                    0,
                    AppSpacing.modalInner,
                    AppSpacing.modalInner,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildTopImage(),
                      if (detailImages.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.s10),
                        _buildDetailImageGallery(detailImages),
                      ],
                      const SizedBox(height: AppSpacing.s10 * 2),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              widget.item.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final next = !_isFavorite;
                              setState(() => _isFavorite = next);
                              try {
                                await widget.onFavoriteChanged(next);
                              } catch (_) {
                                if (!mounted) {
                                  return;
                                }
                                setState(() => _isFavorite = !next);
                              }
                            },
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite
                                  ? AppColors.badgeRedText
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _displayTags
                            .map((tag) => _InfoChip(label: tag))
                            .toList(growable: false),
                      ),
                      const SizedBox(height: AppSpacing.s10 * 2),
                      ...detailRows.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.s10,
                          ),
                          child: _InfoSection(
                            title: row.label,
                            value: row.value,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s10 * 2),
                      if (_isVillager)
                        ..._buildVillagerStateToggles()
                      else
                        ..._buildDefaultStateToggle(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> get _displayTags {
    final labels = <String>[];
    for (final tag in widget.item.tags) {
      if (tag.contains(':')) {
        continue;
      }
      labels.add(tag);
      if (labels.length == 3) {
        break;
      }
    }
    if (labels.isEmpty) {
      labels.add(widget.item.category);
    }
    return labels;
  }

  List<_DetailRow> _buildDetailRows() {
    final rows = <_DetailRow>[];
    final grouped = _groupPrefixedTags();
    final consumedPrefixes = <String>{};

    for (final prefix in _detailPriorityOrder) {
      final values = grouped[prefix];
      if (values == null || values.isEmpty) {
        continue;
      }
      final display = values.join(' / ');
      if (display.trim().isEmpty) {
        continue;
      }
      rows.add(
        _DetailRow(label: _displayLabelForPrefix(prefix), value: display),
      );
      consumedPrefixes.add(prefix);
    }

    for (final entry in grouped.entries) {
      if (consumedPrefixes.contains(entry.key)) {
        continue;
      }
      if (_imageTagPrefixes.contains(entry.key)) {
        continue;
      }
      if (entry.value.isEmpty) {
        continue;
      }
      rows.add(
        _DetailRow(
          label: _displayLabelForPrefix(entry.key),
          value: entry.value.join(' / '),
        ),
      );
    }

    if (rows.isEmpty) {
      rows.add(_DetailRow(label: '분류', value: widget.item.category));
    }

    return rows;
  }

  String _normalizeDetailValue({
    required String prefix,
    required String value,
  }) {
    if (value.isEmpty) {
      return value;
    }

    if (prefix == '구매가' || prefix == '판매가') {
      final parsedPrice = _extractPriceFromLegacyText(value);
      if (parsedPrice.isNotEmpty) {
        return parsedPrice;
      }
    }

    if (value.contains('{') && value.contains('}')) {
      return '';
    }

    return value;
  }

  String _extractPriceFromLegacyText(String text) {
    final pattern = RegExp(
      r'price:\s*([0-9,]+)\s*,\s*currency:\s*([^,\}\]]+)',
      caseSensitive: false,
    );
    final matches = pattern.allMatches(text);
    if (matches.isEmpty) {
      return '';
    }

    final values = <String>[];
    for (final match in matches) {
      final price = match.group(1)?.trim() ?? '';
      final currency = (match.group(2) ?? '').trim();
      if (price.isEmpty) {
        continue;
      }
      if (currency.isEmpty) {
        values.add(price);
      } else {
        values.add('$price$currency');
      }
    }

    return values.join(' / ');
  }

  Widget _buildTopImage() {
    final fallback = Image.asset(
      'assets/images/no_data_image.png',
      width: double.infinity,
      height: 240,
      fit: BoxFit.contain,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: AppColors.bgSecondary,
        child: widget.item.imageUrl.isEmpty
            ? fallback
            : Image.network(
                widget.item.imageUrl,
                width: double.infinity,
                height: 240,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }

  List<_DetailImage> _buildDetailImages() {
    final images = <_DetailImage>[];

    for (final tag in widget.item.tags) {
      final separator = tag.indexOf(':');
      if (separator <= 0 || separator >= tag.length - 1) {
        continue;
      }
      final prefix = tag.substring(0, separator).trim();
      if (!_imageTagPrefixes.contains(prefix)) {
        continue;
      }

      final payload = tag.substring(separator + 1).trim();
      if (prefix == '옵션이미지URL') {
        final parsed = _parseOptionImagePayload(payload);
        if (parsed == null) {
          continue;
        }
        if (images.any((image) => image.url == parsed.url)) {
          continue;
        }
        images.add(parsed);
        continue;
      }

      if (!(payload.startsWith('http://') || payload.startsWith('https://'))) {
        continue;
      }

      final label = _imageLabel(prefix);
      if (images.any((image) => image.url == payload)) {
        continue;
      }
      images.add(_DetailImage(label: label, url: payload));
    }

    return images;
  }

  Widget _buildDetailImageGallery(List<_DetailImage> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.item.category == '패션' ? '색상 옵션' : '참고 이미지',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 126,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, unused) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final image = images[index];
              return SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      image.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openImagePreview(image),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            image.url,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/no_data_image.png',
                                fit: BoxFit.contain,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _imageLabel(String prefix) {
    switch (prefix) {
      case '주민사진URL':
        return '주민 사진';
      case '아이콘URL':
        return '아이콘';
      case '집내부URL':
        return '집 내부';
      case '집외부URL':
        return '집 외부';
      case '옵션이미지URL':
        return '색상 옵션';
      default:
        return '이미지';
    }
  }

  _DetailImage? _parseOptionImagePayload(String payload) {
    final separatorIndex = payload.indexOf('||');
    if (separatorIndex <= 0 || separatorIndex >= payload.length - 2) {
      return null;
    }

    final label = payload.substring(0, separatorIndex).trim();
    final url = payload.substring(separatorIndex + 2).trim();
    if (!(url.startsWith('http://') || url.startsWith('https://'))) {
      return null;
    }

    return _DetailImage(label: label.isEmpty ? '색상 옵션' : label, url: url);
  }

  Future<void> _openImagePreview(_DetailImage image) async {
    await showDialog<void>(
      context: context,
      barrierColor: AppColors.shadowStrong,
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: AppColors.black,
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.network(
                      image.url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/no_data_image.png',
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.white,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Text(
                    image.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool get _isVillager => widget.item.category == '주민';

  List<Widget> _buildDefaultStateToggle() {
    final title = widget.isDonationMode ? '박물관 기증' : '보유 상태';
    final offLabel = widget.isDonationMode ? '미기증' : '미보유';
    final onLabel = widget.isDonationMode ? '기증완료' : '보유';

    return <Widget>[
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: AppSpacing.s10),
      _SegmentStatusToggle(
        value: _isCompleted,
        offLabel: offLabel,
        onLabel: onLabel,
        offIcon: widget.isDonationMode
            ? Icons.radio_button_unchecked_rounded
            : Icons.inventory_2_outlined,
        onIcon: widget.isDonationMode
            ? Icons.account_balance_rounded
            : Icons.check_circle_rounded,
        onSelectedColor: widget.isDonationMode
            ? AppColors.catalogProgressAccent
            : AppColors.catalogSuccessText,
        onChanged: (value) async {
          setState(() => _isCompleted = value);
          await widget.onCompletedChanged(value);
        },
      ),
    ];
  }

  List<Widget> _buildVillagerStateToggles() {
    return <Widget>[
      Text(
        '주민 상태',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: AppSpacing.s10),
      Text(
        '거주',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      _SegmentStatusToggle(
        value: _isCompleted,
        offLabel: '미거주',
        onLabel: '거주중',
        offIcon: Icons.home_outlined,
        onIcon: Icons.home_rounded,
        onSelectedColor: AppColors.catalogSuccessText,
        onChanged: (value) async {
          setState(() => _isCompleted = value);
          await widget.onCompletedChanged(value);
        },
      ),
      const SizedBox(height: AppSpacing.s10),
      Text(
        '선호',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      _SegmentStatusToggle(
        value: _isFavorite,
        offLabel: '일반',
        onLabel: '선호',
        offIcon: Icons.favorite_border_rounded,
        onIcon: Icons.favorite_rounded,
        onSelectedColor: AppColors.badgePurpleText,
        onChanged: (value) async {
          setState(() => _isFavorite = value);
          await widget.onFavoriteChanged(value);
        },
      ),
    ];
  }

  Map<String, List<String>> _groupPrefixedTags() {
    final grouped = <String, List<String>>{};

    for (final tag in widget.item.tags) {
      final separator = tag.indexOf(':');
      if (separator <= 0 || separator >= tag.length - 1) {
        continue;
      }

      final prefix = tag.substring(0, separator).trim();
      final rawValue = tag.substring(separator + 1).trim();
      if (prefix.isEmpty || rawValue.isEmpty) {
        continue;
      }

      final normalized = _normalizeDetailValue(prefix: prefix, value: rawValue);
      if (normalized.isEmpty) {
        continue;
      }

      final values = grouped.putIfAbsent(prefix, () => <String>[]);
      if (!values.contains(normalized)) {
        values.add(normalized);
      }
    }

    return grouped;
  }

  String _displayLabelForPrefix(String prefix) {
    switch (prefix) {
      case '출현시간':
        return '출현 시간';
      case '북반구':
        return '출현 시기(북)';
      case '남반구':
        return '출현 시기(남)';
      case '인테리어BGM':
        return '인테리어 BGM';
      case '성격세부':
        return '성격 세부';
      default:
        return prefix;
    }
  }
}

class _DetailImage {
  const _DetailImage({required this.label, required this.url});

  final String label;
  final String url;
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 96,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.catalogChipBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SegmentStatusToggle extends StatelessWidget {
  const _SegmentStatusToggle({
    required this.value,
    required this.offLabel,
    required this.onLabel,
    required this.offIcon,
    required this.onIcon,
    required this.onSelectedColor,
    required this.onChanged,
  });

  final bool value;
  final String offLabel;
  final String onLabel;
  final IconData offIcon;
  final IconData onIcon;
  final Color onSelectedColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.catalogSegmentBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SegmentStatusItem(
              label: offLabel,
              icon: offIcon,
              selected: !value,
              selectedColor: AppColors.textSecondary,
              onTap: () {
                if (value) {
                  onChanged(false);
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _SegmentStatusItem(
              label: onLabel,
              icon: onIcon,
              selected: value,
              selectedColor: onSelectedColor,
              onTap: () {
                if (!value) {
                  onChanged(true);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentStatusItem extends StatelessWidget {
  const _SegmentStatusItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: selected ? selectedColor : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? selectedColor : AppColors.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;
}
