import 'package:flutter/material.dart';
import 'package:haptitalk/constants/colors.dart';
import 'package:haptitalk/constants/dimensions.dart';
import 'package:haptitalk/widgets/common/buttons/primary_button.dart';
import 'package:haptitalk/widgets/common/buttons/secondary_button.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDanger;
  final Widget? icon;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmText = '확인',
    this.cancelText = '취소',
    required this.onConfirm,
    this.onCancel,
    this.isDanger = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: const Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(height: Dimensions.marginM),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: Dimensions.fontL,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: Dimensions.marginM),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: Dimensions.fontM,
              color: AppColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: Dimensions.marginL),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: cancelText,
                  onPressed: () {
                    if (onCancel != null) {
                      onCancel!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  height: Dimensions.buttonHeightM,
                ),
              ),
              const SizedBox(width: Dimensions.marginM),
              Expanded(
                child: PrimaryButton(
                  text: confirmText,
                  onPressed: onConfirm,
                  height: Dimensions.buttonHeightM,
                  bgColor: isDanger ? Colors.red : AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 다이얼로그 표시 헬퍼 메서드
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = '확인',
    String cancelText = '취소',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDanger = false,
    Widget? icon,
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          onConfirm: () {
            Navigator.of(context).pop(true);
            if (onConfirm != null) {
              onConfirm();
            }
          },
          onCancel: () {
            Navigator.of(context).pop(false);
            if (onCancel != null) {
              onCancel();
            }
          },
          isDanger: isDanger,
          icon: icon,
        );
      },
    );

    return result ?? false;
  }
}
