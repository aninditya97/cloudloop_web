import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DiabetesSettingComponent extends StatefulWidget {
  const DiabetesSettingComponent({
    Key? key,
    required this.type,
  }) : super(key: key);

  final DiabetesType type;

  @override
  State<DiabetesSettingComponent> createState() =>
      _DiabetesSettingComponentState();
}

class _DiabetesSettingComponentState extends State<DiabetesSettingComponent> {
  bool _isLoadingDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.status == ProfileBlocStatus.failure) {
          _dismissLoadingDialog();
          _onFailure(state.error!);
        } else if (state.status == ProfileBlocStatus.success) {
          _dismissLoadingDialog();
          _onSuccess('The data has been successfully updated.');
        } else if (state.status == ProfileBlocStatus.loading) {
          _showLoadingDialog(context);
        }
      },
      child: SettingMenuTile(
        title: Text(context.l10n.diabetesType),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeadingText4(text: widget.type.toLabel()),
            Icon(
              Icons.chevron_right_rounded,
              color: context.theme.primaryColor,
            ),
          ],
        ),
        onTap: () => _showUpdateValueSheet(context),
      ),
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

  Future _showUpdateValueSheet(BuildContext context) async {
    final bloc = context.read<ProfileBloc>();
    final result = await showModalBottomSheet<DiabetesType>(
      context: context,
      builder: (BuildContext context) {
        return _UpdateValueSheet(type: widget.type);
      },
    );

    if (result is DiabetesType) {
      bloc.add(ProfileDiabetesTypeUpdated(result));
    }
  }
}

class _UpdateValueSheet extends StatelessWidget {
  const _UpdateValueSheet({Key? key, required this.type}) : super(key: key);

  final DiabetesType type;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return ActionableContentSheet(
      header: HeadingText2(text: l10n.diabetesType),
      content: Column(
        children: [
          RadioListTile<DiabetesType>(
            isThreeLine: true,
            dense: false,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(
                  Dimens.dp8,
                ),
              ),
              side: type == DiabetesType.type1
                  ? BorderSide(color: theme.primaryColor)
                  : BorderSide(color: theme.dividerColor),
            ),
            tileColor: AppColors.whiteColor,
            controlAffinity: ListTileControlAffinity.trailing,
            title: HeadingText4(
              text: l10n.diabetesType1,
            ),
            subtitle: Text(
              l10n.diabetesType1Description,
              style: const TextStyle(
                fontSize: Dimens.dp12,
              ),
            ),
            value: DiabetesType.type1,
            groupValue: type,
            onChanged: (value) {
              Navigator.pop(context, value);
            },
          ),
          const SizedBox(height: Dimens.dp8),
          RadioListTile<DiabetesType>(
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(
                  Dimens.dp8,
                ),
              ),
              side: type == DiabetesType.type2
                  ? BorderSide(color: theme.primaryColor)
                  : BorderSide(color: theme.dividerColor),
            ),
            tileColor: AppColors.whiteColor,
            controlAffinity: ListTileControlAffinity.trailing,
            title: HeadingText4(
              text: l10n.diabetesType2,
            ),
            subtitle: Text(
              l10n.diabetesType2Description,
              style: const TextStyle(
                fontSize: Dimens.dp12,
              ),
            ),
            value: DiabetesType.type2,
            groupValue: type,
            onChanged: (value) {
              Navigator.pop(context, value);
            },
          ),
          const SizedBox(height: Dimens.dp24),
        ],
      ),
    );
  }
}
