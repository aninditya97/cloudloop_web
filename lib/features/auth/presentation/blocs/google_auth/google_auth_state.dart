part of 'google_auth_bloc.dart';

abstract class GoogleAuthState extends Equatable {
  const GoogleAuthState();

  @override
  List<Object> get props => [];
}

class GoogleAuthInitial extends GoogleAuthState {
  const GoogleAuthInitial();
}

class GoogleAuthLoading extends GoogleAuthState {
  const GoogleAuthLoading();
}

class GoogleAuthPreSuccess extends GoogleAuthState {
  const GoogleAuthPreSuccess(this.credential);

  final UserCredential credential;

  @override
  List<Object> get props => [credential];
}

class GoogleAuthSuccessAuthenticated extends GoogleAuthState {
  const GoogleAuthSuccessAuthenticated(this.user);

  final UserProfile user;

  @override
  List<Object> get props => [user];
}

class GoogleAuthFailure extends GoogleAuthState {
  const GoogleAuthFailure(this.failure);

  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}
