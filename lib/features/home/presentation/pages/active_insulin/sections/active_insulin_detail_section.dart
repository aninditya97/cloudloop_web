import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/domain/entities/insulin_report_data.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';

class ActiveInsulinDetailSection extends StatelessWidget {
  const ActiveInsulinDetailSection({
    Key? key,
    required this.data,
  }) : super(key: key);

  final InsulinReportData data;

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(Dimens.appPadding),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.blueGray[100]!,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(Dimens.dp8)),
        color: AppColors.blueGray[50],
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
                    text: _l10n.currentBGLevel,
                    textColor: AppColors.blueGray[400],
                  ),
                  const SizedBox(height: Dimens.medium),
                  HeadingText4(
                    text: '${data.meta?.current?.format()} mg/dL',
                  ),
                ],
              ),
              const SizedBox(width: Dimens.dp50),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SubtitleText(
                    text: _l10n.recBolus,
                    textColor: AppColors.blueGray[400],
                  ),
                  const SizedBox(height: Dimens.medium),
                  const HeadingText4(
                    text: '0.425 U',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Dimens.dp12),
        ],
      ),
    );
  }
}
