import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  const LoginButton({
    Key? key,
    required this.onPressed,
    required this.loginButtonIcon,
    required this.loginButtonTitle,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final String loginButtonTitle;
  final String loginButtonIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Dimens.appPadding),
      height: 48,
      child: MaterialButton(
        onPressed: onPressed,
        color: AppColors.whiteColor,
        textColor: AppColors.blue,
        padding: const EdgeInsets.all(Dimens.dp14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.medium),
          side: BorderSide(color: AppColors.blueGray[200]!),
        ),
        elevation: 0,
        highlightElevation: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              loginButtonIcon,
              height: 24,
            ),
            const SizedBox(
              width: Dimens.dp10,
            ),
            HeadingText4(
              text: loginButtonTitle,
            ),
          ],
        ),
      ),
    );
  }
}
