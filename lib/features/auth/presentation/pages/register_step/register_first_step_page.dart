import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/presentation/blocs/blocs.dart';
import 'package:cloudloop_mobile/features/auth/presentation/component/component.dart';
import 'package:cloudloop_mobile/features/auth/presentation/pages/register_step/sections/section.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RegisterFirstStepPage extends StatefulWidget {
  const RegisterFirstStepPage({Key? key}) : super(key: key);

  @override
  State<RegisterFirstStepPage> createState() => _RegisterFirstStepPageState();
}

class _RegisterFirstStepPageState extends State<RegisterFirstStepPage> {
  final birthDayController = TextEditingController();

  @override
  void initState() {
    _resetPreviousInputAndSetup();
    super.initState();
  }

  void _resetPreviousInputAndSetup() {
    final bloc = context.read<RegisterBloc>()
      ..add(const RegisterRequestResetted());

    final dateOfBirth = bloc.state.dateOfBirth.value;
    if (dateOfBirth != null) {
      birthDayController.text = DateFormat('dd MMMM yyyy').format(dateOfBirth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;

    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: AppColors.whiteColor,
              automaticallyImplyLeading: false,
              title: const RegisterAppBar(isSecond: false),
            ),
            body: Stack(
              children: [
                ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimens.appPadding,
                        vertical: Dimens.dp24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            formLabel: _l10n.fullName,
                            hintText: _l10n.yourName,
                            onChanged: (value) {
                              context.read<RegisterBloc>().add(
                                    RegisterFullNameChanged(value),
                                  );
                            },
                            errorText: state.fullName.invalid
                                ? _l10n.invalidInputMustLength(
                                    _l10n.fullName,
                                    '4',
                                  )
                                : null,
                          ),
                          const SelectGenderSection(),
                          CustomTextField(
                            formLabel: _l10n.dateOfBirth,
                            hintText: 'dd/mm/yyyy',
                            readOnly: true,
                            controller: birthDayController,
                            suffixIcon: const Icon(Icons.date_range),
                            onTap: _onPickDatePicker,
                            errorText: state.dateOfBirth.invalid
                                ? _l10n
                                    .invalidInputCannotEmpty(_l10n.dateOfBirth)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: PrimaryButton(
                    onPressed: state.fullName.valid && state.dateOfBirth.valid
                        ? () {
                            // context.push('/auth/second-step');
                          }
                        : null,
                    buttonTitle: _l10n.next,
                    horizontalPadding: Dimens.appPadding,
                    verticalPadding: Dimens.dp24,
                    buttonWidth: Dimens.width(context),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future _onPickDatePicker() async {
    final registerBloc = context.read<RegisterBloc>();
    FocusScope.of(context).requestFocus();

    final date = await showDatePicker(
      context: context,
      initialDate: registerBloc.state.dateOfBirth.value ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      registerBloc.add(RegisterDateOfBirthChanged(date));
      birthDayController.text = DateFormat('dd MMMM yyyy').format(date);
    }
  }

  @override
  void dispose() {
    birthDayController.dispose();
    super.dispose();
  }
}
