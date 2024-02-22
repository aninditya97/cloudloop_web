import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';

class IllustrationMessage extends StatelessWidget {
  const IllustrationMessage({
    Key? key,
    required this.imagePath,
    required this.title,
    this.onTap,
    this.message,
    this.customWidget,
    this.widthImage,
  }) : super(key: key);

  final String imagePath;
  final String title;
  final VoidCallback? onTap;
  final String? message;
  final Widget? customWidget;
  final double? widthImage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: onTap,
            child: Image.asset(
              imagePath,
              width: 270,
            ),
          ),
          const SizedBox(height: Dimens.appPadding),
          HeadingText5(
            text: title,
            textColor: AppColors.blueGray[600],
          ),
          const SizedBox(height: Dimens.small),
          SubtitleText(
            text: message.toString(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimens.appPadding),
          if (customWidget != null) customWidget! else const SizedBox(),
          // SizedBox(
          //   width: 160,
          //   height: 45,
          //   child:
          //   ElevatedButton(
          //     onPressed: () {
          //       Navigator.push<void>(
          //         context,
          //         MaterialPageRoute(
          //           builder: (builder) => const SearchFamilyPage(),
          //         ),
          //       );
          //     },
          //     child: Center(
          //       child: Row(
          //         children: const [
          //           Icon(Icons.add, size: Dimens.dp18),
          //           SizedBox(width: Dimens.dp6),
          //           HeadingText4(
          //             text: 'Add a Family',
          //             textColor: AppColors.whiteColor,
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
