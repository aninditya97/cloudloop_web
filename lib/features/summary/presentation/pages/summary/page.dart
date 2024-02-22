import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/summary/presentation/pages/summary/sections/sections.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:get_it/get_it.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<GlucoseReportBloc>(),
      child: const SummaryView(),
    );
  }
}

class SummaryView extends StatefulWidget {
  const SummaryView({Key? key}) : super(key: key);

  @override
  State<SummaryView> createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  late DateTimeRange? _date;
  bool _isLoadingDialogOpen = false;
  bool _isFilter = false;

  void _initalizeDateNow() {
    final _now = DateTime.now();
    _date = DateTimeRange(
      start: DateTime(_now.year, _now.month, _now.day),
      end: DateTime(_now.year, _now.month, _now.day),
    );
  }

  @override
  void initState() {
    _initalizeDateNow();
    _fetchData();
    super.initState();
  }

  void _fetchData() {
    context.read<GlucoseReportBloc>().add(
          GlucoseReportFetched(
            startDate: _date!.start,
            endDate: _date!.end,
            filter: _isFilter,
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

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: () async {
        _fetchData();
      },
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        body: MultiBlocListener(
          listeners: [
            BlocListener<InputBloodGlucoseBloc, InputBloodGlucoseState>(
              listener: (context, state) {
                if (state.status.isSubmissionInProgress) {
                  _showLoadingDialog();
                } else if (state.status.isSubmissionSuccess) {
                  _dismissLoadingDialog();
                  _fetchData();
                } else if (state.status.isSubmissionFailure) {
                  _dismissLoadingDialog();
                  _onFailure(state.failure!);
                }
              },
            ),
            BlocListener<InputInsulinBloc, InputInsulinState>(
              listener: (context, state) {
                if (state.status.isSubmissionInProgress) {
                  _showLoadingDialog();
                } else if (state.status.isSubmissionSuccess) {
                  _dismissLoadingDialog();
                  _fetchData();
                } else if (state.status.isSubmissionFailure) {
                  _dismissLoadingDialog();
                  _onFailure(state.failure!);
                }
              },
            ),
          ],
          child: SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.appPadding,
                    vertical: Dimens.dp24,
                  ),
                  child: Column(
                    children: [
                      CustomAppBar(
                        pageTitle: _l10n.summary,
                        linkPage: _l10n.agpReport,
                        page: AGPReportPage(
                          dateRange: _date!,
                        ),
                      ),
                      const SizedBox(height: Dimens.dp24),
                      DateDropdownComponent(
                        value: _date!,
                        onChanged: (date, text) {
                          setState(() {
                            _date = date;
                            _isFilter = true;
                            _fetchData();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                BlocBuilder<GlucoseReportBloc, GlucoseReportState>(
                  builder: (context, state) {
                    if (state is GlucoseReportSuccess) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: Dimens.dp24),
                          LineChartSection(data: state.data),
                          Divider(
                            thickness: Dimens.small,
                            color: AppColors.blueGray[100],
                          ),
                          RangeChartSection(data: state.data),
                        ],
                      );
                    }
                    return const LoadingSection();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
