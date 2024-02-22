import 'dart:async';
import 'package:background/background_scope.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/presentation/pages/index/page.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/AlertPage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/featureFlag.dart';
import 'package:cloudloop_mobile/features/settings/presentation/presentation.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:flutter/material.dart';
import 'package:move_to_background/move_to_background.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  DateTime ctime = DateTime.now();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const HomePage(),
    const SummaryPage(),
    const MainFamilyPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    //kai_20230720  add app context here
    if (USE_APPCONTEXT == true) {
      ConnectivityMgr.setAppContext(context);
    }

    if (USE_ALERT_PAGE_INSTANCE == true) {
      SwitchState.setmAlertPage(const AlertPage());
      SwitchState.setAppContext(context);
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (BackgroundScope.statusOf(context).isClosed) {
          BackgroundScope.openOf(context);
        }
      },
    );

    return WillPopScope(
      onWillPop: () {
        MoveToBackground.moveTaskToBack();
        return Future.value(false);
      }, // this is use to keep the app in background
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.whiteColor,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: _onItemTapped,
          currentIndex: _selectedIndex,
          unselectedItemColor: const Color(0xff94A3B8),
          selectedItemColor: const Color(0xff3267E3),
          iconSize: Dimens.dp32,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: '',
            ),
          ],
        ),
        body: _widgetOptions.elementAt(_selectedIndex),
      ),
    );
  }
}
