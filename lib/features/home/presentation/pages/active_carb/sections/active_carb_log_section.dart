import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/home/presentation/components/component.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';

class ActiveCarbLogSection extends StatelessWidget {
  const ActiveCarbLogSection({
    Key? key,
    required this.data,
    this.onTapInput,
  }) : super(key: key);

  final CarbohydrateReportData data;
  final VoidCallback? onTapInput;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.appPadding),
          child: HeadingText4(
            text: context.l10n.activeCarbLog,
          ),
        ),
        const SizedBox(height: Dimens.appPadding),
        for (final item in data.items) ...[
          BolusLogComponent(
            isColored: false,
            leading:
                Image.network(item.foodType?.image ?? '', width: Dimens.dp24),
            mgDebt: '${item.value.format()}g',
            date: item.time,
          ),
        ],
        // PrimaryButton(
        //   onPressed: onTapInput,
        //   buttonTitle: 'Input Carb',
        //   buttonWidth: Dimens.width(context),
        //   horizontalPadding: Dimens.appPadding,
        //   verticalPadding: Dimens.appPadding,
        // )
      ],
    );
  }
}
