import 'package:flutter/material.dart';
import 'package:hapti_talk/constants/dimensions.dart';

class BaseCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final VoidCallback? onTap;

  const BaseCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(Dimensions.paddingM),
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(Dimensions.radiusL),
    ),
    this.boxShadow,
    this.border,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
