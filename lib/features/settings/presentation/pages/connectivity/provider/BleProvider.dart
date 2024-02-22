import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleProvider extends ChangeNotifier {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? connectedDevice;
  List<ScanResult> scanResults = [];

  Future<void> startScan() async {
    flutterBlue.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });
    await flutterBlue.startScan();
  }

  Future<void> stopScan() async {
    await flutterBlue.stopScan();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;
    notifyListeners();
  }

  Future<void> disconnectFromDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      notifyListeners();
    }
  }
}
