import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/home/presentation/pages/active_insulin/sections/section.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class ActiveInsulinDetail extends StatelessWidget {
  const ActiveInsulinDetail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<InsulinReportBloc>(),
      child: const ActiveInsulinView(),
    );
  }
}

class ActiveInsulinView extends StatefulWidget {
  const ActiveInsulinView({Key? key}) : super(key: key);

  @override
  State<ActiveInsulinView> createState() => _ActiveInsulinViewState();
}

class _ActiveInsulinViewState extends State<ActiveInsulinView> {
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
    context.read<InsulinReportBloc>().add(
          InsulinReportFetched(
            startDate: _date!.start,
            endDate: _date!.end,
            filter: _isFilter,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
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
                MainAssets.syringeIcon,
                width: Dimens.dp20,
              ),
              const SizedBox(width: Dimens.dp6),
              HeadingText2(
                text: context.l10n.insulinDelivery,
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
            BlocBuilder<InsulinReportBloc, InsulinReportState>(
              builder: (context, state) {
                if (state is InsulinReportSuccess) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: Dimens.dp20),
                      ChartSection(data: state.data),
                      Padding(
                        padding: const EdgeInsets.all(Dimens.appPadding),
                        child: ActiveInsulinDetailSection(
                          data: state.data,
                        ),
                      ),
                      const LargeDivider(),
                      InsulinBolusLog(
                        data: state.data,
                        onTapInput: _onNavigateToAddInsulinPage,
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
          onPressed: _onNavigateToAddInsulinPage,
          buttonTitle: context.l10n.inputInsertedBolus,
          buttonWidth: Dimens.width(context),
          verticalPadding: Dimens.appPadding,
          horizontalPadding: Dimens.appPadding,
        ),
      ),
    );
  }

  Future _onNavigateToAddInsulinPage() async {
    final isSuccess = await Navigator.push<Object>(
      context,
      MaterialPageRoute(
        builder: (builder) => const ActiveInsulinInputPage(),
      ),
    );
    if (isSuccess == true) {
      _fetchData();
    }
  }
}
