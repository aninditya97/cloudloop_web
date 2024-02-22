import 'dart:convert';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:hive/hive.dart';

/// {@template User_repository}
/// A repository which manages the User
/// {@endtemplate}
abstract class UserRepository {
  /// Get current profile user, when successfully return [UserProfile]
  /// if there is an error will throw an error [ErrorException].
  Future<UserProfile> profile();

  /// Request current user token
  /// return [String] token on success
  /// if there is an error will throw an error [ErrorException].
  Future<String> token();
}

/// {@template User_repository_impl}
/// A repository implementation from UserRepository
/// {@endtemplate}
class UserRepositoryImpl
    with ServiceCacheHandlerMixin
    implements UserRepository {
  const UserRepositoryImpl({
    required this.cacheClient,
  });

  final HiveInterface cacheClient;

  @override
  Future<UserProfile> profile() async {
    final savedUser = await getCache<String>(
      cacheClient,
      boxKey: AuthCacheKeys.userCacheKey,
      dataKey: AuthCacheKeys.userCacheKey,
    );

    if (savedUser.isEmpty) {
      throw const NotFoundCacheException(message: 'Current user is not found');
    }

    return UserProfile.fromJson(jsonDecode(savedUser) as Map<String, dynamic>);
  }

  @override
  Future<String> token() async {
    final token = await getCache<String>(
      cacheClient,
      boxKey: AuthCacheKeys.tokenCacheKey,
      dataKey: AuthCacheKeys.tokenCacheKey,
    );

    if (token.isEmpty) {
      throw const NotFoundCacheException(
        message: 'Current user token is not found',
      );
    }

    return token;
  }
}
