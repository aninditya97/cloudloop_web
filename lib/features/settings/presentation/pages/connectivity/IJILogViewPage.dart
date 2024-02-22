import 'dart:async';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/IJILog.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/IJILogChart.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class IJILogViewPageApp extends StatelessWidget {
  const IJILogViewPageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IJILog View',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const IJILogViewPage(),
    );
  }
}

class IJILogViewPage extends StatefulWidget {
  const IJILogViewPage({Key? key}) : super(key: key);

  @override
  _IJILogViewPageState createState() => _IJILogViewPageState();
}

class _IJILogViewPageState extends State<IJILogViewPage> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  // late SharedPreferences prefs;
  late Database db;
  List<IJILog> logs = [];
  List<BluetoothDevice> devices = [];
  String cgmSourceType = '';
  late IJILogChart? _mIJIogChart = null;

  @override
  void initState() {
    super.initState();
    initPrefs();
    initDatabase();
    // initBluetooth();
    if(_mIJIogChart == null)
    {
      _mIJIogChart = IJILogChart(logs: logs);
    }
  }

  void _updateCGMSourceType(String type) {
    setState(() {
      cgmSourceType = type;
    });
    CspPreference.setString('cgmSourceTypeKey', type);
  }

  Future<void> initPrefs() async {
    // prefs = await SharedPreferences.getInstance();
    // await CspPreference.initPrefs();
    //get CGMSourceType here
    CspPreference.initPrefs().then((value) {
      setState(() {
        cgmSourceType = CspPreference.getString('cgmSourceTypeKey');
      });
    });
  }

  Future<void> deleteIJILogAll() async{
    //await deleteDatabase('ijilog.db');
    for (final logItem in logs)
    {
      deleteLog(logItem);
    }
    logs.clear();
  }


  Future<void> initDatabase() async {
    db = await openDatabase(
      'ijilog.db',
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE IJILog(time INTEGER, type INTEGER, data TEXT, report INTEGER)',
        );
      },
    );
    final List<Map> maps = await db.query('IJILog', orderBy: 'time DESC');
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
           // data: json.decode(maps[i]['data']),
            data: maps[i]['data'],
            report: maps[i]['report']
         */
      ),
    );

    setState(() {});
  }

  Future<void> initBluetooth() async {
    await flutterBlue.startScan();
    flutterBlue.scanResults.listen((results) {
      for (final result in results) {
        if (!devices.contains(result.device)) {
          devices.add(result.device);
          setState(() {});
        }
      }
    });
  }

  Future<void> insertLog(IJILog log) async {
    await db.insert('IJILog', {
      'time': log.time,
      'type': log.type,
      // 'data': json.encode(log.data),
      'data': log.data,
      'report': log.report
    });
    logs.insert(0, log);
    setState(() {});
  }

  Future<void> deleteLog(IJILog log) async {
    await db.delete('IJILog', where: 'time = ?', whereArgs: [log.time]);
    logs.remove(log);
    setState(() {});
  }

  Future<void> updateLog(IJILog log) async {
    await db.update(
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IJILog View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final text = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  final controller = TextEditingController();
                  return AlertDialog(
                    title: const Text('Enter text'),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      TextButton(
                        child: const Text('Send'),
                        onPressed: () async {
                          final data = controller.text;
                          // Send data to connected pump device using
                          //write characteristic method
                          Navigator.pop(context);
                        },
                      )
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.blueAccent[700],
                  content: Text('start deleting logs ...'),
                  duration: Duration(seconds: 1),
                ),
              );
              await deleteIJILogAll();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.blueAccent[700],
                  content: Text('complete deleting logs'),
                  duration: Duration(seconds: 2),
                ),
              );
              if(_mIJIogChart != null)
              {
                _mIJIogChart!.updateChart(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  title: Text(
                    'Time:${DateFormat("yyyy/MM/dd-HH:mm:ss").format(
                      DateTime.fromMillisecondsSinceEpoch(
                        log.time,
                        isUtc: true,
                      ),
                    )}, Type: ${(log.type == 1) ? 'bolus' : ((log.type == 2) ? 'basal' : ((log.type == 3) ? 'occlusion' : ((log.type == 4) ? 'low battery' : ((log.type == 5) ? 'low reservior' : 'none'))))}',
                  ),
                  // title: Text('Type: ${log.type}'),
                  subtitle: Text('Data: ${log.data}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      deleteLog(log);
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: IJILogChart(logs: logs),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.id.toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
