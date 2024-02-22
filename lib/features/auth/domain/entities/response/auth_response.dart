import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:equatable/equatable.dart';

class AuthResponse extends Equatable {
  const AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: StringParser.parse(json['token']),
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String token;
  final UserProfile user;

  @override
  List<Object?> get props => [token, user];
}
