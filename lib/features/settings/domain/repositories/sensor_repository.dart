import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/core/database/database.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:dio/dio.dart';

abstract class SensorRepository {
  Future<PumpData?> getPump();

  Future<CgmData?> getCgm();

  Future<bool> getPumpConnected();

  Future<bool> insertPump(PumpData data);

  Future<bool> getCgmConnected();

  Future<bool> disconnectCgm();

  Future<bool> setAutoMode();

  Future<int> getAutoModeStatus();

  Future<bool> setAnnounceMeal(int type);

  Future<int> getAnnounceMealStatus();

  Future<CgmData?> insertCgm(CgmData data);

  Future<bool> disconnectPump();
}

class SensorRepositoryImpl
    with ServiceNetworkHandlerMixin
    implements SensorRepository {
  const SensorRepositoryImpl({
    required this.httpClient,
    required this.localDatabase,
    required this.checkConnection,
  });

  final Dio httpClient;
  final DatabaseHelper localDatabase;
  final NetworkInfo checkConnection;

  @override
  Future<bool> getPumpConnected() async {
    final data = await localDatabase.queryAllRows(
      table: DatabaseUtils.pumpTable,
    );
    var result = false;

    if (data.isNotEmpty) {
      for (final item in data) {
        if (item['status'].toString() == '1') {
          result = true;
        }
      }
    }
    return result;
  }

  @override
  Future<bool> insertPump(PumpData data) async {
    final status = await localDatabase.insert(
      DatabaseUtils.pumpTable,
      data.toJson(),
    );
    return status > 0;
  }

  @override
  Future<bool> getCgmConnected() async {
    final data = await localDatabase.queryAllRows(
      table: DatabaseUtils.cgmTable,
    );
    var result = false;

    if (data.isNotEmpty) {
      for (final item in data) {
        if (item['status'].toString() == '1') {
          result = true;
        }
      }
    }
    return result;
  }

  @override
  Future<CgmData?> insertCgm(CgmData data) async {
    await localDatabase.delete(
      DatabaseUtils.cgmTable,
    );

    CgmData? finalResult;

    final status = await localDatabase.insert(
      DatabaseUtils.cgmTable,
      data.toJson(),
    );
    if (status > 0) {
      final data = await localDatabase.query(
        table: DatabaseUtils.cgmTable,
      );
      await data.moveNext();

      final result = CgmData(
        id: data.current['id'].toString(),
        deviceId: data.current['device_id'].toString(),
        transmitterId: data.current['transmitter_id'].toString(),
        transmitterCode: data.current['transmitter_code'].toString(),
        status: data.current['status'] is bool,
      );
      finalResult = result;
    }
    return finalResult;
  }

  @override
  Future<bool> disconnectCgm() async {
    final data = await localDatabase.delete(
      DatabaseUtils.cgmTable,
    );

    return data > 0;
  }

  @override
  Future<CgmData?> getCgm() async {
    final data = await localDatabase.queryAllRows(
      table: DatabaseUtils.cgmTable,
    );
    CgmData? result;

    if (data.isNotEmpty) {
      for (final item in data) {
        result = CgmData(
          id: item['id'].toString(),
          deviceId: item['device_id'].toString(),
          transmitterId: item['transmitter_id'].toString(),
          transmitterCode: item['transmitter_code'].toString(),
          status: item['status'] == 1,
          connectAt: (item['connect_at'] != null)
              ? DateTime.parse(item['connect_at'].toString())
              : DateTime
                  .now() /* default datetime in case of input value is null*/,
        );
      }
    }
    return result;
  }

  @override
  Future<PumpData?> getPump() async {
    final data = await localDatabase.queryAllRows(
      table: DatabaseUtils.pumpTable,
    );
    PumpData? result;

    if (data.isNotEmpty) {
      for (final item in data) {
        result = PumpData(
          id: item['id'].toString(),
          name: item['name'].toString(),
          status: int.parse(item['status'].toString()) == 1,
          connectAt: (item['connect_at'] != null)
              ? DateTime.parse(item['connect_at'].toString())
              : DateTime
                  .now() /* default datetime in case of input value is null*/,
        );
      }
    }
    return result;
  }

  @override
  Future<bool> setAutoMode() async {
    final data = await localDatabase.queryAllRows(
      table: DatabaseUtils.autoModeTable,
    );
    var status = 0;

    if (data.isNotEmpty) {
      await localDatabase.delete(
        DatabaseUtils.autoModeTable,
      );
    } else {
      final body = {
        'status': true,
        'actived_at': DateTime.now().toIso8601String(),
      };
      status = await localDatabase.insert(
        DatabaseUtils.autoModeTable,
        body,
      );
    }

    return status > 0;
  }

  @override
  Future<int> getAutoModeStatus() async {
    final data = await localDatabase.queryAllRows(
      table: DatabaseUtils.autoModeTable,
    );
    var result = 0;

    if (data.isNotEmpty) {
      for (final item in data) {
        result = int.parse(
          item['status'].toString(),
        );
      }
    }
    return result;
  }

  @override
  Future<bool> setAnnounceMeal(int type) async {
    final data = await localDatabase.queryAllRows(
      table: DatabaseUtils.announceMealTable,
    );
    var status = 0;

    if (type == 0) {
      await localDatabase.delete(
        DatabaseUtils.announceMealTable,
      );
    } else if (data.isNotEmpty && type != 0) {
      await localDatabase.delete(
        DatabaseUtils.announceMealTable,
      );

      final body = {
        //kai_20231102 'status': true,
        'status': 1,
        'type': type,
        'actived_at': DateTime.now().toIso8601String(),
      };
      status = await localDatabase.insert(
        DatabaseUtils.announceMealTable,
        body,
      );
    } else {
      final body = {
        //kai_20231102 'status': true,
        'status': 1,
        'type': type,
        'actived_at': DateTime.now().toIso8601String(),
      };
      status = await localDatabase.insert(
        DatabaseUtils.announceMealTable,
        body,
      );
    }

    return status > 0;
  }

  @override
  Future<int> getAnnounceMealStatus() async {
    final data = await localDatabase.queryAllRows(
      table: DatabaseUtils.announceMealTable,
    );
    var result = 0;

    if (data.isNotEmpty) {
      for (final item in data) {
        result = int.parse(
          item['type'].toString(),
        );
      }
    }
    return result;
  }

  @override
  Future<bool> disconnectPump() async {
    final data = await localDatabase.delete(
      DatabaseUtils.pumpTable,
    );

    return data > 0;
  }
}
