part of 'profile_bloc.dart';

enum ProfileBlocStatus { loading, success, failure }

class ProfileState extends Equatable {
  const ProfileState._({
    this.status = ProfileBlocStatus.loading,
    this.error,
    this.user,
  });

  const ProfileState.loading() : this._();

  const ProfileState.success(UserProfile user)
      : this._(
          user: user,
          status: ProfileBlocStatus.success,
        );

  const ProfileState.failure(ErrorException error)
      : this._(
          error: error,
          status: ProfileBlocStatus.failure,
        );

  final ProfileBlocStatus status;
  final UserProfile? user;
  final ErrorException? error;

  @override
  List<Object?> get props => [status, user, error];
}
