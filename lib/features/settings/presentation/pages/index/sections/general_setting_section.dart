import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';

class GeneralSettingSection extends StatelessWidget {
  const GeneralSettingSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: Dimens.appPadding,
            left: Dimens.appPadding,
            right: Dimens.appPadding,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.grid_view,
              ),
              const SizedBox(width: Dimens.dp14),
              MenuTitleText(
                text: l10n.general,
                textColor: AppColors.blueGray[800],
              )
            ],
          ),
        ),
        Divider(
          color: AppColors.blueGray[100],
          thickness: 1,
        ),
        const CountrySettingComponent(),
        const LanguageSettingComponent(),
      ],
    );
  }
}
