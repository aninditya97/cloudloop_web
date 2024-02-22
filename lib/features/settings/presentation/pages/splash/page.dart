import 'package:cloudloop_mobile/core/database/database_helper.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    DatabaseHelper().initDb();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        if (state.status == AuthenticationStatus.authenticated) {
          return const MainPage();
          //kai_20230615 added
/*
          return MultiProvider(
              providers: [
                // ConnectivityMgr provider instance
                ChangeNotifierProvider(create: (context) => ConnectivityMgr()),
              ], child: const MainPage());
*/

        } else if (state.status == AuthenticationStatus.unauthenticated) {
          return const AuthPage();
        }
        return const Scaffold();
      },
    );
  }
}
