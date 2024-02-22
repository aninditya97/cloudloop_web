import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class SettingMenuTile extends StatelessWidget {
  const SettingMenuTile({
    Key? key,
    required this.title,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  final Widget title;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Dimens.dp12,
          horizontal: Dimens.dp16,
        ),
        child: Row(
          children: [
            DefaultTextStyle(
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.blueGray,
                fontSize: Dimens.dp14,
              ),
              child: Expanded(
                child: title,
              ),
            ),
            trailing ?? const SizedBox(),
          ],
        ),
      ),
    );
  }
}
