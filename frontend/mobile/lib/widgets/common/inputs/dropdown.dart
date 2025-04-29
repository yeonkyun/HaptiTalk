import 'package:flutter/material.dart';
import 'package:hapti_talk/constants/colors.dart';
import 'package:hapti_talk/constants/dimensions.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String? label;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;
  final Widget? icon;
  final Widget? prefixIcon;
  final bool filled;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final String? error;
  final bool enabled;

  const CustomDropdown({
    Key? key,
    this.label,
    required this.hint,
    this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = true,
    this.icon,
    this.prefixIcon,
    this.filled = true,
    this.fillColor,
    this.borderRadius,
    this.padding,
    this.constraints,
    this.error,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderRadiusValue =
        borderRadius ?? BorderRadius.circular(Dimensions.radiusM);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: Dimensions.fontS,
              fontWeight: FontWeight.w500,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: Dimensions.marginXS),
        ],
        Container(
          padding: padding,
          constraints: constraints,
          decoration: BoxDecoration(
            color: filled
                ? (fillColor ?? AppColors.inputBackgroundColor)
                : Colors.transparent,
            borderRadius: borderRadiusValue,
            border:
                error != null ? Border.all(color: Colors.red, width: 1) : null,
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                prefixIcon!,
                const SizedBox(width: Dimensions.marginS),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    hint: Text(
                      hint,
                      style: TextStyle(
                        fontSize: Dimensions.fontM,
                        color: AppColors.hintTextColor,
                      ),
                    ),
                    isExpanded: isExpanded,
                    icon: icon ??
                        const Icon(Icons.arrow_drop_down,
                            color: AppColors.secondaryTextColor),
                    style: const TextStyle(
                      fontSize: Dimensions.fontM,
                      color: AppColors.textColor,
                    ),
                    onChanged: enabled ? onChanged : null,
                    items: items,
                    dropdownColor: Colors.white,
                    borderRadius: borderRadiusValue,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: Dimensions.marginXS),
          Text(
            error!,
            style: const TextStyle(
              fontSize: Dimensions.fontXS,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}
