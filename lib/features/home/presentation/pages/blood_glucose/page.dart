import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/presentation/blocs/blocs.dart';
import 'package:cloudloop_mobile/features/home/presentation/pages/blood_glucose/blood_glucose_input_page.dart';
import 'package:cloudloop_mobile/features/home/presentation/pages/blood_glucose/sections/section.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class BloodGlucoseDetail extends StatelessWidget {
  const BloodGlucoseDetail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<GlucoseReportBloc>(),
      child: const BloodGlucoseView(),
    );
  }
}

class BloodGlucoseView extends StatefulWidget {
  const BloodGlucoseView({Key? key}) : super(key: key);

  @override
  State<BloodGlucoseView> createState() => _BloodGlucoseViewState();
}

class _BloodGlucoseViewState extends State<BloodGlucoseView> {
  late DateTimeRange? _date;
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

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: () async {
        _fetchData();
      },
      child: Scaffold(
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
              HeadingText2(
                text: _l10n.bloodGlucose,
              )
            ],
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: Dimens.appPadding,
                left: Dimens.appPadding,
                right: Dimens.appPadding,
              ),
              child: DateDropdownComponent(
                value: _date!,
                onChanged: (date, text) {
                  setState(() {
                    _date = date;
                    _isFilter = true;
                    _fetchData();
                  });
                },
              ),
            ),
            BlocBuilder<GlucoseReportBloc, GlucoseReportState>(
              builder: (context, state) {
                if (state is GlucoseReportSuccess) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Dimens.dp20),
                      ChartSection(data: state.data),
                      Padding(
                        padding: const EdgeInsets.all(Dimens.appPadding),
                        child: BloodGlucoseDetailSection(data: state.data),
                      ),
                      const LargeDivider(),
                      BolusLogSection(data: state.data),
                      // PrimaryButton(
                      //   onPressed: _onNavigateToAddGlucosePage,
                      //   buttonWidth: Dimens.width(context),
                      //   verticalPadding: Dimens.appPadding,
                      //   horizontalPadding: Dimens.appPadding,
                      //   buttonTitle: 'Input BG Manual',
                      // )
                    ],
                  );
                }
                return const LoadingSection();
              },
            ),
          ],
        ),
        bottomNavigationBar: PrimaryButton(
          onPressed: _onNavigateToAddGlucosePage,
          buttonWidth: Dimens.width(context),
          verticalPadding: Dimens.appPadding,
          horizontalPadding: Dimens.appPadding,
          buttonTitle: _l10n.inputBGManual,
        ),
      ),
    );
  }

  Future _onNavigateToAddGlucosePage() async {
    final isSuccess = await Navigator.push<Object>(
      context,
      MaterialPageRoute(
        builder: (builder) => const BloodGlucoseInputPage(),
      ),
    );

    if (isSuccess == true) {
      _fetchData();
    }
  }
}
