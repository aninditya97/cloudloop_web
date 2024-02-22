import 'package:cloudloop_mobile/core/preferences/assets.dart';
import 'package:cloudloop_mobile/features/home/presentation/components/component.dart';
import 'package:cloudloop_mobile/features/home/presentation/components/sensor_component.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get_it/get_it.dart';
// import 'package:go_router/go_router.dart';

class FindDevicesScreen extends StatelessWidget {
  const FindDevicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<SavePumpBloc>(),
      child: const FindDevicesScreenView(),
    );
  }
}

class FindDevicesScreenView extends StatefulWidget {
  const FindDevicesScreenView({Key? key}) : super(key: key);

  @override
  State<FindDevicesScreenView> createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreenView> {
  @override
  void initState() {
    FlutterBluePlus.instance.startScan(
      timeout: const Duration(seconds: 4),
    );
    super.initState();
  }

  void _onConnect(PumpData pump) {
    context.read<SavePumpBloc>().add(
          SavePump(pump: pump),
        );
  }

  @override
  Widget build(BuildContext context) {
    var findId = const DeviceIdentifier('');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Sensor'),
        actions: [
          IconButton(
            onPressed: () {
              FlutterBluePlus.instance.startScan(
                timeout: const Duration(seconds: 4),
              );
            },
            icon: const Icon(Icons.autorenew_rounded),
          )
        ],
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder<List<ScanResult>>(
          stream: FlutterBluePlus.instance.scanResults,
          initialData: const [],
          builder: (c, snapshot) {
            if (snapshot.data?.isNotEmpty == true) {
              return StreamBuilder<bool>(
                stream: FlutterBluePlus.instance.isScanning,
                initialData: false,
                builder: (c, scanning) {
                  if (scanning.data!) {
                    return Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: Image.asset(MainAssets.searchDevice),
                    );
                  } else {
                    return SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          StreamBuilder<List<BluetoothDevice>>(
                            stream: Stream.periodic(
                              const Duration(seconds: 2),
                              (_) {},
                            ).asyncMap(
                              (_) => FlutterBluePlus.instance.connectedDevices,
                            ),
                            initialData: const [],
                            builder: (c, device) {
                              if (device.data?.isNotEmpty == true) {
                                findId = device.data![0].id;
                                snapshot.data!.removeWhere((element) {
                                  return element.device.id == findId;
                                });

                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => setState(() {}),
                                );
                              }
                              return Column(
                                children: device.data!
                                    .map(
                                      (d) => ListTile(
                                        title: Text(d.name),
                                        subtitle: Text(
                                          d.id.toString(),
                                        ),
                                        trailing:
                                            StreamBuilder<BluetoothDeviceState>(
                                          stream: d.state,
                                          initialData:
                                              BluetoothDeviceState.disconnected,
                                          builder: (c, snapshot) {
                                            if (snapshot.data ==
                                                BluetoothDeviceState
                                                    .connected) {
                                              _onConnect(
                                                PumpData(
                                                  id: findId.id,
                                                  name: device.data![0].name,
                                                  status: true,
                                                  connectAt: DateTime.now(),
                                                ),
                                              );
                                              return ElevatedButton(
                                                child: const Text('OPEN'),
                                                onPressed: () {
                                                  // GoRouter.of(context).push(
                                                  //   '/scan/detail',
                                                  //   extra: d,
                                                  // );
                                                },
                                              );
                                            }
                                            return Text(
                                              snapshot.data.toString(),
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(
                            height: 16,
                          ),
                          // Column(
                          //   children: snapshot.data!
                          //       .map(
                          //         (r) => ScanResultComponent(
                          //           result: r,
                          //           onTap: () => GoRouter.of(context).push(
                          //             '/scan/detail',
                          //             extra: r.device,
                          //           ),
                          //         ),
                          //       )
                          //       .toList(),
                          // ),
                        ],
                      ),
                    );
                  }
                },
              );
            } else {
              return StreamBuilder<bool>(
                stream: FlutterBluePlus.instance.isScanning,
                initialData: false,
                builder: (c, snapshot) {
                  if (snapshot.data!) {
                    return Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: Image.asset(MainAssets.searchDevice),
                    );
                  } else {
                    return Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: const Text('No devices detected'),
                    );
                  }
                },
              );
            }
          },
        ),
      ),
    );
  }
}
