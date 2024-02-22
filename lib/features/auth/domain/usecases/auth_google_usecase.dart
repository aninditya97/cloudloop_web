import 'dart:async';
import 'dart:developer';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthGoogleUseCase
    implements UseCaseFuture<ErrorException, UserCredential, NoParams> {
  const AuthGoogleUseCase(this.googleSignIn);

  final GoogleSignIn googleSignIn;

  @override
  FutureOr<Either<ErrorException, UserCredential>> call(NoParams params) async {
    try {
      // å
      final user = await googleSignIn.signIn();
      final googleAuth = await user?.authentication;
      print(
          'your akses token ${googleAuth?.accessToken} && your id token ${googleAuth?.idToken}');

      // if (googleAuth?.accessToken == null || googleAuth?.idToken == null) {
      //   return const Left(ErrorCodeException(message: ''));
      // }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      return Right(userCredential);
    } on FirebaseAuthException catch (error) {
      return Left(
        GeneralServerException(message: error.message ?? '', code: error.code),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
      return Left(ErrorCodeException(message: error.toString()));
    }
  }
}
