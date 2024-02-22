import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class AppHelperAlertDialog extends StatelessWidget {
  const AppHelperAlertDialog({
    Key? key,
    this.title,
    required this.body,
    this.actions,
  }) : super(key: key);

  final Widget? title;
  final Widget body;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textTheme: TextTheme(
          labelLarge: TextStyle(
            fontSize: Dimens.dp12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      child: AlertDialog(
        title: title,
        titlePadding: EdgeInsets.zero,
        content: body,
        actions: actions,
        actionsPadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        actionsAlignment: MainAxisAlignment.center,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Dimens.dp10,
          ),
        ),
        contentTextStyle: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
