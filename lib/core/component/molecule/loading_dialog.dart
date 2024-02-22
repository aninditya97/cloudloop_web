import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({
    Key? key,
    this.barrierDismissible,
    this.onDismiss,
  }) : super(key: key);

  final bool? barrierDismissible;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return _DialogBackground(
      barrierDismissible: barrierDismissible,
      onDismiss: onDismiss,
      dialog: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.circular(Dimens.dp8),
        ),
        padding: const EdgeInsets.all(Dimens.dp16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: Dimens.dp28,
              height: Dimens.dp28,
              child: CircularProgressIndicator(strokeWidth: 1),
            ),
            const SizedBox(height: Dimens.dp12),
            Text(context.l10n.pleaseWait),
          ],
        ),
      ),
    );
  }
}

class _DialogBackground extends StatelessWidget {
  const _DialogBackground({
    required this.dialog,
    this.barrierDismissible,
    this.onDismiss,
  });

  /// Widget of dialog, you can use NDialog, Dialog,
  ///  AlertDialog or Custom your own Dialog
  final Widget dialog;

  /// Because blur dialog cover the barrier, you have to declare here
  final bool? barrierDismissible;

  /// Action before dialog dismissed
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: WillPopScope(
        onWillPop: () async {
          if (barrierDismissible ?? true) {
            onDismiss?.call();
          }
          Navigator.pop(context);
          return true;
        },
        child: GestureDetector(
          onTap: barrierDismissible ?? true
              ? () {
                  onDismiss?.call();

                  Navigator.pop(context);
                }
              : () {},
          child: IgnorePointer(
            child: Center(
              child: dialog,
            ),
          ),
        ),
      ),
    );
  }
}
