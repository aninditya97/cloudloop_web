import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';

class AlertSettingSection extends StatelessWidget {
  const AlertSettingSection({Key? key}) : super(key: key);

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
                Icons.notifications_outlined,
              ),
              const SizedBox(width: Dimens.dp14),
              MenuTitleText(
                text: l10n.alertAndNotification,
                textColor: AppColors.blueGray[800],
              )
            ],
          ),
        ),
        const Divider(thickness: 1),
        const AlertSettingComponent(),
      ],
    );
  }
}
