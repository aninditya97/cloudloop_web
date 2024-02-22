import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/home/presentation/pages/active_carb/sections/section.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class ActiveCarbDetail extends StatelessWidget {
  const ActiveCarbDetail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<CarbohydrateReportBloc>(),
      child: const ActiveCarbView(),
    );
  }
}

class ActiveCarbView extends StatefulWidget {
  const ActiveCarbView({Key? key}) : super(key: key);

  @override
  State<ActiveCarbView> createState() => _ActiveCarbViewState();
}

class _ActiveCarbViewState extends State<ActiveCarbView> {
  late DateTimeRange? _date;

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
    context.read<CarbohydrateReportBloc>().add(
          CarbohydrateReportFetched(
            startDate: _date!.start,
            endDate: _date!.end,
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
                MainAssets.foodToastIcon,
                width: Dimens.dp20,
              ),
              const SizedBox(width: Dimens.dp6),
              HeadingText2(
                text: _l10n.activeCarb,
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
                    _fetchData();
                  });
                },
              ),
            ),
            BlocBuilder<CarbohydrateReportBloc, CarbohydrateReportState>(
              builder: (context, state) {
                if (state is CarbohydrateReportSuccess) {
                  return Column(
                    children: [
                      const SizedBox(height: Dimens.dp20),
                      ChartSection(data: state.data),
                      Padding(
                        padding: const EdgeInsets.all(Dimens.appPadding),
                        child: ActiveCarbDetailSection(data: state.data),
                      ),
                      const LargeDivider(),
                      const SizedBox(height: Dimens.appPadding),
                      ActiveCarbLogSection(
                        data: state.data,
                        onTapInput: _onNavigateToAddCarbohydratePage,
                      ),
                    ],
                  );
                }

                return const LoadingSection();
              },
            ),
          ],
        ),
        bottomNavigationBar: PrimaryButton(
          onPressed: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (builder) => const ActiveCarbInputPage(),
              ),
            );
          },
          buttonTitle: _l10n.inputCarb,
          buttonWidth: Dimens.width(context),
          horizontalPadding: Dimens.appPadding,
          verticalPadding: Dimens.appPadding,
        ),
      ),
    );
  }

  Future _onNavigateToAddCarbohydratePage() async {
    final isSuccess = await Navigator.push<Object>(
      context,
      MaterialPageRoute(
        builder: (builder) => const ActiveCarbInputPage(),
      ),
    );

    if (isSuccess == true) {
      _fetchData();
    }
  }
}
