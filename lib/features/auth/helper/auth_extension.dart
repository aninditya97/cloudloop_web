import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/auth/presentation/blocs/authentication/authentication_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AuthenticationX on BuildContext {
  UserProfile? get user => BlocProvider.of<AuthenticationBloc>(this).state.user;
}
