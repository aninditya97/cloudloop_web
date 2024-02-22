import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/IJILog.dart';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';

const bool DEBUG_MESSAGE_FLAG = true;

class IJILogDB {
  final String TAG = 'IJILogDB:';
  static late Database? db = null;
  static List<IJILog> logs = [];

  /*
   * @brief initialize IJILog  database table
   */
  Future<void> initDatabase() async {
    db = await openDatabase(
      'ijilog.db',
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
            'CREATE TABLE IJILog(time INTEGER, type INTEGER, data TEXT, '
            'report INTEGER)');
      },
    );
    final List<Map> maps = await db!.query('IJILog', orderBy: 'time DESC');
    logs = List.generate(
      maps.length,
      (i) => IJILog(
        /*
            time: maps[i]['time'],
            type: maps[i]['type'],
            data: maps[i]['data'],
           //     data: json.decode(maps[i]['data']),
            report: maps[i]['report']
        */
        time: maps[i]['time'] as int,
        type: maps[i]['type'] as int,
        data: maps[i]['data'] as String,
        report: maps[i]['report'] as int,
      ),
    );
  }

  /*
   * @brief insert IJILog data to DB Table
   */
  Future<void> insertLog(IJILog log) async {
    await db!.insert('IJILog', {
      'time': log.time,
      'type': log.type,
      // 'data': json.encode(log.data),
      'data': log.data,
      'report': log.report
    });
    logs.insert(0, log);
  }

  /*
   * @brief delete IJILog data from DB Table
   */
  Future<void> deleteLog(IJILog log) async {
    await db!.delete('IJILog', where: 'time = ?', whereArgs: [log.time]);
    logs.remove(log);
  }

  /*
   * @brief update IJILog data DB Table 
   */
  Future<void> updateLog(IJILog log) async {
    await db!.update(
      'IJILog',
      {
        'type': log.type,
        // 'data': json.encode(log.data),
        'data': log.data,
        'report': log.report
      },
      where: 'time = ?',
      whereArgs: [log.time],
    );
  }

  /*
   * @breif get IJILog database instance
   */
  Future<Database?> getIJIDataBase() async {
    if (db == null || !db!.isOpen) {
      db = await openDatabase(
        'ijilog.db',
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
              'CREATE TABLE IJILog(time INTEGER, type INTEGER, data TEXT, '
              'report INTEGER)');
        },
      );

      final List<Map> maps = await db!.query('IJILog', orderBy: 'time DESC');
      logs = List.generate(
        maps.length,
        (i) => IJILog(
          time: maps[i]['time'] as int,
          type: maps[i]['type'] as int,
          data: maps[i]['data'] as String,
          report: maps[i]['report'] as int,
          /*
              time: maps[i]['time'],
              type: maps[i]['type'],
              data: maps[i]['data'],
              //    data: json.decode(maps[i]['data']),
              report: maps[i]['report']
           */
        ),
      );

      if (DEBUG_MESSAGE_FLAG) {
        debugPrint('${TAG}kai:_getIJIDataBase(): db.isOpen = ${db!.isOpen}');
      }
    }
    return db;
  }

  List<IJILog> getLogs() {
    return logs;
  }

  Future<void> closeIJILogDataBase() async {
    await db!.close();
  }
}
