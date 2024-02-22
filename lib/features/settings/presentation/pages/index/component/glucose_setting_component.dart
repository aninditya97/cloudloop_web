import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/features/settings/presentation/presentation.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GlucoseSettingComponent extends StatefulWidget {
  const GlucoseSettingComponent({
    Key? key,
    required this.dailyDose,
  }) : super(key: key);

  final double dailyDose;

  @override
  State<GlucoseSettingComponent> createState() => _GlucoseComponentState();
}

class _GlucoseComponentState extends State<GlucoseSettingComponent> {
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
        title: Text(context.l10n.totalDailyDose),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeadingText4(text: '${widget.dailyDose.format()} U'),
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
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _UpdateValueSheet(dailyDose: widget.dailyDose);
      },
    );

    final total = double.tryParse(result ?? '');

    if (total != null) {
      bloc.add(ProfileDailyDoseUpdated(total));
    }
  }
}

class _UpdateValueSheet extends StatefulWidget {
  const _UpdateValueSheet({
    Key? key,
    required this.dailyDose,
  }) : super(key: key);

  final double dailyDose;

  @override
  State<_UpdateValueSheet> createState() => _UpdateValueSheetState();
}

class _UpdateValueSheetState extends State<_UpdateValueSheet> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ActionableContentSheet(
      header: HeadingText2(text: l10n.totalDailyDose),
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
                text: l10n.currentTarget,
                textColor: AppColors.blueGray[600],
              ),
              const SizedBox(height: Dimens.small),
              HeadingText4(
                text: '${widget.dailyDose.format()} mg/dL',
                textColor: AppColors.blueGray[400],
              ),
            ],
          ),
          const SizedBox(height: Dimens.dp32),
          CustomTextField(
            formLabel: l10n.changeTarget,
            hintText: l10n.inputFieldHint(l10n.totalDailyDose),
            controller: _controller,
            inputType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
