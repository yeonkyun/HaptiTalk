import 'package:flutter/material.dart';
import 'package:hapti_talk/constants/colors.dart';
import 'package:hapti_talk/constants/dimensions.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final String? error;
  final bool obscureText;
  final bool enabled;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final FormFieldValidator<String>? validator;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final InputBorder? border;
  final EdgeInsetsGeometry? contentPadding;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool filled;
  final Color? fillColor;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final bool enableSuggestions;
  final bool autocorrect;

  const CustomTextField({
    Key? key,
    this.controller,
    this.hint,
    this.label,
    this.error,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onEditingComplete,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.border,
    this.contentPadding,
    this.autofocus = false,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.onTap,
    this.filled = true,
    this.fillColor,
    this.style,
    this.hintStyle,
    this.enableSuggestions = true,
    this.autocorrect = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          autofocus: autofocus,
          focusNode: focusNode,
          textCapitalization: textCapitalization,
          readOnly: readOnly,
          onTap: onTap,
          enableSuggestions: enableSuggestions,
          autocorrect: autocorrect,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: hintStyle ??
                TextStyle(
                  color: AppColors.hintTextColor,
                  fontSize: Dimensions.fontM,
                ),
            errorText: error,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: filled,
            fillColor: fillColor ?? AppColors.inputBackgroundColor,
            contentPadding: contentPadding ??
                EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingM,
                  vertical: Dimensions.paddingS,
                ),
            border: border ??
                OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  borderSide: BorderSide.none,
                ),
            enabledBorder: border ??
                OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  borderSide: BorderSide.none,
                ),
            focusedBorder: border ??
                OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 1.5,
                  ),
                ),
            errorBorder: border ??
                OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1.5,
                  ),
                ),
            focusedErrorBorder: border ??
                OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1.5,
                  ),
                ),
          ),
          style: style ??
              const TextStyle(
                fontSize: Dimensions.fontM,
                color: AppColors.textColor,
              ),
        ),
      ],
    );
  }
}
