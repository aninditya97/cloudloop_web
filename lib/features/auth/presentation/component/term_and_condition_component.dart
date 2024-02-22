import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';

class TermsAndConditionComponent extends StatefulWidget {
  const TermsAndConditionComponent({
    Key? key,
    this.onSubmit,
    required this.onCheck,
  }) : super(key: key);

  final VoidCallback? onSubmit;
  final ValueChanged<bool> onCheck;

  @override
  State<TermsAndConditionComponent> createState() =>
      _TermsAndConditionComponentState();
}

class _TermsAndConditionComponentState
    extends State<TermsAndConditionComponent> {
  bool _isChecked = false;
  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return Column(
      // mainAxisAlignment: MainAxisAlignment.end,
      // crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Checkbox(
              value: _isChecked,
              onChanged: (bool? value) {
                setState(() {
                  _isChecked = value!;
                });
                widget.onCheck.call(value!);
              },
            ),
            HeadingText4(
              text: _l10n.agreement,
              textColor: AppColors.blueGray[400],
            ),
            HeadingText4(
              text: _l10n.termsAndCondition,
              textColor: AppColors.primarySolidColor,
            ),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
                horizontal: Dimens.appPadding,
              ) +
              const EdgeInsets.only(bottom: Dimens.dp24),
          child: ElevatedButton(
            onPressed: _isChecked == true ? widget.onSubmit : null,
            child: HeadingText4(
              text: _l10n.next,
              textColor: AppColors.whiteColor,
            ),
          ),
        ),
      ],
    );
  }
}
