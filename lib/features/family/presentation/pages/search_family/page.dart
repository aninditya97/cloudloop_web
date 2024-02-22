import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/presentation/bloc/blocs.dart';
import 'package:cloudloop_mobile/features/family/presentation/pages/search_family/sections/sections.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class SearchFamilyPage extends StatelessWidget {
  const SearchFamilyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.I<SearchFamilyBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<InviteFamilyBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<RemoveFamilyMemberBloc>(),
        ),
      ],
      child: const SearchFamilyView(),
    );
  }
}

class SearchFamilyView extends StatefulWidget {
  const SearchFamilyView({Key? key}) : super(key: key);

  @override
  State<SearchFamilyView> createState() => _SearchFamilyViewState();
}

class _SearchFamilyViewState extends State<SearchFamilyView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        foregroundColor: AppColors.primarySolidColor,
        centerTitle: true,
        title: HeadingText2(
          text: context.l10n.searchFamily,
          textColor: Colors.black,
        ),
      ),
      backgroundColor: AppColors.whiteColor,
      body: const SearchFamilysDataSection(),
    );
  }
}
