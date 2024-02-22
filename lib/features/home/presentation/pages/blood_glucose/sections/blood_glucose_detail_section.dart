import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';

class BloodGlucoseDetailSection extends StatelessWidget {
  const BloodGlucoseDetailSection({
    Key? key,
    required this.data,
  }) : super(key: key);

  final GlucoseReportData data;

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(Dimens.appPadding),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.blueGray[100]!,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(Dimens.medium),
        ),
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
                  const SizedBox(height: Dimens.dp8),
                  HeadingText4(
                    text: '${(data.meta?.current ?? 0.0).format()} mg/dL',
                  ),
                  const SizedBox(height: Dimens.dp8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SubtitleText(
                        text: _l10n.avgBGLevel,
                        textColor: AppColors.blueGray[400],
                      ),
                      const SizedBox(height: Dimens.dp2),
                      HeadingText4(
                        text: '${data.meta?.average ?? 0.0.format()} mg/dL',
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
                    text: _l10n.higestLevel,
                    textColor: AppColors.blueGray[400],
                  ),
                  const SizedBox(height: Dimens.dp8),
                  HeadingText4(
                    text: '${(data.meta?.highest ?? 0.0).format()} mg/dL',
                  ),
                  const SizedBox(height: Dimens.dp8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SubtitleText(
                        text: _l10n.bgPrediction,
                        textColor: AppColors.blueGray[400],
                      ),
                      const SizedBox(height: Dimens.dp2),
                      const HeadingText4(
                        text: 'Eventually 90 mg/dL',
                      ),
                    ],
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
