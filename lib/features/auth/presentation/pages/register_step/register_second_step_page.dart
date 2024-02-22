import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/auth/presentation/blocs/blocs.dart';
import 'package:cloudloop_mobile/features/auth/presentation/component/component.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
// import 'package:go_router/go_router.dart';

class RegisterSecondStepPage extends StatefulWidget {
  const RegisterSecondStepPage({Key? key}) : super(key: key);

  @override
  State<RegisterSecondStepPage> createState() => _RegisterSecondStepPageState();
}

class _RegisterSecondStepPageState extends State<RegisterSecondStepPage> {
  bool _isLoadingDialogOpen = false;
  bool _isValidated = false;
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: AppColors.whiteColor,
          automaticallyImplyLeading: false,
          title: const RegisterAppBar(isSecond: true),
        ),
        body: BlocConsumer<RegisterBloc, RegisterState>(
          listener: (context, state) {
            setState(() {
              _isValidated = state.status.isValidated;
            });
            if (state.status.isSubmissionSuccess) {
              _dismissLoadingDialog();
              _onSubmissionSuccess(state.user);
            } else if (state.status.isSubmissionInProgress) {
              _showLoadingDialog();
            } else if (state.status.isSubmissionFailure) {
              _dismissLoadingDialog();
              context.showErrorSnackBar(state.failure?.message);
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                ListView(
                  children: [
                    // const SelectDiabetesType(),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimens.appPadding,
                        horizontal: Dimens.dp16,
                      ),
                      child: CustomTextField(
                        formLabel: _l10n.weight,
                        hintText: _l10n.inputWeight,
                        inputType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        suffixIcon: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: Dimens.large,
                          ),
                          child: HeadingText4(
                            text: 'Kg',
                          ),
                        ),
                        onChanged: (value) {
                          context.read<RegisterBloc>().add(
                                RegisterWeightChanged(
                                  NumParser.doubleParse(value),
                                ),
                              );
                        },
                        errorText: state.weight.invalid
                            ? _l10n.invalidInput(_l10n.weight)
                            : null,
                      ),
                    ),
                    const SizedBox(
                      height: Dimens.dp32,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimens.dp16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_mode,
                          ),
                          const SizedBox(
                            width: Dimens.dp14,
                          ),
                          MenuTitleText(
                            text: 'Auto Mode',
                            textColor: AppColors.blueGray[800],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: Dimens.dp8,
                    ),
                    const Divider(
                      thickness: 2,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimens.appPadding,
                        horizontal: Dimens.dp16,
                      ),
                      child: CustomTextField(
                        formLabel: _l10n.totalDailyDose,
                        hintText: _l10n.inputDailyDose,
                        suffixIcon: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: Dimens.large,
                          ),
                          child: HeadingText4(
                            text: 'U',
                          ),
                        ),
                        inputType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          context.read<RegisterBloc>().add(
                                RegisterDailyDoseChanged(
                                  NumParser.doubleParse(value),
                                ),
                              );
                        },
                        errorText: state.totalDailyDose.invalid
                            ? _l10n.invalidInput(_l10n.totalDailyDose)
                            : null,
                      ),
                    ),
                    const SizedBox(
                      height: Dimens.dp32,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimens.dp16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.medical_information_outlined,
                          ),
                          const SizedBox(
                            width: Dimens.dp14,
                          ),
                          MenuTitleText(
                            text: 'Manual Mode',
                            textColor: AppColors.blueGray[800],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: Dimens.dp8,
                    ),
                    const Divider(
                      thickness: 2,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimens.appPadding,
                        horizontal: Dimens.dp16,
                      ),
                      child: CustomTextField(
                        formLabel: 'Typical Basal Rate',
                        hintText: 'Input Basal Rate',
                        suffixIcon: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: Dimens.large,
                          ),
                          child: HeadingText4(
                            text: 'U/h',
                          ),
                        ),
                        inputType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'(^-?\d*\.?\d*)'),
                          )
                        ],
                        onChanged: (value) {
                          context.read<RegisterBloc>().add(
                                RegisterTypicalBasalRateChanged(
                                  NumParser.doubleParse(value),
                                ),
                              );
                        },
                        errorText: state.typicalBasalRate.invalid
                            ? _l10n.invalidInput('Typical Basal Rate')
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimens.appPadding,
                        horizontal: Dimens.dp16,
                      ),
                      child: CustomTextField(
                        formLabel: 'Typical Insulin-to-Carb Ratio',
                        hintText: 'Input ICR',
                        suffixIcon: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: Dimens.large,
                            horizontal: Dimens.large,
                          ),
                          child: HeadingText4(
                            text: 'CHO/g',
                          ),
                        ),
                        inputType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          context.read<RegisterBloc>().add(
                                RegisterTypicalICRChanged(
                                  NumParser.doubleParse(value),
                                ),
                              );
                        },
                        errorText: state.typicalICR.invalid
                            ? _l10n.invalidInput(
                                'Typical Insulin-to-Carb Ratio',
                              )
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimens.appPadding,
                        horizontal: Dimens.dp16,
                      ),
                      child: CustomTextField(
                        formLabel: 'Typical Insulin Sensitivity Factor',
                        hintText: 'Input ISF',
                        suffixIcon: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: Dimens.large,
                          ),
                          child: HeadingText4(
                            text: '',
                          ),
                        ),
                        inputType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          context.read<RegisterBloc>().add(
                                RegisterTypicalISFChanged(
                                  NumParser.doubleParse(value),
                                ),
                              );
                        },
                        errorText: state.typicalISF.invalid
                            ? _l10n.invalidInput(
                                'Typical Insulin Sensitivity Factor',
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: TermsAndConditionComponent(
          onCheck: (value) {
            _isChecked = value;
            setState(() {});
          },
          onSubmit: _isChecked
              ? _isValidated
                  ? () {
                      context
                          .read<RegisterBloc>()
                          .add(const RegisterRequestSubmitted());
                    }
                  : null
              : null,
        ),
      ),
    );
  }

  void _onSubmissionSuccess(UserProfile? user) {
    if (user != null) {
      context
          .read<AuthenticationBloc>()
          .add(AuthenticationLoginRequested(user));
      // context.push('/auth/complete');
    }
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
}
