import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/core/database/database.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// {@template report_repository}
/// A repository which manages the Report
/// {@endtemplate}
abstract class ReportRepository {
  /// Send new input blood glucose, when successfully return `true`
  /// if there is an error will throw an error [ErrorException].
  ///
  /// Params:
  /// - [bloodGlucoseParams] a payload body to sending to server
  Future<bool> sendBloodGlucose(SendBloodGlucoseParams bloodGlucoseParams);

  /// Send new input insulin, when successfully return `true`
  /// if there is an error will throw an error [ErrorException].
  ///
  /// Params:
  /// - [insulinDelveryParams] a payload body to sending to server
  Future<bool> sendInsulinDelivery(
    SendInsulinDeliveryParams insulinDelveryParams,
  );

  /// Send new input carbohydrate, when successfully return `true`
  /// if there is an error will throw an error [ErrorException].
  ///
  /// Params:
  /// - [body] a payload body to sending to server
  Future<bool> sendCarbohydrate(Map<String, dynamic> body);

  /// Get glucose report, when successfully return [GlucoseReportData]
  /// if there is an error will throw an error [ErrorException].
  ///
  /// Params:
  /// [startDate] start date of report
  /// [endDate] end date of report
  Future<GlucoseReportData> glucoseReports({
    DateTime? startDate,
    DateTime? endDate,
    required bool filter,
  });

  /// Get insulin report, when successfully return [InsulinReportData]
  /// if there is an error will throw an error [ErrorException].
  ///
  /// Params:
  /// [startDate] start date of report
  /// [endDate] end date of report
  Future<InsulinReportData> insulinReports({
    DateTime? startDate,
    DateTime? endDate,
    required bool filter,
  });

  /// Get carbohydrate report, when successfully return [CarbohydrateReportData]
  /// if there is an error will throw an error [ErrorException].
  ///
  /// Params:
  /// [startDate] start date of report
  /// [endDate] end date of report
  Future<CarbohydrateReportData> carbohydrateReports({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// get all of FoodType data, when successfully return [CarbohydrateFoodData]
  /// if there is an error will throw an error [ErrorException].
  Future<CarbohydrateFoodData> carbohydrateFoodData({
    int? page,
    int? perPage,
    String? search,
    String? source,
  });
}

/// {@template report_repository_impl}
/// A implemented repository of ReportRepository
/// {@endtemplate}
class ReportRepositoryImpl
    with ServiceNetworkHandlerMixin
    implements ReportRepository {
  const ReportRepositoryImpl({
    required this.httpClient,
    required this.localDatabase,
    required this.checkConnection,
  });

  final Dio httpClient;
  final DatabaseHelper localDatabase;
  final NetworkInfo checkConnection;

  @override
  Future<bool> sendBloodGlucose(
    SendBloodGlucoseParams bloodGlucoseParams,
  ) async {
    if (await checkConnection.isConnected) {
      final result = await localDatabase.queryAllRows(
        table: DatabaseUtils.insertBloodGlucoseTable,
      );

      if (result.isNotEmpty) {
        final userId = await localDatabase.query(
          table: DatabaseUtils.mySelfTable,
          columnName: 'id',
        );
        await userId.moveNext();

        final currentBloodGlucose = SendBloodGlucoseParams(
          temporaryId: const Uuid().v4(),
          userId: int.parse(userId.current['id'].toString()),
          value: bloodGlucoseParams.value,
          source: bloodGlucoseParams.source,
          time: bloodGlucoseParams.time,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        final bloodGlucoseList = <Map<String, dynamic>>[
          currentBloodGlucose.toJson(),
          ...result
        ];

        return post<bool>(
          '/users/blood-glucoses/create/sync',
          httpClient: httpClient,
          payload: bloodGlucoseList,
          onSuccess: (response) async {
            await localDatabase.delete(DatabaseUtils.insertBloodGlucoseTable);
            await localDatabase.delete(DatabaseUtils.userBloodGlucoseTable);
            return true;
          },
        );
      }

      return post<bool>(
        '/users/blood-glucoses',
        httpClient: httpClient,
        payload: bloodGlucoseParams.toJson(),
        onSuccess: (response) async => true,
      );
    } else {
      final userId = await localDatabase.query(
        table: DatabaseUtils.mySelfTable,
        columnName: 'id',
      );
      await userId.moveNext();

      await _updateBloodGlucoseTable(
        bloodGlucoseParams,
        int.parse(userId.current['id'].toString()),
      );

      final status = await localDatabase.insertWithRaw(
        'INSERT INTO '
        '${DatabaseUtils.insertBloodGlucoseTable}'
        '(temporary_id, time, value, source, user_id, created_at, updated_at)'
        ' VALUES(?, ?, ?, ?, ?, ?, ?)',
        [
          const Uuid().v4(),
          DateTime.now().toIso8601String(),
          bloodGlucoseParams.value,
          bloodGlucoseParams.source,
          userId.current['id'],
          DateTime.now().toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );
      return status > 0;
    }
  }

  @override
  Future<bool> sendInsulinDelivery(
    SendInsulinDeliveryParams insulinDelveryParams,
  ) async {
    if (await checkConnection.isConnected) {
      final result = await localDatabase.queryAllRows(
        table: DatabaseUtils.insertInsulinDeliveryTable,
      );

      if (result.isNotEmpty) {
        final userId = await localDatabase.query(
          table: DatabaseUtils.mySelfTable,
          columnName: 'id',
        );
        await userId.moveNext();

        final currentInsulinDeliveries = SendInsulinDeliveryParams(
          temporaryId: const Uuid().v4(),
          userId: int.parse(userId.current['id'].toString()),
          value: insulinDelveryParams.value,
          source: insulinDelveryParams.source,
          time: insulinDelveryParams.time,
          announceMealEnabled: insulinDelveryParams.announceMealEnabled,
          autoModeEnabled: insulinDelveryParams.autoModeEnabled,
          iob: insulinDelveryParams.iob,
          hypoPrevention: insulinDelveryParams.hypoPrevention,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        final insulinDelivaryList = <Map<String, dynamic>>[
          currentInsulinDeliveries.toJson(),
          ...result
        ];
        return post<bool>(
          '/users/insulin-deliveries/create/sync',
          httpClient: httpClient,
          payload: insulinDelivaryList,
          onSuccess: (response) async {
            await localDatabase
                .delete(DatabaseUtils.insertInsulinDeliveryTable);
            await localDatabase
                .delete(DatabaseUtils.userInsulinDeliveriesTable);
            return true;
          },
        );
      }
      return post<bool>(
        '/users/insulin-deliveries',
        httpClient: httpClient,
        payload: insulinDelveryParams.toJson(),
        onSuccess: (response) async => true,
      );
    } else {
      final userId = await localDatabase.query(
        table: DatabaseUtils.mySelfTable,
        columnName: 'id',
      );
      await userId.moveNext();

      await _updateInsulinDeliveyTable(
        insulinDelveryParams,
        int.parse(
          userId.current['id'].toString(),
        ),
      );

      final status = await localDatabase.insertWithRaw(
        'INSERT INTO '
        '${DatabaseUtils.insertInsulinDeliveryTable}'
        '(temporary_id, time, value, source, user_id, announce_meal_enabled, '
        'auto_mode_enabled, iob, hypoPrevention, created_at, updated_at)'
        ' VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          const Uuid().v4(),
          DateTime.now().toIso8601String(),
          insulinDelveryParams.value,
          insulinDelveryParams.source,
          userId.current['id'],
          insulinDelveryParams.announceMealEnabled,
          insulinDelveryParams.autoModeEnabled,
          insulinDelveryParams.iob,
          insulinDelveryParams.hypoPrevention,
          DateTime.now().toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );

      return status > 0;
    }
  }

  @override
  Future<bool> sendCarbohydrate(Map<String, dynamic> body) async {
    if (await checkConnection.isConnected) {
      return post<bool>(
        '/users/carbohydrates',
        httpClient: httpClient,
        payload: body,
        onSuccess: (response) async => true,
      );
    } else {
      final status = await localDatabase.insert(
        DatabaseUtils.userCarbohydratesTable,
        body,
      );
      return status > 0;
    }
  }

  @override
  Future<GlucoseReportData> glucoseReports({
    DateTime? startDate,
    DateTime? endDate,
    required bool filter,
  }) async {
    if (await checkConnection.isConnected) {
      return get<GlucoseReportData>(
        '/users/blood-glucoses',
        httpClient: httpClient,
        queryParameters: <String, dynamic>{
          // 'fromDate': '2022-06-01',
          'fromDate': startDate != null
              ? DateFormat('yyyy-MM-dd').format(startDate)
              : null,
          // 'toDate': '2022-06-30',
          'toDate':
              endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
          'perPage': 1000,
          if (!filter) 'latestHour': 4
        },
        onSuccess: (response) async {
          final result = response.data as Map<String, dynamic>;
          unawaited(_saveBloodGlucoseToLocalDb(result));

          return GlucoseReportData.fromJson(
            response.data as Map<String, dynamic>,
          );
        },
      );
    } else {
      final result = await localDatabase.queryAllRows(
        table: DatabaseUtils.userBloodGlucoseTable,
      );
      final resultList = result.map(GlucoseReportItem.fromJson).toList();
      final metaResult = await localDatabase.queryAllRows(
        table: DatabaseUtils.glucoseReportMetaTable,
      );
      final meta = GlucoseReportMeta.fromJson(metaResult[0]);

      final metaLevelResultVeryHigh =
          await localDatabase.queryRawWhereWithClauseRows(
        table: DatabaseUtils.glucoseReportMetaLevelTable,
        columnName: 'percentage',
        whereClause: 'status',
        argument: 'very high',
      );

      final veryHigh = GlucoseReportMetaLevel.fromJson(
        metaLevelResultVeryHigh[0],
      );

      final metaLevelResultHigh =
          await localDatabase.queryRawWhereWithClauseRows(
        table: DatabaseUtils.glucoseReportMetaLevelTable,
        columnName: 'percentage',
        whereClause: 'status',
        argument: 'high',
      );

      final high = GlucoseReportMetaLevel.fromJson(
        metaLevelResultHigh[0],
      );

      final metaLevelResultVeryLow =
          await localDatabase.queryRawWhereWithClauseRows(
        table: DatabaseUtils.glucoseReportMetaLevelTable,
        columnName: 'percentage',
        whereClause: 'status',
        argument: 'very low',
      );

      final veryLow = GlucoseReportMetaLevel.fromJson(
        metaLevelResultVeryLow[0],
      );

      final metaLevelResultLow =
          await localDatabase.queryRawWhereWithClauseRows(
        table: DatabaseUtils.glucoseReportMetaLevelTable,
        columnName: 'percentage',
        whereClause: 'status',
        argument: 'low',
      );

      final low = GlucoseReportMetaLevel.fromJson(
        metaLevelResultLow[0],
      );

      final metaLevelResultNormal =
          await localDatabase.queryRawWhereWithClauseRows(
        table: DatabaseUtils.glucoseReportMetaLevelTable,
        columnName: 'percentage',
        whereClause: 'status',
        argument: 'normal',
      );

      final normal = GlucoseReportMetaLevel.fromJson(
        metaLevelResultNormal[0],
      );

      return GlucoseReportData(
        items: resultList,
        meta: GlucoseReportMeta(
          current: meta.current,
          highest: meta.highest,
          lowest: meta.lowest,
          average: meta.average,
        ),
        veryHeightLevel: GlucoseReportMetaLevel(
          percentage: veryHigh.percentage,
        ),
        highLevel: GlucoseReportMetaLevel(
          percentage: high.percentage,
        ),
        normalLevel: GlucoseReportMetaLevel(
          percentage: normal.percentage,
        ),
        veryLowLevel: GlucoseReportMetaLevel(
          percentage: veryLow.percentage,
        ),
        lowLevel: GlucoseReportMetaLevel(
          percentage: low.percentage,
        ),
      );
    }
  }

  Future<void> _saveBloodGlucoseToLocalDb(Map<String, dynamic> result) async {
    final bloodGlucose = GlucoseReportData.fromJson(result);
    for (final item in bloodGlucose.items) {
      await localDatabase.insert(
        DatabaseUtils.userBloodGlucoseTable,
        item.toJson(),
      );
    }

    await localDatabase.delete(DatabaseUtils.glucoseReportMetaTable);

    await localDatabase.insertWithRaw(
      'INSERT INTO '
      '${DatabaseUtils.glucoseReportMetaTable}'
      '(current, highest, lowest, average)'
      ' VALUES(?, ?, ?, ?)',
      [
        bloodGlucose.meta?.current ?? 0.0,
        bloodGlucose.meta?.highest ?? 0.0,
        bloodGlucose.meta?.lowest ?? 0.0,
        bloodGlucose.meta?.average ?? 0.0
      ],
    );

    await localDatabase.delete(DatabaseUtils.glucoseReportMetaLevelTable);

    await localDatabase.insertWithRaw(
      'INSERT INTO '
      '${DatabaseUtils.glucoseReportMetaLevelTable}'
      '(percentage, days, hours, minutes, seconds, status)'
      ' VALUES(?, ?, ?, ?, ?, ?)',
      [
        bloodGlucose.veryHeightLevel?.percentage ?? 0.0,
        bloodGlucose.veryHeightLevel?.dates?.days ?? 0.0,
        bloodGlucose.veryHeightLevel?.dates?.hours ?? 0.0,
        bloodGlucose.veryHeightLevel?.dates?.minutes ?? 0.0,
        bloodGlucose.veryHeightLevel?.dates?.seconds ?? 0.0,
        'very high'
      ],
    );

    await localDatabase.insertWithRaw(
      'INSERT INTO '
      '${DatabaseUtils.glucoseReportMetaLevelTable}'
      '(percentage, days, hours, minutes, seconds, status)'
      ' VALUES(?, ?, ?, ?, ?, ?)',
      [
        bloodGlucose.highLevel?.percentage ?? 0.0,
        bloodGlucose.highLevel?.dates?.days ?? 0.0,
        bloodGlucose.highLevel?.dates?.hours ?? 0.0,
        bloodGlucose.highLevel?.dates?.minutes ?? 0.0,
        bloodGlucose.highLevel?.dates?.seconds ?? 0.0,
        'high'
      ],
    );

    await localDatabase.insertWithRaw(
      'INSERT INTO '
      '${DatabaseUtils.glucoseReportMetaLevelTable}'
      '(percentage, days, hours, minutes, seconds, status)'
      ' VALUES(?, ?, ?, ?, ?, ?)',
      [
        bloodGlucose.normalLevel?.percentage ?? 0.0,
        bloodGlucose.normalLevel?.dates?.days ?? 0.0,
        bloodGlucose.normalLevel?.dates?.hours ?? 0.0,
        bloodGlucose.normalLevel?.dates?.minutes ?? 0.0,
        bloodGlucose.normalLevel?.dates?.seconds ?? 0.0,
        'normal'
      ],
    );

    await localDatabase.insertWithRaw(
      'INSERT INTO '
      '${DatabaseUtils.glucoseReportMetaLevelTable}'
      '(percentage, days, hours, minutes, seconds, status)'
      ' VALUES(?, ?, ?, ?, ?, ?)',
      [
        bloodGlucose.lowLevel?.percentage ?? 0.0,
        bloodGlucose.lowLevel?.dates?.days ?? 0.0,
        bloodGlucose.lowLevel?.dates?.hours ?? 0.0,
        bloodGlucose.lowLevel?.dates?.minutes ?? 0.0,
        bloodGlucose.lowLevel?.dates?.seconds ?? 0.0,
        'low'
      ],
    );

    await localDatabase.insertWithRaw(
      'INSERT INTO '
      '${DatabaseUtils.glucoseReportMetaLevelTable}'
      '(percentage, days, hours, minutes, seconds, status)'
      ' VALUES(?, ?, ?, ?, ?, ?)',
      [
        bloodGlucose.veryLowLevel?.percentage ?? 0.0,
        bloodGlucose.veryLowLevel?.dates?.days ?? 0.0,
        bloodGlucose.veryLowLevel?.dates?.hours ?? 0.0,
        bloodGlucose.veryLowLevel?.dates?.minutes ?? 0.0,
        bloodGlucose.veryLowLevel?.dates?.seconds ?? 0.0,
        'very low'
      ],
    );
  }

  Future<void> _updateBloodGlucoseTable(
    SendBloodGlucoseParams bloodGlucoseParams,
    int userId,
  ) async {
    final result = await localDatabase.queryAllRows(
      table: DatabaseUtils.userBloodGlucoseTable,
    );
    final resultList = result.map(GlucoseReportItem.fromJson).toList();

    await localDatabase.insertWithRaw(
      'INSERT OR REPLACE INTO '
      '${DatabaseUtils.userBloodGlucoseTable}'
      '(id, time, value, source, user_id, level, '
      'createdAt, updatedAt, syncAt, deletedAt)'
      ' VALUES(?, ?, ?, ?, ?, ?, ?, ? ,? ,?)',
      [
        resultList.last.id + 1,
        DateTime.now().toIso8601String(),
        bloodGlucoseParams.value,
        bloodGlucoseParams.source,
        userId,
        _getStatus(bloodGlucoseParams.value),
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
      ],
    );
  }

  String _getStatus(num value) {
    String status;
    if (value > 180) {
      status = 'HIGH';
    } else if (value < 70) {
      status = 'NORMAL';
    } else {
      status = 'LOW';
    }
    return status;
  }

  Future<void> _updateInsulinDeliveyTable(
    SendInsulinDeliveryParams insulinDelveryParams,
    int userId,
  ) async {
    final result = await localDatabase.queryAllRows(
      table: DatabaseUtils.userInsulinDeliveriesTable,
    );
    final resultList = result.map(InsulinReportItem.fromJson).toList();

    await localDatabase.insertWithRaw(
      'INSERT INTO '
      '${DatabaseUtils.userInsulinDeliveriesTable}'
      '(id, time, value, source, user_id, announce_meal_enabled, '
      'auto_mode_enabled, iob, hypoPrevention, '
      'createdAt, updatedAt, syncAt, deletedAt)'
      ' VALUES(?, ?, ?, ?, ?, ?, ?, ? ,? ,? , ?, ?, ?)',
      [
        resultList.last.id + 1,
        insulinDelveryParams.time,
        insulinDelveryParams.value,
        insulinDelveryParams.source,
        userId,
        null,
        null,
        0,
        null,
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
      ],
    );
  }

  @override
  Future<InsulinReportData> insulinReports({
    DateTime? startDate,
    DateTime? endDate,
    required bool filter,
  }) async {
    if (await checkConnection.isConnected) {
      return get<InsulinReportData>(
        '/users/insulin-deliveries',
        httpClient: httpClient,
        queryParameters: <String, dynamic>{
          'fromDate': startDate != null
              ? DateFormat('yyyy-MM-dd').format(startDate)
              // ? '2022-06-01'
              : null,
          'toDate': endDate != null
              ? DateFormat('yyyy-MM-dd').format(endDate)
              // ? '2022-07-30'
              : null,
          'perPage': 1000,
          if (!filter) 'latestHour': 4,
        },
        onSuccess: (response) async {
          final result = response.data as Map<String, dynamic>;
          unawaited(
            _saveInsulinDeliveryDataToLocalDb(
              result,
            ),
          );

          return InsulinReportData.fromJson(
            response.data as Map<String, dynamic>,
          );
        },
      );
    } else {
      final result = await localDatabase.queryAllRows(
        table: DatabaseUtils.userInsulinDeliveriesTable,
      );
      final resultList = result.map(InsulinReportItem.fromJson).toList();
      return InsulinReportData(items: resultList);
    }
  }

  Future<void> _saveInsulinDeliveryDataToLocalDb(
    Map<String, dynamic> result,
  ) async {
    final insulinDelivery = InsulinReportData.fromJson(result);
    for (final item in insulinDelivery.items) {
      await localDatabase.insert(
        DatabaseUtils.userInsulinDeliveriesTable,
        item.toJson(),
      );
    }
  }

  @override
  Future<CarbohydrateReportData> carbohydrateReports({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (await checkConnection.isConnected) {
      return get<CarbohydrateReportData>(
        '/users/carbohydrates',
        httpClient: httpClient,
        queryParameters: <String, dynamic>{
          'fromDate': startDate != null
              ? DateFormat('yyyy-MM-dd').format(startDate)
              // ? '2022-06-01'
              : null,
          'toDate': endDate != null
              ? DateFormat('yyyy-MM-dd').format(endDate)
              // ? '2022-07-30'
              : null,
          'perPage': 1000,
        },
        onSuccess: (response) async {
          final result = response.data as Map<String, dynamic>;
          unawaited(
            _saveCarbohydrateReportsToLocalDb(
              result,
            ),
          );

          return CarbohydrateReportData.fromJson(
            response.data as Map<String, dynamic>,
          );
        },
      );
    } else {
      final result = await localDatabase.queryAllRows(
        table: DatabaseUtils.insertCarbohydrateTable,
      );
      final resultList = result.map(CarbohydrateReportItem.fromJson).toList();
      return CarbohydrateReportData(items: resultList);
    }
  }

  Future<void> _saveCarbohydrateReportsToLocalDb(
    Map<String, dynamic> result,
  ) async {
    final carbohydrate = CarbohydrateReportData.fromJson(
      result,
    );

    final userId = await localDatabase.query(
      table: DatabaseUtils.mySelfTable,
      columnName: 'id',
    );
    await userId.moveNext();
    for (final item in carbohydrate.items) {
      await localDatabase.insertWithRaw(
        'INSERT OR REPLACE INTO '
        '${DatabaseUtils.userCarbohydratesTable}'
        '(id, value, source, user_id, food_type_id, time, '
        'syncAt, createdAt, deletedAt, updatedAt)'
        ' VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          item.id,
          item.value,
          userId.current['id'],
          item.foodType?.id,
          item.time?.toIso8601String(),
          item.syncAt?.toIso8601String(),
          item.createdAt?.toIso8601String(),
          item.deletedAt?.toIso8601String(),
          item.updatedAt?.toIso8601String(),
        ],
      );
    }
  }

  @override
  Future<CarbohydrateFoodData> carbohydrateFoodData({
    int? page,
    int? perPage,
    String? search,
    String? source,
  }) async {
    if (await checkConnection.isConnected) {
      return get<CarbohydrateFoodData>(
        '/users/food-types',
        httpClient: httpClient,
        queryParameters: <String, dynamic>{
          'page': page,
          'perPage': perPage,
          'search': search,
          'source': source,
        },
        onSuccess: (response) async {
          return CarbohydrateFoodData.fromJson(
            response.data as Map<String, dynamic>,
          );
        },
      );
    } else {
      final result = await localDatabase.queryAllRows(
        table: DatabaseUtils.foodTypesTable,
      );
      final resultList = result.map(FoodType.fromJson).toList();
      return CarbohydrateFoodData(items: resultList);
    }
  }
}
