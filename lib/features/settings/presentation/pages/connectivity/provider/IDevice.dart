import 'dart:async';
import 'package:cloudloop_mobile/features/settings/domain/entities/xdrip_data.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// @brief this interface define device functions.
// @author kai_20230429

// IDevice interface
abstract class IDevice {
  Future<List<BluetoothDevice>?> startScan(int timeout);

  ///< start scanning peripheral pump devices with timeout seconds
  void stopScan();

  ///< stop scanning
  List<BluetoothDevice>? getScannedDeviceLists();

  ///< get the scanned device lists for the specified device name
  Future<void> connectToDevice(BluetoothDevice device);

  ///< try to connect the selected scanned device
  Future<void> disconnectFromDevice();

  ///< try to disconnect the connected device
  Future<List<BluetoothService>?> discoverServices();

  ///< get the service lists of the connected device
  BluetoothDevice? getConnectedDevice();

  ///< get the connected device
  String getModelName();

  ///< get the connected device's model name
  String getManufacturerName();

  ///< get device manufacturer Name
  String getFirmwareVersion();

  ///< get the firmware version of the connected device
  String getSerialNumber();

  ///< get serial number of the connected device
  String getVerificationCode();

  ///< get the validation code of the connected device
  String getBatteryLevel();

  ///< get battery status as like level from the connected device
  int getConnectedTime();

  ///< get the connected time & date when the device is connected
  Future<List<BluetoothCharacteristic>?> discoverCharacteristics(
    BluetoothService service,
  );

  ///< find specified service's BluetoothCharacteristic lists
  Future<BluetoothCharacteristic?> getCharacteristic(String uuid);

  ///< find specified UUID's BluetoothCharacteristic
  void clearDeviceInfo();

  ///< clear Device information shown in UI. In case that user change Device
  ///Type, this should be called.
}
