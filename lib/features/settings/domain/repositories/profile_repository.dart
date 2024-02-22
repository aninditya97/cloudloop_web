import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/core/database/database.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// {@template profile_repository}
/// A repository which manages the Profile
/// {@endtemplate}
abstract class ProfileRepository {
  /// Get current profile Profile, when successfully return [UserProfile]
  /// if there is an error will throw an error [ErrorException].
  Future<UserProfile> profile();

  /// Request update current Profile
  /// return [bool] on success
  /// if there is an error will throw an error [ErrorException].
  Future<bool> updateProfile(Map<String, dynamic> data);
}

/// {@template profile_repository_impl}
/// A repository implementation from ProfileRepository
/// {@endtemplate}
class ProfileRepositoryImpl
    with ServiceNetworkHandlerMixin
    implements ProfileRepository {
  const ProfileRepositoryImpl({
    required this.httpClient,
    required this.localDatabase,
    required this.checkConnection,
  });

  final Dio httpClient;
  final DatabaseHelper localDatabase;
  final NetworkInfo checkConnection;

  @override
  Future<UserProfile> profile() async {
    if (await checkConnection.isConnected) {
      return get<UserProfile>(
        '/users/me',
        httpClient: httpClient,
        onSuccess: (response) async {
          return UserProfile.fromJson(
            (response.data as Map)['data'] as Map<String, dynamic>,
          );
        },
      );
    } else {
      final result = await localDatabase.queryAllRows(
        table: DatabaseUtils.mySelfTable,
      );
      return UserProfile.fromJson(
        result.first,
      );
    }
  }

  @override
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (await checkConnection.isConnected) {
      final queueList = <Map<String, dynamic>>[];

      final userId = await localDatabase.query(
        table: DatabaseUtils.mySelfTable,
        columnName: 'id',
      );
      await userId.moveNext();

      final body = {
        'temporary_id': const Uuid().v4(),
        'user_id': userId.current['id'],
        'name': data['name'].toString(),
        'birthDate': data['birthDate'].toString(),
        'gender': data['gender'].toString(),
        'diabetesType': data['diabetesType'].toString(),
        'weight': data['weight'].toString(),
        'totalDailyDose': data['totalDailyDose'].toString(),
        'updated_at': DateTime.now().toIso8601String()
      };

      final updatedAt = await localDatabase.query(
        table: DatabaseUtils.mySelfTable,
        columnName: 'updated_at',
      );
      await updatedAt.moveNext();

      if (updatedAt.current['updated_at'] != null) {
        queueList.add(body);

        return post<bool>(
          '/users/me/update/sync',
          httpClient: httpClient,
          payload: queueList,
          onSuccess: (response) async => true,
        );
      }

      return put<bool>(
        '/users/me',
        httpClient: httpClient,
        payload: data,
        onSuccess: (response) async {
          return true;
        },
      );
    } else {
      final userId = await localDatabase.query(
        table: DatabaseUtils.mySelfTable,
        columnName: 'id',
      );
      await userId.moveNext();

      final body = {
        'temporary_id': const Uuid().v4(),
        'id': userId.current['id'],
        'name': data['name'].toString(),
        'birthDate': data['birthDate'].toString(),
        'gender': data['gender'].toString(),
        'diabetesType': data['diabetesType'].toString(),
        'weight': data['weight'].toString(),
        'totalDailyDose': data['totalDailyDose'].toString(),
        'updated_at': DateTime.now().toIso8601String()
      };
      final status = await localDatabase.insert(
        DatabaseUtils.mySelfTable,
        body,
      );
      return status > 0;
    }
  }
}
