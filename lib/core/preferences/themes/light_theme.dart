import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LightTheme extends BaseTheme {
  LightTheme(this.primaryColor);

  final Color primaryColor;
  static const Color dividerColor = Color(0xFFF5F5F5);

  @override
  ColorScheme get scheme => ColorScheme.light(
        primary: primaryColor,
      );

  @override
  AppBarTheme get appBar => AppBarTheme(
        elevation: 0,
        color: primaryColor,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.dark,
        ),
      );

  @override
  ButtonThemeData get button => ButtonThemeData(
        buttonColor: primaryColor,
        padding: const EdgeInsets.symmetric(
          vertical: Dimens.dp12,
          horizontal: Dimens.dp24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.dp8),
        ),
      );

  @override
  ElevatedButtonThemeData get elevatedButton => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.whiteColor,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.dp8),
          ),
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            vertical: Dimens.dp12,
            horizontal: Dimens.dp24,
          ),
          elevation: 0,
        ),
      );

  @override
  OutlinedButtonThemeData get outlinedButton => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.dp8),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: Dimens.dp12,
            horizontal: Dimens.dp24,
          ),
        ),
      );

  @override
  InputDecorationTheme get inputDecoration {
    final baseBorder = OutlineInputBorder(
      borderSide: const BorderSide(color: dividerColor),
      borderRadius: BorderRadius.circular(Dimens.dp8),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.whiteColor,
      contentPadding: const EdgeInsets.symmetric(
        vertical: Dimens.dp12,
        horizontal: Dimens.appPadding,
      ),
      enabledBorder: baseBorder,
      disabledBorder: baseBorder,
      border: baseBorder,
      focusedBorder:
          baseBorder.copyWith(borderSide: BorderSide(color: primaryColor)),
      focusedErrorBorder:
          baseBorder.copyWith(borderSide: const BorderSide(color: Colors.red)),
      errorBorder:
          baseBorder.copyWith(borderSide: const BorderSide(color: Colors.red)),
    );
  }

  @override
  CardTheme get card => const CardTheme();

  /// theme for [BottomSheet]
  BottomSheetThemeData get bottomSheet => const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimens.dp24),
          ),
        ),
        backgroundColor: Colors.white,
      );

  @override
  ThemeData get data {
    return ThemeData(
      fontFamily: 'Inter',
      primaryColor: primaryColor,
      appBarTheme: appBar,
      buttonTheme: button,
      elevatedButtonTheme: elevatedButton,
      outlinedButtonTheme: outlinedButton,
      inputDecorationTheme: inputDecoration,
      dividerColor: dividerColor,
      cardTheme: card,
      bottomSheetTheme: bottomSheet,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: scheme,
    );
  }
}
