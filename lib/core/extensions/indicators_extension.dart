import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

/// Extension all about indicators in flutter
extension IndicatorsExtension on BuildContext {
  /// Show Error indicator
  /// [BuildContext] param must child of [Scaffold] widget
  void showErrorSnackBar(String? errorMessage) {
    if (errorMessage != null && errorMessage.isNotEmpty) {
      hideCurrentSnackBar();
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(this).errorColor,
        ),
      );
    }
  }

  /// Show Success indicator snackbar on bottom of screen
  void showSuccessSnackBar(String? successMessage) {
    if (successMessage != null && successMessage.isNotEmpty) {
      hideCurrentSnackBar();
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(
                child: Text(
                  successMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(this).primaryColor,
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
  }

  /// Hide current snackBar, when current scaffold available snackBar active
  void hideCurrentSnackBar() {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..removeCurrentSnackBar();
  }

  Future<void> showLoadingDialog() {
    return showDialog(
      context: this,
      barrierDismissible: false,
      useSafeArea: false,
      barrierColor: Colors.transparent,
      builder: (_) => const LoadingDialog(
        barrierDismissible: false,
      ),
    );
  }
}
