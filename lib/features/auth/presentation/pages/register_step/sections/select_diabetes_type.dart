import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/presentation/blocs/blocs.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectDiabetesType extends StatelessWidget {
  const SelectDiabetesType({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    // final theme = context.theme;

    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeadingText4(
              text: _l10n.diabetesType,
            ),
            const SizedBox(height: Dimens.dp4),
            // RadioListTile<DiabetesType>(
            //   isThreeLine: true,
            //   dense: true,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: const BorderRadius.all(
            //       Radius.circular(
            //         Dimens.dp8,
            //       ),
            //     ),
            //     side: state.diabetesType.value == DiabetesType.type1
            //         ? const BorderSide(
            //             color: AppColors.primarySolidColor,
            //           )
            //         : BorderSide(color: theme.dividerColor),
            //   ),
            //   tileColor: AppColors.whiteColor,
            //   controlAffinity: ListTileControlAffinity.trailing,
            //   title: HeadingText4(
            //     text: _l10n.diabetesType1,
            //   ),
            //   subtitle: Text(
            //     _l10n.diabetesType1Description,
            //     style: const TextStyle(
            //       fontSize: Dimens.dp12,
            //     ),
            //   ),
            //   value: DiabetesType.type1,
            //   groupValue: state.diabetesType.value,
            //   onChanged: (DiabetesType? value) {
            //     context.read<RegisterBloc>().add(
            //           const RegisterDiabetesTypeChanged(DiabetesType.type1),
            //         );
            //   },
            // ),
            const SizedBox(height: Dimens.dp8),
            // RadioListTile<DiabetesType>(
            //   dense: true,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: const BorderRadius.all(
            //       Radius.circular(
            //         Dimens.dp8,
            //       ),
            //     ),
            //     side: state.diabetesType.value == DiabetesType.type2
            //         ? const BorderSide(
            //             color: AppColors.primarySolidColor,
            //           )
            //         : BorderSide(color: theme.dividerColor),
            //   ),
            //   tileColor: AppColors.whiteColor,
            //   controlAffinity: ListTileControlAffinity.trailing,
            //   title: HeadingText4(
            //     text: _l10n.diabetesType2,
            //   ),
            //   subtitle: Text(
            //     _l10n.diabetesType2Description,
            //     style: const TextStyle(
            //       fontSize: Dimens.dp12,
            //     ),
            //   ),
            //   value: DiabetesType.type2,
            //   groupValue: state.diabetesType.value,
            //   onChanged: (_) {
            //     context.read<RegisterBloc>().add(
            //           const RegisterDiabetesTypeChanged(DiabetesType.type2),
            //         );
            //   },
            // ),
          ],
        );
      },
    );
  }
}
