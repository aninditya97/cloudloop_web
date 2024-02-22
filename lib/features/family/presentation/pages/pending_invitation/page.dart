import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/presentation/bloc/blocs.dart';
import 'package:cloudloop_mobile/features/family/presentation/pages/pending_invitation/sections/invitations_data_section.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class PendingInvitationFamilyPage extends StatelessWidget {
  const PendingInvitationFamilyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.I<InvitationsMemberBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<AcceptFamilyInvitationBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<RejectFamilyInvitationBloc>(),
        ),
      ],
      child: const PendingInvitationFamilyView(),
    );
  }
}

class PendingInvitationFamilyView extends StatelessWidget {
  const PendingInvitationFamilyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        foregroundColor: AppColors.primarySolidColor,
        centerTitle: true,
        title: HeadingText4(
          text: context.l10n.pendingInvitation,
          textColor: Colors.black,
        ),
      ),
      body: const InvitationsDataSection(),
    );
  }
}
