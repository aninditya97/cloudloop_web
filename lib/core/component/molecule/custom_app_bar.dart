import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({
    Key? key,
    required this.pageTitle,
    this.linkPage,
    this.page,
  }) : super(key: key);

  final String pageTitle;
  final String? linkPage;
  final Widget? page;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        HeadingText1(text: pageTitle),
        TextButton(
          onPressed: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (builder) => page!,
              ),
            );
          },
          child: HeadingText3(
            text: linkPage ?? '',
            textColor: AppColors.primarySolidColor,
          ),
        ),
      ],
    );
  }
}
