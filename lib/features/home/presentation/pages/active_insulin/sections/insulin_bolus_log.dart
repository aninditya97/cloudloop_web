import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/home/presentation/components/component.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';

class InsulinBolusLog extends StatelessWidget {
  const InsulinBolusLog({
    Key? key,
    required this.data,
    this.onTapInput,
  }) : super(key: key);

  final InsulinReportData data;
  final VoidCallback? onTapInput;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimens.appPadding,
      ),
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
              mgDebt: '${item.value.format()} U',
              date: item.time,
            ),
          ],
          const SizedBox(height: Dimens.appPadding),
          // PrimaryButton(
          //   onPressed: onTapInput,
          //   buttonTitle: 'Input Inserted Bolus',
          //   buttonWidth: Dimens.width(context),
          //   horizontalPadding: Dimens.appPadding,
          // )
        ],
      ),
    );
  }
}
