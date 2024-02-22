import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/presentation/blocs/blocs.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonalDataSection extends StatelessWidget {
  const PersonalDataSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (prev, current) => prev.status != current.status,
      listener: (context, state) {
        if (state.status == ProfileBlocStatus.success) {
          context.read<AuthenticationBloc>().add(
                AuthenticationLoginRequested(
                  state.user!,
                ),
              );
        }
      },
      builder: (context, state) {
        if (state.user != null) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: Dimens.appPadding,
                  right: Dimens.appPadding,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                    ),
                    const SizedBox(
                      width: Dimens.dp14,
                    ),
                    MenuTitleText(
                      text: l10n.personalData,
                      textColor: AppColors.blueGray[800],
                    )
                  ],
                ),
              ),
              Divider(
                color: AppColors.blueGray[100],
                thickness: 1,
              ),
              GlucoseSettingComponent(dailyDose: state.user!.totalDailyDose),
              WeightSettingComponent(weight: state.user!.weight),
            ],
          );
        }
        return const _LoadingContent();
      },
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.dp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: Dimens.dp24, width: Dimens.dp150),
          const SizedBox(height: Dimens.dp32),
          Row(
            children: const [
              Skeleton(height: Dimens.dp16, width: Dimens.dp125),
              Spacer(),
              Skeleton(height: Dimens.dp16, width: Dimens.dp75),
            ],
          ),
          const SizedBox(height: Dimens.dp24),
          Row(
            children: const [
              Skeleton(height: Dimens.dp16, width: Dimens.dp125),
              Spacer(),
              Skeleton(height: Dimens.dp16, width: Dimens.dp75),
            ],
          ),
          const SizedBox(height: Dimens.dp24),
          Row(
            children: const [
              Skeleton(height: Dimens.dp16, width: Dimens.dp125),
              Spacer(),
              Skeleton(height: Dimens.dp16, width: Dimens.dp75),
            ],
          ),
          const SizedBox(height: Dimens.dp24),
          Row(
            children: const [
              Skeleton(height: Dimens.dp16, width: Dimens.dp125),
              Spacer(),
              Skeleton(height: Dimens.dp16, width: Dimens.dp75),
            ],
          ),
        ],
      ),
    );
  }
}
