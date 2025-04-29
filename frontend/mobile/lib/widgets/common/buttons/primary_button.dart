import 'package:flutter/material.dart';
import 'package:hapti_talk/constants/colors.dart';
import 'package:hapti_talk/constants/dimensions.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double width;
  final double height;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color bgColor;
  final Color textColor;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const PrimaryButton({
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
    this.bgColor = AppColors.primaryColor,
    this.textColor = Colors.white,
    this.prefixIcon,
    this.suffixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: (isLoading || isDisabled) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? AppColors.lightGrayColor : bgColor,
          foregroundColor: textColor,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
          elevation: 0,
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
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
