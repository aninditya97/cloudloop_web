import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    Key? key,
    required this.onPressed,
    required this.buttonTitle,
    this.buttonWidth,
    this.buttonHeight,
    this.horizontalPadding,
    this.verticalPadding,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final String buttonTitle;
  final double? buttonWidth;
  final double? buttonHeight;
  final double? horizontalPadding;
  final double? verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? 0,
        vertical: verticalPadding ?? 0,
      ),
      child: SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: onPressed,
          child: HeadingText3(
            text: buttonTitle,
            textColor: AppColors.whiteColor,
          ),
        ),
      ),
    );
  }
}
