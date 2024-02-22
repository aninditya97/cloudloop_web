import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class Skeleton extends StatelessWidget {
  const Skeleton({
    Key? key,
    this.baseColor,
    this.highlightColor,
    this.width,
    this.height,
    this.radius,
  }) : super(key: key);

  final Color? baseColor;
  final Color? highlightColor;
  final double? width;
  final double? height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius ?? 4),
        gradient: LinearGradient(
          colors: [
            highlightColor ?? context.theme.dividerColor,
            baseColor ?? context.theme.dividerColor.withOpacity(0.5),
          ],
        ),
      ),
      child: SizedBox(
        width: width,
        height: height,
      ),
    );
  }
}
