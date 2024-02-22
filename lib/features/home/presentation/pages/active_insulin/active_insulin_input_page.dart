import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/home/presentation/blocs/blocs.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

class ActiveInsulinInputPage extends StatefulWidget {
  const ActiveInsulinInputPage({Key? key}) : super(key: key);

  @override
  State<ActiveInsulinInputPage> createState() => _ActiveInsulinInputViewState();
}

class _ActiveInsulinInputViewState extends State<ActiveInsulinInputPage> {
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
              MainAssets.syringeIcon,
              width: Dimens.dp20,
            ),
            const SizedBox(width: Dimens.dp6),
            HeadingText2(
              text: _l10n.insulinDelivery,
            )
          ],
        ),
      ),
      body: BlocConsumer<InputInsulinBloc, InputInsulinState>(
        listener: (context, state) {
          if (state.status.isSubmissionInProgress) {
            _showLoadingDialog();
          } else if (state.status.isSubmissionSuccess) {
            _dismissLoadingDialog();
            _onSuccess(_l10n.dataSuccessToEnter);
          } else if (state.status.isSubmissionFailure) {
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
                          HeadingText4(
                            text: _l10n.currentBGLevel,
                          ),
                          HeadingText4(
                            text: '${context.user?.totalDailyDose ?? 0} mg/dL',
                            textColor: AppColors.blueGray[400],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimens.appPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          HeadingText4(
                            text: _l10n.recommendedBolus,
                          ),
                          HeadingText4(
                            text: '0.425 U',
                            textColor: AppColors.blueGray[400],
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: Dimens.dp20,
                      thickness: Dimens.dp6,
                      color: AppColors.blueGray[100],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(Dimens.appPadding),
                      child: CustomTextField(
                        inputType: TextInputType.number,
                        formLabel: _l10n.insertedBolus,
                        hintText: _l10n.inputBolus,
                        suffixIcon: const Padding(
                          padding: EdgeInsets.all(Dimens.appPadding),
                          child: HeadingText4(
                            text: 'U',
                          ),
                        ),
                        inputFormatters: [
                          SetDecimalTextInputFormatter(decimalRange: 2)
                        ],
                        onChanged: (value) {
                          context.read<InputInsulinBloc>().add(
                                InputInsulinValueChanged(
                                  value: NumParser.tryDoubleParse(value),
                                ),
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(Dimens.appPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PrimaryButton(
                      onPressed: state.status.isValidated
                          ? () {
                              context
                                  .read<InputInsulinBloc>()
                                  .add(const InputInsulinSubmitted());
                            }
                          : null,
                      buttonTitle: _l10n.save,
                      buttonWidth: Dimens.width(context),
                    ),
                    SecondaryButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      buttonTitle: _l10n.discard,
                      buttonWidth: Dimens.width(context),
                    ),
                  ],
                ),
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

  Future _onSuccess(String message) async {
    context.showSuccessSnackBar(message);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        context.hideCurrentSnackBar();
        Navigator.pop(context, true);
      }
    });
  }
}
