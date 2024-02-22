import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';

class AuthMainSection extends StatelessWidget {
  const AuthMainSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimens.dp75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            MainAssets.welcomeIllustration,
          ),
          const SizedBox(height: 68),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.appPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WelcomeText(
                  text: _l10n.welcomeTextTitle,
                ),/*
                const WelcomeText(
                  text: 'by Curestream',
                ), */
                const SizedBox(
                  height: Dimens.medium,
                ),
                HeadingText4(
                  text: _l10n.welcomeTextDesc,
                  textColor: AppColors.whiteColor,
                  textHeight: 1.6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
