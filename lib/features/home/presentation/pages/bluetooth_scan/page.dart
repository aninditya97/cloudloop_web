import 'dart:math';

import 'package:cloudloop_mobile/features/home/presentation/components/sensor_component.dart';
import 'package:cloudloop_mobile/features/home/presentation/pages/bluetooth_scan/sections/bluetooth_off_scree_section.dart';
import 'package:cloudloop_mobile/features/home/presentation/pages/bluetooth_scan/sections/find_device_screen_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothScanPage extends StatelessWidget {
  const BluetoothScanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothState>(
      stream: FlutterBluePlus.instance.state,
      initialData: BluetoothState.unknown,
      builder: (c, snapshot) {
        final state = snapshot.data;
        if (state == BluetoothState.on) {
          return const FindDevicesScreen();
        }
        return const BluetoothOffScreen();
      },
    );
  }
}

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key, this.device}) : super(key: key);

  final BluetoothDevice? device;

  List<int> _getRandomBytes() {
    final math = Random();
    return [
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255)
    ];
  }

  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    return services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map(
                  (c) => CharacteristicTile(
                    characteristic: c,
                    onReadPressed: () => c.read(),
                    onWritePressed: () async {
                      await c.write(_getRandomBytes(), withoutResponse: true);
                      await c.read();
                    },
                    onNotificationPressed: () async {
                      await c.setNotifyValue(!c.isNotifying);
                      await c.read();
                    },
                    descriptorTiles: c.descriptors
                        .map(
                          (d) => DescriptorTile(
                            descriptor: d,
                            onReadPressed: () => d.read(),
                            onWritePressed: () => d.write(_getRandomBytes()),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device!.name),
        actions: [
          StreamBuilder<BluetoothDeviceState>(
            stream: device!.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              if (snapshot.data == BluetoothDeviceState.connected) {
                onPressed = device!.disconnect;
                text = 'DISCONNECT';
              } else if (snapshot.data == BluetoothDeviceState.disconnected) {
                onPressed = device!.connect;
                text = 'CONNECT';
              } else {
                onPressed = null;
                text = snapshot.data.toString().substring(21).toUpperCase();
              }
              return Row(
                children: [
                  TextButton(
                    onPressed: onPressed,
                    child: Text(
                      text,
                      style: Theme.of(context)
                          .primaryTextTheme
                          .button
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: device!.pair,
                    child: Text(
                      'PAIR',
                      style: Theme.of(context)
                          .primaryTextTheme
                          .button
                          ?.copyWith(color: Colors.white),
                    ),
                  )
                ],
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder(
              stream: device!.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (snapshot.data == BluetoothDeviceState.connected)
                      const Icon(Icons.bluetooth_connected)
                    else
                      const Icon(Icons.bluetooth_disabled),
                    if (snapshot.data == BluetoothDeviceState.connected)
                      StreamBuilder(
                        stream: rssiStream(),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.hasData ? '${snapshot.data}dBm' : '',
                            style: Theme.of(context).textTheme.caption,
                          );
                        },
                      )
                    else
                      Text('', style: Theme.of(context).textTheme.caption),
                  ],
                ),
                title: Text(
                  'Device is ${snapshot.data.toString().split('.')[1]}.',
                ),
                subtitle: Text('${device!.id}'),
                trailing: StreamBuilder(
                  stream: device!.isDiscoveringServices,
                  initialData: false,
                  builder: (c, snapshot) => IndexedStack(
                    index: snapshot.data! ? 1 : 0,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: device!.discoverServices,
                      ),
                      const IconButton(
                        icon: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                        ),
                        onPressed: null,
                      )
                    ],
                  ),
                ),
              ),
            ),
            StreamBuilder(
              stream: device!.mtu,
              initialData: 0,
              builder: (c, snapshot) => ListTile(
                title: const Text('MTU Size'),
                subtitle: Text('${snapshot.data} bytes'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => device!.requestMtu(223),
                ),
              ),
            ),
            StreamBuilder<List<BluetoothService>>(
              stream: device!.services,
              initialData: const [],
              builder: (c, snapshot) {
                return Column(
                  children: _buildServiceTiles(snapshot.data!),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Stream<int> rssiStream() async* {
    var isConnected = true;
    final subscription = device!.state.listen((state) {
      isConnected = state == BluetoothDeviceState.connected;
    });
    while (isConnected) {
      yield await device!.readRssi();
      await Future.delayed(const Duration(seconds: 1), () {});
    }
    await subscription.cancel();
    // Device disconnected, stopping RSSI stream
  }
}
