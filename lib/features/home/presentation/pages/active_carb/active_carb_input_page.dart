import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class ActiveCarbInputPage extends StatelessWidget {
  const ActiveCarbInputPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.I<InputCarbohydrateBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<CarbohydrateFoodBloc>(),
        ),
      ],
      child: const ActiveCarbInputView(),
    );
  }
}

class ActiveCarbInputView extends StatefulWidget {
  const ActiveCarbInputView({Key? key}) : super(key: key);

  @override
  State<ActiveCarbInputView> createState() => _ActiveCarbInputViewState();
}

class _ActiveCarbInputViewState extends State<ActiveCarbInputView> {
  bool _isLoadingDialogOpen = false;

  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  @override
  void initState() {
    _fetchFoodType(1);
    super.initState();
  }

  void _fetchFoodType(int page) {
    context.read<CarbohydrateFoodBloc>().add(
          CarbohydrateFoodFetched(page: page, source: 'USER'),
        );
  }

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
              MainAssets.foodToastIcon,
              width: Dimens.dp20,
            ),
            const SizedBox(width: Dimens.dp6),
            HeadingText2(text: _l10n.activeCarb)
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchFoodType(1);
        },
        child: BlocConsumer<InputCarbohydrateBloc, InputCarbohydrateState>(
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

            // set value controller
            _dateController.text = state.date.value != null
                ? DateFormat('dd/MM/yyyy').format(state.date.value!)
                : '';
            _timeController.text = state.time.value != null
                ? state.time.value!.format(context)
                : '';
          },
          builder: (context, state) => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(Dimens.appPadding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              formLabel: _l10n.amountConsume,
                              hintText: _l10n.inputCarb,
                              inputType: TextInputType.number,
                              suffixIcon: const Padding(
                                padding: EdgeInsets.all(Dimens.appPadding),
                                child: HeadingText4(
                                  text: 'g',
                                ),
                              ),
                              inputFormatters: [
                                SetDecimalTextInputFormatter(decimalRange: 2)
                              ],
                              onChanged: (value) {
                                context.read<InputCarbohydrateBloc>().add(
                                      InputCarbohydrateValueChanged(
                                        value: NumParser.tryDoubleParse(value),
                                      ),
                                    );
                              },
                              errorText: state.carbohydrate.invalid
                                  ? _l10n.invalidInput('Carbo')
                                  : null,
                            ),
                            const SizedBox(height: Dimens.appPadding),
                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: CustomTextField(
                                    controller: _dateController,
                                    formLabel: _l10n.time,
                                    hintText: 'dd/mm/yyyy',
                                    readOnly: true,
                                    onTap: _showDatePicker,
                                    suffixIcon:
                                        const Icon(Icons.calendar_month),
                                  ),
                                ),
                                const SizedBox(width: Dimens.small),
                                Expanded(
                                  flex: 3,
                                  child: CustomTextField(
                                    controller: _timeController,
                                    formLabel: '',
                                    hintText: 'hh:mm',
                                    readOnly: true,
                                    suffixIcon: const Icon(Icons.timer),
                                    onTap: () => _showTimePicker(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Dimens.appPadding),
                            HeadingText4(text: _l10n.foodType),
                            const SizedBox(height: Dimens.dp16),
                            const _FoodTypeSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                color: context.theme.scaffoldBackgroundColor,
                padding: const EdgeInsets.all(Dimens.dp16),
                child: Column(
                  children: [
                    PrimaryButton(
                      onPressed: state.status.isValidated
                          ? () {
                              context
                                  .read<InputCarbohydrateBloc>()
                                  .add(const InputCarbohydrateSubmitted());
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
              )
            ],
          ),
        ),
      ),
    );
  }

  Future _showDatePicker() async {
    final now = DateTime.now();
    final bloc = context.read<InputCarbohydrateBloc>();
    final current = bloc.state.date.value;
    final result = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );

    if (result != null) {
      bloc.add(InputCarbohydrateDateChanged(date: result));
    }
  }

  Future _showTimePicker(BuildContext context) async {
    final now = TimeOfDay.now();
    final bloc = context.read<InputCarbohydrateBloc>();
    final current = bloc.state.time.value;
    final result = await showTimePicker(
      context: context,
      initialTime: current ?? now,
    );

    if (result != null) {
      bloc.add(InputCarbohydrateTimeChanged(time: result));
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

  void _onFailure(ErrorException failure) {
    context.showErrorSnackBar(failure.message);
  }

  Future _onSuccess(String message) async {
    context.showSuccessSnackBar(message);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}

class _FoodTypeSection extends StatelessWidget {
  const _FoodTypeSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocBuilder<InputCarbohydrateBloc, InputCarbohydrateState>(
      builder: (context, manipulationState) {
        return BlocBuilder<CarbohydrateFoodBloc, CarbohydrateFoodState>(
          builder: (context, state) {
            if (state is CarbohydrateFoodSuccess) {
              return Column(
                children: [
                  for (final item in state.data.items) ...[
                    RadioListTile<FoodType>(
                      dense: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(
                            Dimens.dp8,
                          ),
                        ),
                        side: manipulationState.foodType.value?.id == item.id
                            ? const BorderSide(
                                color: AppColors.primarySolidColor,
                              )
                            : BorderSide(color: theme.dividerColor),
                      ),
                      tileColor: AppColors.whiteColor,
                      controlAffinity: ListTileControlAffinity.trailing,
                      title: Row(
                        children: [
                          if (item.image.isNotEmpty)
                            Image.network(
                              item.image,
                              width: Dimens.dp32,
                            )
                          else
                            Image.asset(
                              MainAssets.nutIcon,
                              width: Dimens.dp32,
                            ),
                          const SizedBox(width: Dimens.dp12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HeadingText4(
                                  text: item.name,
                                ),
                                SubtitleText(
                                  text: item.description,
                                  textColor: AppColors.blueGray[400],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      value: item,
                      groupValue: manipulationState.foodType.value,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<InputCarbohydrateBloc>().add(
                                InputCarbohydrateFoodTypeChanged(
                                  foodType: value,
                                ),
                              );
                        }
                      },
                    ),
                    const SizedBox(height: Dimens.dp12),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  const Skeleton(width: double.infinity, height: Dimens.dp50),
                  const SizedBox(height: Dimens.dp12),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
