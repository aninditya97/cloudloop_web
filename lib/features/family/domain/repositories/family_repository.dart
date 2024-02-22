import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/core/database/database.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// {@template family_repository}
/// A repository which manages the Family
/// {@endtemplate}
abstract class FamilyRepository {
  /// Get member family, when successfully return [FamilyMemberData]
  /// if there is an error will throw an error [ErrorException].
  ///
  /// Params:
  /// [page] page position
  /// [perPage] total data in each page
  Future<FamilyMemberData> getFamilyMember(
    int page,
    int perPage,
  );

  Future<FamilyData> getFamilyMemberById(int id);

  /// Get member family, when successfully return [FamilyMemberData]
  /// if there is an error will throw an error [ErrorException].
  ///
  /// Params:
  /// [query] query for search
  Future<SearchUserData> searchFamily(
    int page,
    int perPage,
    String? query,
  );

//   /// Get current summary family, when successfully return [SummaryFamily]
//   /// if there is an error will throw an error [ErrorException].
//   ///
//   /// Params:
//   /// - [body] a payload body to sending to server
//   // Future<InputBloodGlucose> sendBloodGlucose(Map<String, dynamic> body);

  /// Get current summary family, when successfully return [bool]
  /// if there is an error will throw an error [ErrorException].
  ///
  /// Params:
  /// - [body] a payload body to sending to server
  Future<bool> inviteFamily(Map<String, dynamic> body);

  Future<bool> syncInviteFamily();

  Future<bool> leaveFamily(int id);

  Future<bool> syncLeaveFamily();

  Future<UserInvitationData> getInvitations(
    int page,
    int perPage,
  );

  Future<bool> acceptFamilyInvitation(int id);

  Future<bool> syncAcceptFamilyInvitation();

  Future<bool> rejectFamilyInvitation(int id);

  Future<bool> syncRejectFamilyInvitation();

  Future<bool> updateFamily(int id, Map<String, dynamic> body);

  Future<bool> syncUpdateFamily();

  Future<bool> removeFamilyMember(int id, Map<String, dynamic> body);

  Future<bool> syncRemoveFamilyMember();
}

// /// {@template family_repository_impl}
// /// A implemented repository of FamilyRepository
// /// {@endtemplate}
class FamilyRepositoryImpl
    with ServiceNetworkHandlerMixin
    implements FamilyRepository {
  const FamilyRepositoryImpl({
    required this.httpClient,
    required this.localDatabase,
    required this.checkConnection,
  });

  final Dio httpClient;
  final DatabaseHelper localDatabase;
  final NetworkInfo checkConnection;

  @override
  Future<FamilyMemberData> getFamilyMember(
    int page,
    int perPage,
  ) async {
    if (await checkConnection.isConnected) {
      return get<FamilyMemberData>(
        '/users/families/members',
        httpClient: httpClient,
        queryParameters: <String, dynamic>{
          'page': page,
          'perPage': perPage,
        },
        onSuccess: (response) async {
          // final result = response.data as Map<String, dynamic>;
          // final familyMember = FamilyMemberData.fromJson(result);
          // if (familyMember.items != null) {
          //   for (final item in familyMember.items!) {
          //     await localDatabase.insertWithRaw(
          //       'INSERT OR REPLACE INTO '
          //       '${DatabaseUtils.familyMemberTable}'
          //       '(id, label, role, user_id, name, email, '
          //       'avatar, password, birth_date, gender, diabetes_type, '
          //       'weight, total_daily_dose, current_blood_glucose_level, '
          //       'current_blood_glucose_value, page) '
          //       'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          //       [
          //         item.id,
          //         item.label,
          //         item.role.toLabel(),
          //         item.user?.id,
          //         item.user?.name,
          //         item.user?.email,
          //         item.user?.avatar,
          //         null,
          //         item.user?.birthDate,
          //         item.user?.gender,
          //         item.user?.diabetesType,
          //         item.user?.weight,
          //         item.user?.totalDailyDose,
          //         item.user?.summary?.carbohydrate?.level,
          //         item.user?.summary?.carbohydrate?.value,
          //         page
          //       ],
          //     );
          //   }
          // }
          return FamilyMemberData.fromJson(
            (response.data as Map) as Map<String, dynamic>,
          );
        },
      );
    } else {
      final result = await localDatabase.queryAllRows(
        table: DatabaseUtils.familyMemberTable,
      );
      final resultList =
          result.map(FamilyMemberTemporaryData.fromJson).toList();
      final familyMemberList = <FamilyData>[];

      for (final item in resultList) {
        final datas = FamilyData(
          id: item.id,
          label: item.label,
          role: item.role,
          user: UserData(
            id: item.userId,
            name: item.name,
            email: item.email,
            avatar: item.avatar,
            birthDate: item.birthDate,
            gender: item.gender,
            diabetesType: item.diabetesType,
            weight: item.weight,
            totalDailyDose: item.totalDailyDose,
            currentBloodGlucose: item.currentBloodGlucose,
          ),
        );

        familyMemberList.add(datas);
      }

      final totalData = await localDatabase.queryRowCount(
        DatabaseUtils.familyMemberTable,
      );
      return FamilyMemberData(
        items: familyMemberList,
        meta: MetaData(
          page: page,
          perPage: 10,
          totalData: totalData,
          message: '',
          statusCode: 200,
          totalPage: (totalData / 10).ceil(),
        ),
      );
    }
  }

  @override
  Future<FamilyData> getFamilyMemberById(int id) async {
    if (await checkConnection.isConnected) {
      return get<FamilyData>(
        '/users/families/members/$id',
        httpClient: httpClient,
        onSuccess: (response) async {
          return FamilyData.fromJson(
            (response.data as Map)['data'] as Map<String, dynamic>,
          );
        },
      );
    } else {
      final result = await localDatabase.queryWithClauseRows(
        table: DatabaseUtils.familyMemberTable,
        columnName: 'id',
        argument: id.toString(),
      );
      final data = result.map(FamilyData.fromJson).toList().last;
      return data;
    }
  }

  @override
  Future<SearchUserData> searchFamily(
    int page,
    int perPage,
    String? query,
  ) async {
    if (await checkConnection.isConnected) {
      return get<SearchUserData>(
        '/users',
        httpClient: httpClient,
        queryParameters: <String, dynamic>{
          'page': page,
          'perPage': perPage,
          'search': query
        },
        onSuccess: (response) async {
          // final result = response.data as Map<String, dynamic>;
          // final user = SearchUserData.fromJson(result);
          // if (user.items != null) {
          //   for (final person in user.items!) {
          //     await localDatabase.insertWithRaw(
          //       'INSERT OR REPLACE INTO '
          //       '${DatabaseUtils.usersTable}'
          //       '(id, name, email, '
          //       'avatar, password, birth_date, gender, diabetes_type, '
          //       'weight, total_daily_dose, sent_at, connected_at, '
          //       'status, created_at, updated_at, page) '
          //       'VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          //       [
          //         person.id,
          //         person.name,
          //         person.email,
          //         person.avatar,
          //         null,
          //         person.birthDate,
          //         person.gender,
          //         person.diabetesType,
          //         person.weight,
          //         person.totalDailyDose,
          //         person.connection?.sentAt?.toIso8601String(),
          //         person.connection?.connectedAt?.toIso8601String(),
          //         person.connection?.status.name,
          //         person.createdAt?.toIso8601String(),
          //         person.updatedAt?.toIso8601String(),
          //         page
          //       ],
          //     );
          //   }
          // }
          return SearchUserData.fromJson(
            (response.data as Map) as Map<String, dynamic>,
          );
        },
      );
    } else {
      final result = await localDatabase.queryWithClauseRows(
        table: DatabaseUtils.usersTable,
        columnName: 'name',
        argument: query.toString(),
        limit: 10,
        offset: (page - 1) * 10,
      );

      final resultList = result.map(UserData.fromJson).toList();

      final totalData = await localDatabase.queryRowCount(
        DatabaseUtils.familyMemberTable,
      );
      return SearchUserData(
        items: resultList,
        meta: MetaData(
          page: page,
          perPage: 10,
          totalData: totalData,
          message: '',
          statusCode: 200,
          totalPage: (totalData / 10).ceil(),
        ),
      );
    }
  }

  @override
  Future<bool> inviteFamily(Map<String, dynamic> body) async {
    if (await checkConnection.isConnected) {
      // final result = await localDatabase.queryAllRows(
      //   table: DatabaseUtils.insertInvitationTable,
      // );

      // final invitationList =
      //     result.map(InvitationTemporaryData.fromJson).toList();

      // final targetList = <Map<String, dynamic>>[];

      // final emailList = body['targets'] as List<String>;

      // if (invitationList.isNotEmpty) {
      //   if (emailList.isNotEmpty) {
      //     final userId = await localDatabase.query(
      //       table: DatabaseUtils.mySelfTable,
      //       columnName: 'id',
      //     );
      //     await userId.moveNext();
      //     final map = {
      //       'temporary_id': const Uuid().v4(),
      //       'targets': emailList,
      //       'user_id': userId.current['id'],
      //       'created_at': DateTime.now().toIso8601String(),
      //       'updated_at': DateTime.now().toIso8601String()
      //     };

      //     targetList.add(map);

      //     final invitationList =
      //         result.map(InvitationTemporaryData.fromJson).toList();

      //     for (final person in invitationList) {
      //       final map = {
      //         'temporary_id': person.temporaryId,
      //         'targets': [person.email],
      //         'user_id': person.userId,
      //         'created_at': person.createdAt.toIso8601String(),
      //         'updated_at': person.updatedAt.toIso8601String()
      //       };
      //       targetList.add(map);
      //     }

      //   return post<bool>(
      //     '/users/families/create/sync',
      //     httpClient: httpClient,
      //     payload: targetList,
      //     onSuccess: (response) async {
      //       await localDatabase.delete(DatabaseUtils.insertInvitationTable);
      //       return true;
      //     },
      //   );
      // } else {
      //   for (final person in invitationList) {
      //     final map = {
      //       'temporary_id': person.temporaryId,
      //       'targets': [person.email],
      //       'user_id': person.userId,
      //       'created_at': person.createdAt.toIso8601String(),
      //       'updated_at': person.updatedAt.toIso8601String()
      //     };
      //     targetList.add(map);
      //   }

      //     return post<bool>(
      //       '/users/families/create/sync',
      //       httpClient: httpClient,
      //       payload: targetList,
      //       onSuccess: (response) async {
      //         await localDatabase.delete(DatabaseUtils.insertInvitationTable);
      //         return true;
      //       },
      //     );
      //   }
      // }

      return post<bool>(
        '/users/families',
        httpClient: httpClient,
        payload: body,
        onSuccess: (response) async => true,
      );
    } else {
      final emailList = body['targets'] as List<String>;
      final userId = await localDatabase.query(
        table: DatabaseUtils.mySelfTable,
        columnName: 'id',
      );
      await userId.moveNext();
      final status = await localDatabase.insertWithRaw(
        'INSERT OR REPLACE INTO '
        '${DatabaseUtils.insertInvitationTable}'
        '(temporary_id, email, user_id, created_at, updated_at) '
        'VALUES(?, ?, ?, ?, ?)',
        [
          const Uuid().v4(),
          emailList[0],
          userId.current['id'],
          DateTime.now().toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );
      return status > 0;
    }
  }

  @override
  Future<bool> syncInviteFamily() async {
    final result = await localDatabase.queryAllRows(
      table: DatabaseUtils.insertInvitationTable,
    );

    final invitationList =
        result.map(InvitationTemporaryData.fromJson).toList();

    final targetList = <Map<String, dynamic>>[];

    if (invitationList.isNotEmpty) {
      final invitationList =
          result.map(InvitationTemporaryData.fromJson).toList();

      for (final person in invitationList) {
        final map = {
          'temporary_id': person.temporaryId,
          'targets': [person.email],
          'user_id': person.userId,
          'created_at': person.createdAt.toIso8601String(),
          'updated_at': person.updatedAt.toIso8601String()
        };
        targetList.add(map);
      }

      return post<bool>(
        '/users/families/create/sync',
        httpClient: httpClient,
        payload: targetList,
        onSuccess: (response) async {
          await localDatabase.delete(DatabaseUtils.insertInvitationTable);
          return true;
        },
      );
    }
    return false;
  }

  @override
  Future<bool> acceptFamilyInvitation(int id) async {
    if (await checkConnection.isConnected) {
      // final queueList = <Map<String, dynamic>>[];

      // final userId = await localDatabase.query(
      //   table: DatabaseUtils.mySelfTable,
      //   columnName: 'id',
      // );
      // await userId.moveNext();

      // final result = await localDatabase.queryAllRows(
      //   table: DatabaseUtils.acceptInvitationTable,
      // );

      // final acceptedQueueList =
      //     result.map(AcceptedTemporaryData.fromJson).toList();

      // if (queueList.isNotEmpty) {
      //   for (final accept in acceptedQueueList) {
      //     queueList.add(accept.toJson());
      //   }

      //   final newUpdate = <String, dynamic>{
      //     'temporary_id': const Uuid().v4(),
      //     'invitation_id': id,
      //     'user_id': userId.current['id'],
      //     'rejected_at': DateTime.now().toIso8601String()
      //   };
      //   queueList.add(newUpdate);

      //   return post<bool>(
      //     '/users/families/invitations/accept/sync',
      //     httpClient: httpClient,
      //     payload: queueList,
      //     onSuccess: (response) async {
      //       await localDatabase.delete(
      //         DatabaseUtils.acceptInvitationTable,
      //       );
      //       return true;
      //     },
      //   );
      // }

      return post<bool>(
        '/users/families/invitations/$id/accept',
        httpClient: httpClient,
        onSuccess: (response) async => true,
      );
    } else {
      final userId = await localDatabase.query(
        table: DatabaseUtils.mySelfTable,
        columnName: 'id',
      );
      await userId.moveNext();
      final body = <String, dynamic>{
        'temporary_id': const Uuid().v4(),
        'invitation_id': id,
        'user_id': userId.current['id'],
        'accepted_at': DateTime.now().toIso8601String()
      };
      final status = await localDatabase.insert(
        DatabaseUtils.acceptInvitationTable,
        body,
      );
      return status > 0;
    }
  }

  @override
  Future<bool> syncAcceptFamilyInvitation() async {
    final queueList = <Map<String, dynamic>>[];

    final userId = await localDatabase.query(
      table: DatabaseUtils.mySelfTable,
      columnName: 'id',
    );
    await userId.moveNext();

    final result = await localDatabase.queryAllRows(
      table: DatabaseUtils.acceptInvitationTable,
    );

    final acceptedQueueList =
        result.map(AcceptedTemporaryData.fromJson).toList();

    if (queueList.isNotEmpty) {
      for (final accept in acceptedQueueList) {
        queueList.add(accept.toJson());
      }

      return post<bool>(
        '/users/families/invitations/accept/sync',
        httpClient: httpClient,
        payload: queueList,
        onSuccess: (response) async {
          await localDatabase.delete(
            DatabaseUtils.acceptInvitationTable,
          );
          return true;
        },
      );
    }

    return false;
  }

  @override
  Future<bool> leaveFamily(int id) async {
    // if (await checkConnection.isConnected) {
    //   final result = await localDatabase.queryAllRows(
    //     table: DatabaseUtils.leaveFamilyTable,
    //   );

    //   final leaveQueueList = result.map(LeaveTemporaryData.fromJson).toList();

    //   final queueList = <Map<String, dynamic>>[];

    //   if (leaveQueueList.isNotEmpty) {
    //     for (final person in leaveQueueList) {
    //       final map = {
    //         'temporary_id': person.temporaryId,
    //         'user_id': person.userId,
    //       };
    //       queueList.add(map);
    //     }

    //     return post<bool>(
    //       '/users/families/leave/sync',
    //       httpClient: httpClient,
    //       payload: queueList,
    //       onSuccess: (response) async {
    //         await localDatabase.delete(
    //           DatabaseUtils.leaveFamilyTable,
    //         );
    //         return true;
    //       },
    //     );
    //   } else {
    return post<bool>(
      '/users/families/leave',
      httpClient: httpClient,
      onSuccess: (response) async => true,
    );
    // }
    // } else {
    //   final userId = await localDatabase.query(
    //     table: DatabaseUtils.mySelfTable,
    //     columnName: 'id',
    //   );
    //   await userId.moveNext();
    //   final body = <String, dynamic>{
    //     'temporary_id': const Uuid().v4(),
    //     'user_id': userId.current['id'],
    //   };
    //   final status = await localDatabase.insert(
    //     DatabaseUtils.leaveFamilyTable,
    //     body,
    //   );
    //   await localDatabase.delete(
    //     DatabaseUtils.familyMemberTable,
    //   );
    //   return status > 0;
    // }
  }

  @override
  Future<bool> syncLeaveFamily() async {
    final result = await localDatabase.queryAllRows(
      table: DatabaseUtils.leaveFamilyTable,
    );

    final leaveQueueList = result.map(LeaveTemporaryData.fromJson).toList();

    final queueList = <Map<String, dynamic>>[];

    if (leaveQueueList.isNotEmpty) {
      for (final person in leaveQueueList) {
        final map = {
          'temporary_id': person.temporaryId,
          'user_id': person.userId,
        };
        queueList.add(map);
      }

      return post<bool>(
        '/users/families/leave/sync',
        httpClient: httpClient,
        payload: queueList,
        onSuccess: (response) async {
          await localDatabase.delete(
            DatabaseUtils.leaveFamilyTable,
          );
          return true;
        },
      );
    }

    return false;
  }

  @override
  Future<bool> rejectFamilyInvitation(int id) async {
    if (await checkConnection.isConnected) {
      final queueList = <Map<String, dynamic>>[];

      final userId = await localDatabase.query(
        table: DatabaseUtils.mySelfTable,
        columnName: 'id',
      );
      await userId.moveNext();

      final result = await localDatabase.queryAllRows(
        table: DatabaseUtils.rejectInvitationTable,
      );

      final rejectQueueList =
          result.map(RejactedTemporaryData.fromJson).toList();

      if (rejectQueueList.isNotEmpty) {
        for (final reject in rejectQueueList) {
          queueList.add(reject.toJson());
        }

        final newUpdate = <String, dynamic>{
          'temporary_id': const Uuid().v4(),
          'invitation_id': id,
          'user_id': userId.current['id'],
          'rejected_at': DateTime.now().toIso8601String()
        };
        queueList.add(newUpdate);

        return post<bool>(
          '/users/families/invitations/reject/sync',
          httpClient: httpClient,
          payload: queueList,
          onSuccess: (response) async {
            await localDatabase.delete(
              DatabaseUtils.rejectInvitationTable,
            );
            return true;
          },
        );
      } else {
        return post<bool>(
          '/users/families/invitations/$id/reject',
          httpClient: httpClient,
          onSuccess: (response) async => true,
        );
      }
    } else {
      final userId = await localDatabase.query(
        table: DatabaseUtils.mySelfTable,
        columnName: 'id',
      );
      await userId.moveNext();
      final body = <String, dynamic>{
        'temporary_id': const Uuid().v4(),
        'invitation_id': id,
        'user_id': userId.current['id'],
        'rejected_at': DateTime.now().toIso8601String()
      };
      final status = await localDatabase.insert(
        DatabaseUtils.rejectInvitationTable,
        body,
      );
      return status > 0;
    }
  }

  @override
  Future<bool> syncRejectFamilyInvitation() async {
    final queueList = <Map<String, dynamic>>[];

    final userId = await localDatabase.query(
      table: DatabaseUtils.mySelfTable,
      columnName: 'id',
    );
    await userId.moveNext();

    final result = await localDatabase.queryAllRows(
      table: DatabaseUtils.rejectInvitationTable,
    );

    final rejectQueueList = result.map(RejactedTemporaryData.fromJson).toList();

    if (rejectQueueList.isNotEmpty) {
      for (final reject in rejectQueueList) {
        queueList.add(reject.toJson());
      }

      return post<bool>(
        '/users/families/invitations/reject/sync',
        httpClient: httpClient,
        payload: queueList,
        onSuccess: (response) async {
          await localDatabase.delete(
            DatabaseUtils.rejectInvitationTable,
          );
          return true;
        },
      );
    }

    return false;
  }

  @override
  Future<bool> updateFamily(int id, Map<String, dynamic> body) async {
    if (await checkConnection.isConnected) {
      final result = await localDatabase.queryAllRows(
        table: DatabaseUtils.updateFamilyRoleTable,
      );

      final updateLabelQueueList =
          result.map(UpdateLabelTemporaryData.fromJson).toList();

      final queueList = <Map<String, dynamic>>[];

      if (updateLabelQueueList.isNotEmpty) {
        for (final person in updateLabelQueueList) {
          queueList.add(person.toJson());
        }

        final newUpdate = <String, dynamic>{
          'temporary_id': const Uuid().v4(),
          'family_member_id': id,
          'label': body['label'],
          'updated_at': DateTime.now().toIso8601String()
        };

        queueList.add(newUpdate);

        return post<bool>(
          '/users/families/members/update/sync',
          httpClient: httpClient,
          payload: queueList,
          onSuccess: (response) async {
            await localDatabase.delete(
              DatabaseUtils.updateFamilyRoleTable,
            );
            return true;
          },
        );
      } else {
        return put<bool>(
          '/users/families/members/$id',
          httpClient: httpClient,
          payload: body,
          onSuccess: (response) async => true,
        );
      }
    } else {
      final map = <String, dynamic>{
        'temporary_id': const Uuid().v4(),
        'family_member_id': id,
        'label': body['label'],
        'updated_at': DateTime.now().toIso8601String()
      };
      final status = await localDatabase.insert(
        DatabaseUtils.updateFamilyRoleTable,
        map,
      );

      await localDatabase.update(
        DatabaseUtils.familyMemberTable,
        <String, dynamic>{'label': body['label']},
        'id',
        id,
      );
      return status > 0;
    }
  }

  @override
  Future<bool> syncUpdateFamily() async {
    final result = await localDatabase.queryAllRows(
      table: DatabaseUtils.updateFamilyRoleTable,
    );

    final updateLabelQueueList =
        result.map(UpdateLabelTemporaryData.fromJson).toList();

    final queueList = <Map<String, dynamic>>[];

    if (updateLabelQueueList.isNotEmpty) {
      for (final person in updateLabelQueueList) {
        queueList.add(person.toJson());
      }

      return post<bool>(
        '/users/families/members/update/sync',
        httpClient: httpClient,
        payload: queueList,
        onSuccess: (response) async {
          await localDatabase.delete(
            DatabaseUtils.updateFamilyRoleTable,
          );
          return true;
        },
      );
    }

    return false;
  }

  @override
  Future<bool> removeFamilyMember(int id, Map<String, dynamic> body) async {
    if (await checkConnection.isConnected) {
      final queueList = <Map<String, dynamic>>[];

      final userId = await localDatabase.query(
        table: DatabaseUtils.mySelfTable,
        columnName: 'id',
      );
      await userId.moveNext();

      final result = await localDatabase.queryAllRows(
        table: DatabaseUtils.removeFamilyMemberTable,
      );

      final removeQueueList = result.map(RemoveTemporaryData.fromJson).toList();

      if (removeQueueList.isNotEmpty) {
        for (final remove in removeQueueList) {
          final map = {
            'temporary_id': remove.temporaryId,
            'family_member_id': remove.familyMemberId,
            'user_id': remove.userId,
            'deleted_at': remove.deletedAt.toIso8601String()
          };
          queueList.add(map);
        }

        final newUpdate = <String, dynamic>{
          'temporary_id': const Uuid().v4(),
          'family_member_id': id,
          'user_id': userId.current['id'],
          'deleted_at': DateTime.now().toIso8601String()
        };
        queueList.add(newUpdate);

        return post<bool>(
          '/users/families/members/remove/sync',
          httpClient: httpClient,
          payload: queueList,
          onSuccess: (response) async {
            await localDatabase.delete(
              DatabaseUtils.removeFamilyMemberTable,
            );
            return true;
          },
        );
      } else {
        return delete<bool>(
          '/users/families/members/$id',
          httpClient: httpClient,
          onSuccess: (response) async => true,
        );
      }
    } else {
      final userId = await localDatabase.query(
        table: DatabaseUtils.mySelfTable,
        columnName: 'id',
      );
      await userId.moveNext();
      final body = <String, dynamic>{
        'temporary_id': const Uuid().v4(),
        'family_member_id': id,
        'user_id': userId.current['id'],
        'deleted_at': DateTime.now().toIso8601String()
      };
      final status = await localDatabase.insert(
        DatabaseUtils.removeFamilyMemberTable,
        body,
      );
      return status > 0;
    }
  }

  @override
  Future<bool> syncRemoveFamilyMember() async {
    final queueList = <Map<String, dynamic>>[];

    final userId = await localDatabase.query(
      table: DatabaseUtils.mySelfTable,
      columnName: 'id',
    );
    await userId.moveNext();

    final result = await localDatabase.queryAllRows(
      table: DatabaseUtils.removeFamilyMemberTable,
    );

    final removeQueueList = result.map(RemoveTemporaryData.fromJson).toList();

    if (removeQueueList.isNotEmpty) {
      for (final remove in removeQueueList) {
        final map = {
          'temporary_id': remove.temporaryId,
          'family_member_id': remove.familyMemberId,
          'user_id': remove.userId,
          'deleted_at': remove.deletedAt.toIso8601String()
        };
        queueList.add(map);
      }

      return post<bool>(
        '/users/families/members/remove/sync',
        httpClient: httpClient,
        payload: queueList,
        onSuccess: (response) async {
          await localDatabase.delete(
            DatabaseUtils.removeFamilyMemberTable,
          );
          return true;
        },
      );
    }

    return false;
  }

  @override
  Future<UserInvitationData> getInvitations(
    int page,
    int perPage,
  ) async {
    if (await checkConnection.isConnected) {
      return get<UserInvitationData>(
        '/users/families/invitations',
        httpClient: httpClient,
        queryParameters: <String, dynamic>{
          'status': 'PENDING',
          'page': page,
          'perPage': perPage,
        },
        onSuccess: (response) async {
          return UserInvitationData.fromJson(
            (response.data as Map) as Map<String, dynamic>,
          );
        },
      );
    } else {
      final result = await localDatabase.queryAllRows(
        table: DatabaseUtils.familyInvitationLogsTable,
      );
      final resultList = result.map(InvitationData.fromJson).toList();

      final totalData = await localDatabase.queryRowCount(
        DatabaseUtils.familyMemberTable,
      );

      return UserInvitationData(
        meta: MetaData(
          page: page,
          perPage: 10,
          totalData: totalData,
          message: '',
          statusCode: 200,
          totalPage: (totalData / 10).ceil(),
        ),
        items: resultList,
      );
    }
  }
}
