import 'package:background/background_scope.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/auth/presentation/pages/index/section/section.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<GoogleAuthBloc>(),
      child: const AuthView(),
    );
  }
}

class AuthView extends StatefulWidget {
  const AuthView({Key? key}) : super(key: key);

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool _isLoadingDialogOpen = false;

  @override
  Widget build(BuildContext context) {
//kai_20231030 kodingwork added
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (BackgroundScope.statusOf(context).isClosed) {
          BackgroundScope.openOf(context);
        }
      },
    );

    final _l10n = context.l10n;
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.primarySolidColor,
          body: BlocListener<GoogleAuthBloc, GoogleAuthState>(
            listener: (context, state) {
              if (state is GoogleAuthFailure) {
                _dismissLoadingDialog();
                _onAuthenticationFailure(state.failure);
              } else if (state is GoogleAuthPreSuccess) {
                _dismissLoadingDialog();
                _onAuthenticationSuccess(state.credential);
              } else if (state is GoogleAuthSuccessAuthenticated) {
                _dismissLoadingDialog();
                _onLoginAuthenticationSuccess(state.user);
              } else if (state is GoogleAuthLoading) {
                _showLoadingDialog();
              }
            },
            child: SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Dimens.appPadding),
                    child: AuthHeaderSection(state: state),
                  ),
                  const AuthMainSection(),
                  LoginButton(
                    onPressed: () {
                      context.read<GoogleAuthBloc>().add(
                            const GoogleAuthRequested(),
                          );
                    },
                    loginButtonIcon: MainAssets.googleIcon,
                    loginButtonTitle: _l10n.googleLogin,
                  ),
                  //kai_20231004
                  /*
                  Text(
                    ' by Curestream' ,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                    ),
                    textAlign: TextAlign.center,
                  ),
		*/
                  /*
                  Image.asset(
                    MainAssets.curestreamlogo,
                    width: 135,
                    height: Dimens.dp18,
                    alignment: Alignment.center,
                   // color: AppColors.blackTextColor,
                  ),
		*/
                  Image.asset(
                    MainAssets.curestreamIcon,
                    width: 40,
                    height: 40,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onAuthenticationFailure(ErrorException failure) {
    context.showErrorSnackBar(failure.message);
  }

  Future _onAuthenticationSuccess(UserCredential credential) async {
    final bloc = context.read<RegisterBloc>();
    final router = GoRouter.of(context);
    final token = await credential.user?.getIdToken();
    if (token?.isNotEmpty ?? false) {
      bloc.add(RegisterAuthTokenChanged(token!));
      router.push('/auth/first-step');
    }
  }

  void _onLoginAuthenticationSuccess(UserProfile user) {
    context.read<AuthenticationBloc>().add(AuthenticationLoginRequested(user));
  }

  void _showLoadingDialog() {
    if (!_isLoadingDialogOpen) {
      setState(() {
        _isLoadingDialogOpen = true;
      });

      context.showLoadingDialog().whenComplete(
        () {
          if (mounted) {
            setState(
              () {
                _isLoadingDialogOpen = false;
              },
            );
          }
        },
      );
    }
  }

  void _dismissLoadingDialog() {
    if (_isLoadingDialogOpen) {
      Navigator.of(context).pop();
    }
  }
}
