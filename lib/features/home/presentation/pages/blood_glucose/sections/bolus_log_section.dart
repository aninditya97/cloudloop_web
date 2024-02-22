import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/home/presentation/components/component.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';

class BolusLogSection extends StatelessWidget {
  const BolusLogSection({Key? key, required this.data}) : super(key: key);

  final GlucoseReportData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimens.appPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.appPadding),
            child: HeadingText4(
              text: context.l10n.insertedBolusLog,
            ),
          ),
          const SizedBox(height: Dimens.appPadding),
          for (final item in data.items) ...[
            BolusLogComponent(
              isColored: false,
              mgDebt: '${item.value.format()} mg/dL',
              date: item.time,
            ),
          ],
        ],
      ),
    );
  }
}
