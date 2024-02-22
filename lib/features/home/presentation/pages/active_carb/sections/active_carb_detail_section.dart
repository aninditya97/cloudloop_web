import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActiveCarbDetailSection extends StatelessWidget {
  const ActiveCarbDetailSection({Key? key, required this.data})
      : super(key: key);

  final CarbohydrateReportData data;

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    final lastConsumed =
        data.items.isNotEmpty ? data.items.last.value.format() : 0;

    final lastDate = data.items.isNotEmpty
        ? DateFormat('HH:mm dd/MM/yyyy').format(data.items.last.time!)
        : '-';

    return Container(
      padding: const EdgeInsets.all(Dimens.appPadding),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.blueGray[100]!,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(Dimens.dp8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeadingText4(
            text: _l10n.detail,
          ),
          const SizedBox(height: Dimens.dp12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SubtitleText(
                    text: _l10n.lastConsumed,
                    textColor: AppColors.blueGray[400],
                  ),
                  const SizedBox(height: Dimens.small),
                  Row(
                    children: [
                      Image.asset(
                        MainAssets.lollipopIcon,
                        width: Dimens.dp20,
                      ),
                      HeadingText4(
                        text: '$lastConsumed g',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: Dimens.dp50),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SubtitleText(
                    text: _l10n.lastUpdate,
                    textColor: AppColors.blueGray[400],
                  ),
                  const SizedBox(height: Dimens.small),
                  HeadingText4(text: lastDate),
                  const SizedBox(height: Dimens.dp8),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
