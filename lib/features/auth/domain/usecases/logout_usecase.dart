import 'dart:async';
import 'dart:developer';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LogoutUsecase implements UseCaseFuture<ErrorException, bool, NoParams> {
  const LogoutUsecase({
    required this.repository,
    required this.googleSignIn,
    required this.firebaseAuth,
  });

  final AuthRepository repository;
  final GoogleSignIn googleSignIn;
  final FirebaseAuth firebaseAuth;

  @override
  FutureOr<Either<ErrorException, bool>> call(NoParams params) async {
    try {
      await googleSignIn.disconnect().onError((error, stackTrace) {
        log(error.toString());
        return null;
      });
      await firebaseAuth.signOut();
      return Right(await repository.logout());
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}
