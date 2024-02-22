import 'package:cloudloop_mobile/core/preferences/colors.dart';
import 'package:cloudloop_mobile/core/preferences/dimens.dart';
import 'package:flutter/material.dart';

class TextStyles {
  const TextStyles._();

  static const TextStyle subtitleText = TextStyle(
    color: AppColors.secondaryTextColor,
    fontWeight: FontWeight.w400,
    fontSize: Dimens.dp12,
  );

  static const TextStyle heading6 = TextStyle(
    color: AppColors.secondaryTextColor,
    fontWeight: FontWeight.w500,
    fontSize: Dimens.dp12,
  );

  static const TextStyle heading5 = TextStyle(
    color: AppColors.primaryTextColor,
    fontWeight: FontWeight.w600,
    fontSize: Dimens.dp12,
  );

  static const TextStyle bodyText = TextStyle(
    color: AppColors.blackTextColor,
    fontWeight: FontWeight.w400,
    fontSize: Dimens.dp14,
  );

  static const TextStyle heading4 = TextStyle(
    color: AppColors.primaryTextColor,
    fontWeight: FontWeight.w500,
    fontSize: Dimens.dp14,
  );

  static const TextStyle heading3 = TextStyle(
    color: AppColors.primaryTextColor,
    fontWeight: FontWeight.w600,
    fontSize: Dimens.dp14,
  );

  static const TextStyle heading2 = TextStyle(
    color: AppColors.primaryTextColor,
    fontWeight: FontWeight.w600,
    fontSize: Dimens.large,
  );

  static const TextStyle menuTitleText = TextStyle(
    color: AppColors.primaryTextColor,
    fontWeight: FontWeight.w500,
    fontSize: Dimens.large,
  );

  static const TextStyle heading1 = TextStyle(
    color: AppColors.blackTextColor,
    fontWeight: FontWeight.w600,
    fontSize: Dimens.dp20,
  );

  static const TextStyle welcomeText = TextStyle(
    color: AppColors.whiteColor,
    fontWeight: FontWeight.w700,
    fontSize: Dimens.dp30,
  );
}
