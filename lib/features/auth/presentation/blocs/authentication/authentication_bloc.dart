import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required this.currentUser,
    required this.logout,
    required this.saveUser,
  }) : super(const AuthenticationState.unknown()) {
    on<AuthenticationInitialized>(_onAuthenticationInitialized);
    on<AuthenticationLoginRequested>(_onAuthenticationLoginRequested);
    on<AuthenticationLogoutRequested>(_onAuthenticationLogoutRequested);
  }

  final LogoutUsecase logout;
  final GetCurrentUserUsecase currentUser;
  final UpdateProfileCacheUseCase saveUser;

  /// Handler when add event to Login
  Future _onAuthenticationLoginRequested(
    AuthenticationLoginRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    try {
      final saveResult =
          await saveUser(UpdateProfileCacheParams(user: event.user));
      if (emit.isDone) return;
      emit(
        saveResult.fold(
          (l) => state,
          (r) => AuthenticationState.authenticated(event.user),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  /// Handler when add event to Logout
  Future _onAuthenticationLogoutRequested(
    AuthenticationLogoutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    try {
      final result = await logout.call(const NoParams());
      if (emit.isDone) return;
      if (result.isRight()) {
        emit(const AuthenticationState.unauthenticated());
      }
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  /// Initialize current user is authenticated or not
  Future _onAuthenticationInitialized(
    AuthenticationInitialized event,
    Emitter<AuthenticationState> emit,
  ) async {
    try {
      final result = await currentUser.call(const NoParams());
      if (emit.isDone) return;
      emit(
        result.fold(
          (failure) => const AuthenticationState.unauthenticated(),
          AuthenticationState.authenticated,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }
}
