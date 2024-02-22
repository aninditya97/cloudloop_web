import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class LargeDivider extends StatelessWidget {
  const LargeDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: Dimens.dp20,
      thickness: Dimens.dp6,
      color: AppColors.blueGray[100],
    );
  }
}
