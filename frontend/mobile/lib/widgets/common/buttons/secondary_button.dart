import 'package:flutter/material.dart';
import 'package:haptitalk/constants/colors.dart';
import 'package:haptitalk/constants/dimensions.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double width;
  final double height;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color borderColor;
  final Color textColor;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const SecondaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width = double.infinity,
    this.height = Dimensions.buttonHeightL,
    this.padding = const EdgeInsets.symmetric(
      horizontal: Dimensions.paddingM,
      vertical: Dimensions.paddingS,
    ),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(Dimensions.radiusM),
    ),
    this.borderColor = AppColors.primaryColor,
    this.textColor = AppColors.primaryColor,
    this.prefixIcon,
    this.suffixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: (isLoading || isDisabled) ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isDisabled ? AppColors.secondaryTextColor : textColor,
          padding: padding,
          side: BorderSide(
            color: isDisabled ? AppColors.dividerColor : borderColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: textColor,
          strokeWidth: 2.5,
        ),
      );
    }

    final List<Widget> rowChildren = [];

    if (prefixIcon != null) {
      rowChildren.add(prefixIcon!);
      rowChildren.add(const SizedBox(width: Dimensions.marginS));
    }

    rowChildren.add(
      Text(
        text,
        style: TextStyle(
          color: isDisabled ? AppColors.secondaryTextColor : textColor,
          fontSize: Dimensions.fontM,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (suffixIcon != null) {
      rowChildren.add(const SizedBox(width: Dimensions.marginS));
      rowChildren.add(suffixIcon!);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: rowChildren,
    );
  }
}
