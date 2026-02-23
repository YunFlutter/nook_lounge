import 'package:flutter/material.dart';
import 'package:nook_lounge_app/app/theme/app_colors.dart';
import 'package:nook_lounge_app/app/theme/app_text_styles.dart';

class TurnipPriceInputField extends StatelessWidget {
  const TurnipPriceInputField({
    required this.value,
    required this.onChanged,
    required this.fieldId,
    this.onFocusChanged,
    super.key,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final String fieldId;
  final ValueChanged<bool>? onFocusChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Focus(
        onFocusChange: (hasFocus) {
          onFocusChanged?.call(hasFocus);
        },
        child: TextFormField(
          key: ValueKey<String>('slot-$fieldId'),
          initialValue: value?.toString() ?? '',
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            isDense: true,
            hintText: '-',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            fillColor: AppColors.catalogChipBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
          ),
          style: AppTextStyles.bodyWithSize(
            14,
            color: AppColors.textPrimary,
            weight: FontWeight.w700,
          ),
          onChanged: (text) {
            final normalized = text.replaceAll(RegExp(r'[^0-9]'), '');
            if (normalized.isEmpty) {
              onChanged(null);
              return;
            }
            onChanged(int.tryParse(normalized));
          },
        ),
      ),
    );
  }
}
