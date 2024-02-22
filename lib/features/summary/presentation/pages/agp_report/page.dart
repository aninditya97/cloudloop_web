import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:cloudloop_mobile/features/summary/presentation/pages/pdf_preview.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class AGPReportPage extends StatelessWidget {
  const AGPReportPage({
    Key? key,
    required this.dateRange,
  }) : super(key: key);

  final DateTimeRange dateRange;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<AgpReportBloc>(),
      child: _AGPReportView(
        dateRange: dateRange,
      ),
    );
  }
}

class _AGPReportView extends StatefulWidget {
  const _AGPReportView({
    Key? key,
    required this.dateRange,
  }) : super(key: key);

  final DateTimeRange dateRange;

  @override
  State<_AGPReportView> createState() => _AGPReportViewState();
}

class _AGPReportViewState extends State<_AGPReportView> {
  late DateTimeRange? _date;
  UserProfile? _user;

  void _initalizeDateNow() {
    _date = widget.dateRange;
  }

  @override
  void initState() {
    _initalizeDateNow();
    _fetchUserData().whenComplete(_fetchData);

    super.initState();
  }

  void _fetchData() {
    context.read<AgpReportBloc>().add(
          AgpReportFetched(
            page: 1,
            startDate: _date?.start,
            endDate: _date!.end,
            userId: int.parse(_user!.id),
          ),
        );
  }

  Future<void> _fetchUserData() async {
    _user = (await GetIt.I<GetProfileUseCase>().call(
      const NoParams(),
    ))
        .foldRight(
      const UserProfile(
        gender: Gender.female,
        name: '',
        id: '',
        weight: 0,
        totalDailyDose: 0,
      ),
      (r, previous) => r,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        foregroundColor: AppColors.primarySolidColor,
        centerTitle: true,
        title: HeadingText2(
          text: context.l10n.agpReport,
          textColor: Colors.black,
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<AgpReportBloc, AgpReportState>(
          builder: (context, state) {
            if (state is AgpReportSuccess) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(Dimens.appPadding),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.name,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text: _user!.name,
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp16),
                          HeadingText4(
                            text: '${DateFormat('yyyy-MM-dd').format(
                              widget.dateRange.start,
                            )} to ${DateFormat('yyyy-MM-dd').format(
                              widget.dateRange.end,
                            )}',
                            textColor: AppColors.blueGray[400],
                          ),
                        ],
                      ),
                    ),
                    const LargeDivider(),
                    Padding(
                      padding: const EdgeInsets.all(Dimens.appPadding),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.averageGlucose,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text:
                                    '${state.data.averageGlucose?.toStringAsFixed(
                                  2,
                                )} mol/L',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.gmi,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text:
                                    '${state.data.gmiPercentage?.toStringAsFixed(
                                  2,
                                )} %',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.gmi,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text:
                                    '${state.data.gmiMmol?.toStringAsFixed(2)} mmol/mol',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.glucoseSD,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text: '${state.data.glucoseSd?.toStringAsFixed(
                                  2,
                                )} mmol/L',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.glucoseCV,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text: '${state.data.glucoseCv?.toStringAsFixed(
                                  2,
                                )} %',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.timeInTarget,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text:
                                    '${state.data.timeInTarget?.toStringAsFixed(
                                  2,
                                )} %',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.timeAboveTarget,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text:
                                    '${state.data.timeAboveTarget?.toStringAsFixed(
                                  2,
                                )} %',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.timeBelowTarget,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text:
                                    '${state.data.timeBelowTarget?.toStringAsFixed(
                                  2,
                                )} %',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.numberHyposDuration,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text:
                                    '${state.data.numberOfHypos?.toStringAsFixed(
                                  2,
                                )}',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.averageHyposDuration,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text:
                                    '${state.data.averageHypoDuration?.toStringAsFixed(
                                  2,
                                )} ${context.l10n.mins}',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.sensorGlucoseAvailability,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text:
                                    '${state.data.sensorGlucoseAvailability?.toStringAsFixed(
                                  2,
                                )} %',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const LargeDivider(),
                    Padding(
                      padding: const EdgeInsets.all(Dimens.appPadding),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.totalDailyDose,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text: '${0.toStringAsFixed(
                                  2,
                                )} U/day',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.totalDailyBolus,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text: '${0.toStringAsFixed(
                                  2,
                                )} U/day',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.totalDailyBasal,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text: '${0.toStringAsFixed(
                                  2,
                                )} U/day',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                        ],
                      ),
                    ),
                    const LargeDivider(),
                    Padding(
                      padding: const EdgeInsets.all(Dimens.appPadding),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.autoModeUse,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text:
                                    '${state.data.autoModeUse?.toStringAsFixed(
                                  2,
                                )} %',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              HeadingText4(
                                text: context.l10n.autoModeInteruppted,
                                textColor: AppColors.blueGray[600],
                              ),
                              HeadingText4(
                                text:
                                    '${state.data.autoModeIntterupted?.toStringAsFixed(
                                  2,
                                )}',
                                textColor: AppColors.blueGray[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimens.dp8),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(Dimens.appPadding),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (builder) => PDFPreviewPage(
                  dateRange: widget.dateRange,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.whiteColor,
            side: BorderSide(
              color: AppColors.blueGray[200]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.download_rounded,
              ),
              const SizedBox(width: Dimens.dp8),
              HeadingText4(
                text: context.l10n.downloadPDF,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
