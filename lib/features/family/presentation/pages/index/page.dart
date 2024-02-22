import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/features/family/presentation/pages/index/sections/sections.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class MainFamilyPage extends StatelessWidget {
  const MainFamilyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.I<FamilyMemberBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<InvitationsMemberBloc>(),
        ),
      ],
      child: const _MainFamilyView(),
    );
  }
}

class _MainFamilyView extends StatefulWidget {
  const _MainFamilyView({Key? key}) : super(key: key);

  @override
  State<_MainFamilyView> createState() => _MainFamilyState();
}

class _MainFamilyState extends State<_MainFamilyView> {
  bool _invitationListEmpty = false;
  bool _buildIsFinish = false;

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => setState(() {}),
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          _invitationListEmpty == true ? 60 : 120,
        ), // Set this height
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.appPadding,
            ),
            child: Column(
              children: [
                CustomAppBar(
                  pageTitle: _l10n.family,
                  linkPage: _l10n.addFamily,
                  page: const SearchFamilyPage(),
                ),
                Stack(
                  children: <Widget>[
                    OverlapDataSection(
                      onCheck: (value) {
                        _invitationListEmpty = value;
                        _buildIsFinish = true;
                      },
                    ),
                    if (_buildIsFinish == false) ...[
                      Skeleton(
                        height: Dimens.dp40,
                        width: MediaQuery.of(context).size.width - Dimens.dp16,
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: const FamilysDataSection(),
    );
  }
}
