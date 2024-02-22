import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class ContentSheet extends StatelessWidget {
  const ContentSheet({
    Key? key,
    required this.content,
    this.height,
    this.expandContent = true,
  }) : super(key: key);

  final Widget content;
  final double? height;
  final bool expandContent;

  @override
  Widget build(BuildContext context) {
    final controllerIndicator = Container(
      margin: const EdgeInsets.only(top: Dimens.dp16, bottom: Dimens.dp24),
      width: 80,
      height: 4,
      decoration: BoxDecoration(
        color: context.theme.dividerColor,
        borderRadius: BorderRadius.circular(Dimens.dp4),
      ),
    );

    if (expandContent == true) {
      return AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              controllerIndicator,
              Expanded(
                child: content,
              ),
            ],
          ),
        ),
      );
    } else {
      return AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets,
        duration: const Duration(milliseconds: 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: (Dimens.width(context) / 2) - 40,
              ),
              child: controllerIndicator,
            ),
            content,
          ],
        ),
      );
    }
  }
}
