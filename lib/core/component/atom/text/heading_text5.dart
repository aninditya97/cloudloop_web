import 'package:cloudloop_mobile/core/preferences/text_styles.dart';
import 'package:flutter/material.dart';

class HeadingText5 extends StatelessWidget {
  const HeadingText5({
    Key? key,
    required this.text,
    this.textColor,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  final String text;
  final Color? textColor;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyles.heading5.copyWith(
        color: textColor,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
