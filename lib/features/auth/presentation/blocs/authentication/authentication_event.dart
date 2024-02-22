part of 'authentication_bloc.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object> get props => [];
}

class AuthenticationLoginRequested extends AuthenticationEvent {
  const AuthenticationLoginRequested(this.user);

  final UserProfile user;

  @override
  List<Object> get props => [user];
}

class AuthenticationLogoutRequested extends AuthenticationEvent {
  const AuthenticationLogoutRequested();
}

class AuthenticationInitialized extends AuthenticationEvent {
  const AuthenticationInitialized();
}
