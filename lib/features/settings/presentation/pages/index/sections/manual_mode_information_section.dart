import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/presentation/blocs/authentication/authentication_bloc.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManualModeInformationSection extends StatefulWidget {
  const ManualModeInformationSection({
    Key? key,
  }) : super(key: key);

  @override
  State<ManualModeInformationSection> createState() =>
      _ManualModeInformationSectionState();
}

class _ManualModeInformationSectionState
    extends State<ManualModeInformationSection> {
  bool _isLoadingDialogOpen = false;
  bool _isEdit = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (prev, current) => prev.status != current.status,
      listener: (context, state) {
        if (state.status == ProfileBlocStatus.success) {
          context
              .read<AuthenticationBloc>()
              .add(AuthenticationLoginRequested(state.user!));
          if (_isEdit) {
            _dismissLoadingDialog();
            _onSuccess(context.l10n.dataUpdateSuccessMsg);
            _isEdit = false;
          }
        } else if (state.status == ProfileBlocStatus.failure) {
          _dismissLoadingDialog();
          _onFailure(state.error!);
        } else if (state.status == ProfileBlocStatus.loading) {
          _showLoadingDialog(context);
        }
      },
      builder: (context, state) {
        if (state.user != null) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: Dimens.appPadding,
                  left: Dimens.appPadding,
                  right: Dimens.appPadding,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.medical_information_outlined,
                    ),
                    const SizedBox(width: Dimens.dp14),
                    MenuTitleText(
                      text: context.l10n.manualModeInformation,
                      textColor: AppColors.blueGray[800],
                    )
                  ],
                ),
              ),
              Divider(
                color: AppColors.blueGray[100],
                thickness: 1,
              ),
              SettingMenuTile(
                title:  Text(context.l10n.typicalBasalRate),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HeadingText4(text: '${state.user?.basalRate ?? 0} U/h'),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.theme.primaryColor,
                    ),
                  ],
                ),
                onTap: () {
                  _showUpdateValueSheet(
                    context,
                    1,
                    context.l10n.typicalBasalRate,
                    '${state.user?.basalRate ?? 0} U/h',
                  );
                },
              ),
              SettingMenuTile(
                title:  Text(context.l10n.typicalInsulin2CarbRatio),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HeadingText4(
                      text: '${state.user?.insulinCarbRatio ?? 0} g CHO per U',
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.theme.primaryColor,
                    ),
                  ],
                ),
                onTap: () {
                  _showUpdateValueSheet(
                    context,
                    2,
                    context.l10n.typicalInsulin2CarbRatio,
                    '${state.user?.insulinCarbRatio ?? 0} g CHO per U',
                  );
                },
              ),
              SettingMenuTile(
                title:  Text(context.l10n.typicalInsulinSensitivityFactor),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HeadingText4(
                      text: '${state.user?.insulinSensitivityFactor ?? 0}',
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.theme.primaryColor,
                    ),
                  ],
                ),
                onTap: () {
                  _showUpdateValueSheet(
                    context,
                    3,
                    context.l10n.typicalInsulinSensitivityFactor,
                    '${state.user?.insulinSensitivityFactor ?? 0}',
                  );
                },
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  void _showLoadingDialog(BuildContext context) {
    if (!_isLoadingDialogOpen) {
      setState(() {
        _isLoadingDialogOpen = true;
      });

      context.showLoadingDialog().whenComplete(() {
        if (mounted) {
          setState(() {
            _isLoadingDialogOpen = false;
          });
        }
      });
    }
  }

  void _dismissLoadingDialog() {
    if (_isLoadingDialogOpen) {
      Navigator.of(context).pop();
    }
  }

  void _onFailure(ErrorException failure) {
    context.showErrorSnackBar(failure.message);
  }

  Future _onSuccess(String message) async {
    context.showSuccessSnackBar(message);
  }

  Future _showUpdateValueSheet(
    BuildContext context,
    int type,
    String header,
    String currentValue,
  ) async {
    _isEdit = true;
    final bloc = context.read<ProfileBloc>();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _UpdateValueSheet(
          type: type,
          header: header,
          currentValue: currentValue,
        );
      },
    );

    final total = double.tryParse(result ?? '');

    if (total != null) {
      if (type == 1) {
        bloc.add(
          ProfileTypicalBasalRateUpdated(total),
        );
      } else if (type == 2) {
        bloc.add(
          ProfileTypicalICRUpdated(total),
        );
      } else {
        bloc.add(
          ProfileTypicalISFUpdated(total),
        );
      }
    }
  }
}

class _UpdateValueSheet extends StatefulWidget {
  const _UpdateValueSheet({
    Key? key,
    required this.header,
    required this.type,
    required this.currentValue,
  }) : super(key: key);

  final String header;
  final int type;
  final String currentValue;

  @override
  State<_UpdateValueSheet> createState() => _UpdateValueSheetState();
}

class _UpdateValueSheetState extends State<_UpdateValueSheet> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ActionableContentSheet(
      header: HeadingText2(text: widget.header),
      actions: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _controller.text.trim().isNotEmpty
                ? () {
                    Navigator.pop(context, _controller.text);
                  }
                : null,
            child: Text(l10n.save),
          ),
          const SizedBox(height: Dimens.small),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blueGray,
            ),
            child: Text(l10n.discard),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeadingText4(
                text: l10n.current,
                textColor: AppColors.blueGray[600],
              ),
              const SizedBox(height: Dimens.small),
              HeadingText4(
                text: widget.currentValue,
                textColor: AppColors.blueGray[400],
              ),
            ],
          ),
          const SizedBox(height: Dimens.dp32),
          CustomTextField(
            formLabel: l10n.changeValue,
            hintText: l10n.inputFieldHint(widget.header),
            controller: _controller,
            inputType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'(^-?\d*\.?\d*)'),
              )
            ],
            onChanged: (_) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
