import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/home/presentation/blocs/blocs.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

class BloodGlucoseInputPage extends StatefulWidget {
  const BloodGlucoseInputPage({Key? key}) : super(key: key);

  @override
  State<BloodGlucoseInputPage> createState() => _BloodGlucoseInputPageState();
}

class _BloodGlucoseInputPageState extends State<BloodGlucoseInputPage> {
  bool _isLoadingDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: Navigator.of(context).pop,
        ),
        foregroundColor: AppColors.primarySolidColor,
        backgroundColor: AppColors.whiteColor,
        titleSpacing: Dimens.dp75,
        title: Row(
          children: [
            Image.asset(
              MainAssets.bloodDropIcon,
              width: Dimens.dp20,
            ),
            const SizedBox(width: Dimens.dp6),
            HeadingText2(text: _l10n.bloodGlucose)
          ],
        ),
      ),
      body: BlocConsumer<InputBloodGlucoseBloc, InputBloodGlucoseState>(
        listener: (context, state) {
          if (state.status.isSubmissionInProgress) {
            _showLoadingDialog();
          } else if (state.status.isSubmissionSuccess) {
            _dismissLoadingDialog();
            _onSuccess(_l10n.dataSuccessToEnter);
          } else if (state.status.isSubmissionFailure) {
            _dismissLoadingDialog();
            _onFailure(state.failure!);
          }
        },
        builder: (context, state) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(Dimens.appPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          HeadingText4(text: _l10n.currentBGLevel),
                          HeadingText4(
                            text: '${context.user?.totalDailyDose ?? 0} mg/dL',
                            textColor: AppColors.blueGray[400],
                          ),
                        ],
                      ),
                    ),
                    const LargeDivider(),
                    Padding(
                      padding: const EdgeInsets.all(Dimens.appPadding),
                      child: CustomTextField(
                        formLabel: _l10n.bloodGlucose,
                        hintText: _l10n.inputGlucoseLevel,
                        inputType: TextInputType.number,
                        inputFormatters: [
                          SetDecimalTextInputFormatter(decimalRange: 2)
                        ],
                        onChanged: (value) {
                          context.read<InputBloodGlucoseBloc>().add(
                                InputBloodGlucoseValueChanged(
                                  value: NumParser.tryDoubleParse(value),
                                ),
                              );
                        },
                        suffixIcon: const Padding(
                          padding: EdgeInsets.all(Dimens.appPadding),
                          child: HeadingText4(
                            text: 'mg/dL',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimens.appPadding,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error,
                            size: Dimens.appPadding,
                            color: AppColors.blueGray[300],
                          ),
                          const SizedBox(width: Dimens.appPadding),
                          SubtitleText(
                            text: _l10n.inputManualBGLevel,
                            textColor: AppColors.blueGray[400],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Dimens.appPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PrimaryButton(
                    onPressed: state.status.isValidated
                        ? () {
                            context
                                .read<InputBloodGlucoseBloc>()
                                .add(const InputBloodGlucoseSubmitted());
                          }
                        : null,
                    buttonTitle: _l10n.save,
                    buttonWidth: Dimens.width(context),
                  ),
                  SecondaryButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    buttonTitle: _l10n.discard,
                    buttonWidth: Dimens.width(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog() {
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

  void _onSuccess(String message) {
    context.showSuccessSnackBar(message);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        context.hideCurrentSnackBar();
        Navigator.pop(context, true);
      }
    });
  }
}
