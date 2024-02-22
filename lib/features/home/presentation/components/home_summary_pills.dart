import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class HomeSummaryPills extends StatelessWidget {
  const HomeSummaryPills({
    Key? key,
    required this.pillIcon,
    this.pillDesc,
  }) : super(key: key);

  final Widget pillIcon;
  final String? pillDesc;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimens.dp8),
        border: Border.all(
          color: AppColors.blueGray[200]!,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          pillIcon,
          const SizedBox(height: Dimens.dp8),
          if (pillDesc != null)
            Text(
              pillDesc!,
              style: TextStyle(
                fontSize: Dimens.dp10,
                color: AppColors.blueGray[600],
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
