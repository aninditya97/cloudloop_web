import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/presentation/blocs/blocs.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/setting_menu_tile.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/sections/sections.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.I<ProfileBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<DisconnectCgmBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<DisconnectPumpBloc>(),
        ),
      ],
      child: const SettingsView(),
    );
  }
}

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
//kai_20230925
  int tapCount = 0;
  int maxTapCount = 6;
  int maxTapIntervalTime = 1000;
  DateTime? lastTapTime = DateTime.now();

  void onTap() {
    final now = DateTime.now();

    if (lastTapTime != null &&
        now.difference(lastTapTime!).inMilliseconds > maxTapIntervalTime) {
      // 마지막 탭 시간이 1초를 초과한 경우 초기화
      tapCount = 0;
    }

    lastTapTime = now;
    setState(() {
      if (tapCount < maxTapCount) {
        tapCount++;
      } else {
        // in case of tapping 6 times continuously, enable test pump age vice versa
        tapCount = 0; // clear tap counter
        if (CspPreference.getBooleanDefaultFalse(CspPreference.pumpTestPage) !=
            true) {
          CspPreference.setBool(CspPreference.pumpTestPage, true);
          showMessage(context, 'Test Pump Page is enabled!!');
        } else {
          CspPreference.setBool(CspPreference.pumpTestPage, false);
          showMessage(context, 'Test Pump Page is disabled!!');
        }
      }
    });
  }

  /*
   * @brief show toast message which selected device type
   */
  void showMessage(BuildContext context, String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  @override
  void initState() {
    _fetchProfileData();
    super.initState();
  }

  void _fetchProfileData() {
    context.read<ProfileBloc>().add(const ProfileFetched());
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.appPadding,
                  vertical: Dimens.dp24,
                ),
                child:
                    //kai_20230925 modified
                    SettingMenuTile(
                  title: Text(
                    context.l10n.settings,
                    style: const TextStyle(
                        fontSize: Dimens.dp20,
                        fontWeight: FontWeight.normal,
                        color: Colors.black),
                  ),
                  onTap: onTap,
                ),
                /*
                CustomAppBar(
                  pageTitle: context.l10n.settings,
                ),
                 */
              ),
              const PersonalDataSection(),
              const ManualModeInformationSection(),
              const InsulinPumpSection(),
              const ContinousGlucoseSection(),
              const GeneralSettingSection(),
              const AlertSettingSection(),
              const SizedBox(height: Dimens.dp24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimens.dp16),
                child: OutlinedButton(
                  onPressed: _onRequestLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.errorColor,
                  ),
                  child: Text(l10n.logOut),
                ),
              ),
              const SizedBox(height: Dimens.dp50),
            ],
          ),
        ),
      ),
    );
  }

  void _onRequestLogout() {
    context
        .read<AuthenticationBloc>()
        .add(const AuthenticationLogoutRequested());
  }
}
