// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/core/database/database.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

/// {@template auth_repository}
/// A repository which manages the auth
/// {@endtemplate}
abstract class AuthRepository {
  /// Request login with email, when successfully return [UserProfile]
  /// if there is an error will throw an error [ErrorException].
  ///
  /// Params:
  /// - [body] a payload body to sending to server
  Future<UserProfile> loginWithEmail(Map<String, dynamic> body);

  /// Request login with firebase token, when successfully return [UserProfile]
  /// if there is an error will throw an error [ErrorException].
  ///
  /// Params:
  /// - [token] a firebase auth token user to send server
  Future<UserProfile> loginWithFirebase(String token);

  /// Request register with email, when successfully return [UserProfile]
  /// if there is an error will throw an error [ErrorException].
  ///
  /// Params:
  /// - [body] a payload body to sending to server
  Future<UserProfile> registerWithEmail(Map<String, dynamic> body);

  /// Request login with firebase token, when successfully return [UserProfile]
  /// if there is an error will throw an error [ErrorException].
  ///
  /// Params:
  /// - [body] a payload body to sending to server
  Future<UserProfile> registerWithFirebase(Map<String, dynamic> body);

  /// Request logout and clear all cache in this app
  /// return [bool] with value `true` on success
  /// if there is an error will throw an error [ErrorException].
  Future<bool> logout();

  /// Request save user profile cache
  /// return [bool] with value `true` on success
  /// if there is an error will throw an error [ErrorException].
  Future<bool> saveProfileCache(Map<String, dynamic> data);

  Future<bool> saveToken(String token);
}

/// {@template auth_repository_impl}
/// A repository implementation from AuthRepository
/// {@end_template}
class AuthRepositoryImpl
    with ServiceCacheHandlerMixin, ServiceNetworkHandlerMixin
    implements AuthRepository {
  const AuthRepositoryImpl({
    required this.httpClient,
    required this.cacheClient,
    required this.localDatabase,
  });

  final Dio httpClient;
  final HiveInterface cacheClient;
  final DatabaseHelper localDatabase;

  @override
  Future<UserProfile> loginWithEmail(Map<String, dynamic> body) async {
    return post<UserProfile>(
      '/users/auth/login/email',
      httpClient: httpClient,
      payload: body,
      onSuccess: (response) async {
        final responseData = response.data['data'] as Map<String, dynamic>;
        final result = AuthResponse.fromJson(responseData);
        await saveProfileCache(result.user.toJson());
        await saveToken(result.token);

        return result.user;
      },
    );
  }

  @override
  Future<bool> logout() {
    return deleteCache(
      cacheClient,
      boxKey: AuthCacheKeys.userCacheKey,
      dataKey: AuthCacheKeys.userCacheKey,
      onSuccess: (result) async {
        // await localDatabase.delete(DatabaseUtils.usersTable);
        // await localDatabase.delete(DatabaseUtils.mySelfTable);
        // await localDatabase.delete(DatabaseUtils.familyTable);
        // await localDatabase.delete(DatabaseUtils.familyMemberTable);
        // await localDatabase.delete(DatabaseUtils.foodTypesTable);
        // await localDatabase.delete(DatabaseUtils.glucoseReportMetaLevelTable);
        // await localDatabase.delete(DatabaseUtils.glucoseReportMetaTable);
        // await localDatabase.delete(DatabaseUtils.userCarbohydratesTable);
        // await localDatabase.delete(DatabaseUtils.userBloodGlucoseTable);
        // await localDatabase.delete(DatabaseUtils.userInsulinDeliveriesTable);
        // await localDatabase.delete(DatabaseUtils.familyInvitationLogsTable);

        // await localDatabase.delete(DatabaseUtils.updateFamilyRoleTable);
        // await localDatabase.delete(DatabaseUtils.insertBloodGlucoseTable);
        // await localDatabase.delete(DatabaseUtils.insertInsulinDeliveryTable);
        // await localDatabase.delete(DatabaseUtils.insertCarbohydrateTable);
        // await localDatabase.delete(DatabaseUtils.acceptInvitationTable);
        // await localDatabase.delete(DatabaseUtils.rejectInvitationTable);
        // await localDatabase.delete(DatabaseUtils.insertInvitationTable);
        // await localDatabase.delete(DatabaseUtils.leaveFamilyTable);
        // await localDatabase.delete(DatabaseUtils.removeFamilyMemberTable);
        // await localDatabase.delete(DatabaseUtils.cgmTable);
        // await localDatabase.delete(DatabaseUtils.pumpTable);
        // await localDatabase.delete(DatabaseUtils.announceMealTable);
        // await localDatabase.delete(DatabaseUtils.autoModeTable);
        return result;
      },
    );
  }

  @override
  Future<UserProfile> loginWithFirebase(String token) async {
    return post<UserProfile>(
      '/users/auth/login/firebase',
      httpClient: httpClient,
      payload: {'token': token},
      onSuccess: (response) async {
        final responseData = response.data['data'] as Map<String, dynamic>;
        final result = AuthResponse.fromJson(responseData);
        await saveProfileCache(result.user.toJson());
        await saveToken(result.token);
        // await localDatabase.insert(
        //   DatabaseUtils.mySelfTable,
        //   result.user.toJson(),
        // );

        return result.user;
      },
    );
  }

  @override
  Future<UserProfile> registerWithEmail(Map<String, dynamic> body) async {
    return post<UserProfile>(
      '/users/auth/register',
      httpClient: httpClient,
      payload: body,
      onSuccess: (response) async {
        final responseData = response.data['data'] as Map<String, dynamic>;
        final result = AuthResponse.fromJson(responseData);
        await saveProfileCache(result.user.toJson());
        await saveToken(result.token);

        return result.user;
      },
    );
  }

  @override
  Future<UserProfile> registerWithFirebase(Map<String, dynamic> body) async {
    return post<UserProfile>(
      '/users/auth/register/firebase',
      httpClient: httpClient,
      payload: body,
      onSuccess: (response) async {
        final responseData = response.data['data'] as Map<String, dynamic>;
        final result = AuthResponse.fromJson(responseData);
        await saveProfileCache(result.user.toJson());
        await saveToken(result.token);

        return result.user;
      },
    );
  }

  @override
  Future<bool> saveToken(String token) async {
    final result = await setCache<String?>(
      cacheClient,
      boxKey: AuthCacheKeys.tokenCacheKey,
      dataKey: AuthCacheKeys.tokenCacheKey,
      value: token,
      onSuccess: (result) async => result,
    );

    return result != null;
  }

  @override
  Future<bool> saveProfileCache(Map<String, dynamic> data) async {
    final result = await setCache<String?>(
      cacheClient,
      boxKey: AuthCacheKeys.userCacheKey,
      dataKey: AuthCacheKeys.userCacheKey,
      value: jsonEncode(data),
      onSuccess: (result) async => result,
    );

    return result != null;
  }
}
