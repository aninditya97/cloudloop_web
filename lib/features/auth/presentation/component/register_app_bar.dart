import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';

class RegisterAppBar extends StatelessWidget {
  const RegisterAppBar({
    Key? key,
    required this.isSecond,
  }) : super(key: key);

  final bool isSecond;

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return Row(
      children: [
        IconButton(
          onPressed: Navigator.of(context).pop,
          icon: const Icon(
            Icons.chevron_left,
            color: AppColors.primarySolidColor,
          ),
        ),
        const SizedBox(width: Dimens.dp10),
        Expanded(
          child: Column(
            children: [
              HeadingText2(
                text: _l10n.setUpInformation,
                textColor: AppColors.blackTextColor,
              ),
              const SizedBox(height: Dimens.dp6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: Dimens.dp6,
                    width: Dimens.dp100,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                      color: AppColors.primarySolidColor,
                    ),
                  ),
                  const SizedBox(width: Dimens.small),
                  Container(
                    width: Dimens.dp100,
                    height: Dimens.dp6,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                      color: isSecond
                          ? AppColors.primarySolidColor
                          : AppColors.blue[100],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        InkWell(
          child: Container(
            width: Dimens.dp48,
            height: Dimens.dp48,
            alignment: Alignment.centerRight,
            child: const Icon(
              Icons.info_outline,
              size: Dimens.dp24,
              color: Colors.black,
            ),
          ),
          onTap: () {
            _showDialog(context);
          },
        ),
      ],
    );
  }

  void _showDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AppHelperAlertDialog(
        title: Container(
          padding: const EdgeInsets.only(top: Dimens.dp16),
          child: Column(
            children: const [
              HeadingText2(
                text: 'Help Info',
                textColor: Colors.black,
              ),
              SizedBox(
                height: Dimens.dp8,
              ),
              Divider(
                thickness: 1,
                color: Colors.black,
              )
            ],
          ),
        ),
        body: ListView(
          children: const [
            SizedBox(
              height: Dimens.dp8,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimens.dp16),
              child: Text(
                "Lorem Ipsum is simply dummy text of the printing and typesetting industry. "
                "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, "
                "when an unknown printer took a galley of type and scrambled it to make a type "
                "specimen book. It has survived not only five centuries, but also the leap into "
                "electronic typesetting, remaining essentially unchanged. It was popularised in the "
                "1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more "
                "recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
                "Lorem Ipsum is simply dummy text of the printing and typesetting industry. "
                "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, "
                "when an unknown printer took a galley of type and scrambled it to make a type "
                "specimen book. It has survived not only five centuries, but also the leap into "
                "electronic typesetting, remaining essentially unchanged. It was popularised in the "
                "1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more "
                "recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
                "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, "
                "when an unknown printer took a galley of type and scrambled it to make a type "
                "specimen book. It has survived not only five centuries, but also the leap into "
                "electronic typesetting, remaining essentially unchanged. It was popularised in the "
                "1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more "
                "recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
                textAlign: TextAlign.justify,
              ),
            ),
            SizedBox(
              height: Dimens.dp8,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
