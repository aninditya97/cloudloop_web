import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/auth/presentation/blocs/blocs.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectGenderSection extends StatelessWidget {
  const SelectGenderSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimens.appPadding,
      ),
      child: BlocBuilder<RegisterBloc, RegisterState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeadingText4(
                text: _l10n.sex,
              ),
              const SizedBox(
                height: Dimens.medium,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  border: Border.all(
                    color: state.gender.value == Gender.male
                        ? AppColors.primarySolidColor
                        : theme.dividerColor,
                  ),
                ),
                child: RadioListTile<Gender>(
                  dense: false,
                  tileColor: AppColors.whiteColor,
                  controlAffinity: ListTileControlAffinity.trailing,
                  title: Row(
                    children: [
                      const InkWell(
                        child: Icon(
                          Icons.male_sharp,
                          color: AppColors.primaryMutedColor,
                          size: Dimens.dp30,
                        ),
                      ),
                      const SizedBox(width: Dimens.dp14),
                      BodyText(
                        text: _l10n.male,
                      ),
                    ],
                  ),
                  value: Gender.male,
                  groupValue: state.gender.value,
                  onChanged: (_) {
                    context
                        .read<RegisterBloc>()
                        .add(const RegisterGenderChanged(Gender.male));
                  },
                ),
              ),
              const SizedBox(height: Dimens.dp10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  border: Border.all(
                    color: state.gender.value == Gender.female
                        ? AppColors.primarySolidColor
                        : theme.dividerColor,
                  ),
                ),
                child: RadioListTile<Gender>(
                  dense: false,
                  tileColor: AppColors.whiteColor,
                  controlAffinity: ListTileControlAffinity.trailing,
                  title: Row(
                    children: [
                      InkWell(
                        child: Icon(
                          Icons.female_sharp,
                          color: AppColors.rose[300],
                          size: Dimens.dp30,
                        ),
                      ),
                      const SizedBox(width: Dimens.dp14),
                      BodyText(
                        text: _l10n.female,
                      ),
                    ],
                  ),
                  value: Gender.female,
                  groupValue: state.gender.value,
                  onChanged: (_) {
                    context
                        .read<RegisterBloc>()
                        .add(const RegisterGenderChanged(Gender.female));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
