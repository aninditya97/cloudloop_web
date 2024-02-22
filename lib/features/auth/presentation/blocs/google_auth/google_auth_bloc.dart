import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'google_auth_event.dart';
part 'google_auth_state.dart';

class GoogleAuthBloc extends Bloc<GoogleAuthEvent, GoogleAuthState> {
  GoogleAuthBloc({
    required this.authGoogle,
    required this.loginFirebase,
  }) : super(const GoogleAuthInitial()) {
    on<GoogleAuthRequested>(_onRequestAuthentication);
  }

  final AuthGoogleUseCase authGoogle;
  final LoginFirebaseUsecase loginFirebase;

  Future _onRequestAuthentication(
    GoogleAuthRequested event,
    Emitter<GoogleAuthState> emit,
  ) async {
    try {
      emit(const GoogleAuthInitial());
      emit(const GoogleAuthLoading());

      final result = await authGoogle(const NoParams());
      if (emit.isDone) return;

      ErrorException? error;
      UserCredential? credential;

      result.fold(
        (failure) {
          error = failure;
        },
        (successData) {
          credential = successData;
        },
      );

      if (error != null) {
        emit(
          GoogleAuthFailure(error!),
        );
        return;
      } else {
        // Check login
        final firebaseToken =
            await FirebaseAuth.instance.currentUser?.getIdToken();
        final loginResult = await loginFirebase(
          LoginFirebaseParams(token: firebaseToken ?? ''),
        );

        emit(
          loginResult.fold(
            (failure) {
              if (failure.code == 'BAD_REQUEST_ERROR' ||
                  failure.code == 'EMAIL_NOT_REGISTERED') {
                return GoogleAuthPreSuccess(credential!);
              }

              return GoogleAuthFailure(failure);
            },
            GoogleAuthSuccessAuthenticated.new,
          ),
        );
      }
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
      emit(GoogleAuthFailure(ErrorCodeException(message: error.toString())));
    }
  }
}
