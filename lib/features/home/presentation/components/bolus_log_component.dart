import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BolusLogComponent extends StatelessWidget {
  const BolusLogComponent({
    Key? key,
    this.isColored,
    this.mgDebt,
    this.date,
    this.leading,
  }) : super(key: key);

  final bool? isColored;
  final String? mgDebt;
  final DateTime? date;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Dimens.dp32,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.appPadding,
      ),
      decoration: BoxDecoration(
        color: isColored == true ? AppColors.blueGray[100] : Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              leading ??
                  const Icon(
                    Icons.circle_outlined,
                    size: Dimens.dp8,
                    color: AppColors.primarySolidColor,
                  ),
              const SizedBox(width: Dimens.dp12),
              HeadingText4(
                text: '$mgDebt',
              ),
            ],
          ),
          SubtitleText(
            text: date != null
                ? DateFormat('HH:mm dd/MM/yyyy').format(date!)
                : '',
          ),
        ],
      ),
    );
  }
}
