import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

class RegisterCompletePage extends StatelessWidget {
  const RegisterCompletePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  MainAssets.setUpCompleted,
                  width: 214,
                  height: 278,
                ),
                const SizedBox(height: Dimens.appPadding),
                HeadingText4(
                  text: _l10n.setupFinishedTitle,
                  textColor: AppColors.blueGray,
                ),
                const SizedBox(height: Dimens.small),
                SubtitleText(
                  text: _l10n.setupFinishedDesc,
                  textColor: AppColors.blueGray[400],
                )
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.appPadding,
                vertical: Dimens.dp24,
              ),
              child: ElevatedButton(
                onPressed: () {
                  // context.go('/');
                },
                child: HeadingText4(
                  text: _l10n.next,
                  textColor: AppColors.whiteColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
