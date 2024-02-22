import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class ActionableContentSheet extends StatelessWidget {
  const ActionableContentSheet({
    Key? key,
    this.header,
    required this.content,
    this.actions,
  }) : super(key: key);

  final Widget? header;
  final Widget content;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return ContentSheet(
      expandContent: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.dp16,
              ),
              child: header,
            ),
            const SizedBox(height: Dimens.dp10),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: Dimens.dp16),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.dp16,
            ),
            child: content,
          ),
          if (actions != null) ...[
            const SizedBox(height: Dimens.dp24),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.dp16,
                vertical: Dimens.dp8,
              ),
              child: SafeArea(child: actions!),
            )
          ],
        ],
      ),
    );
  }
}
