// IPump interface

import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/IDevice.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ResponseCallback.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// @brief this interface define Pump functions.
// @author kai_20230429

abstract class IPump extends IDevice {
  double getBolusDeliveryValue();
  double getLastBolusDeliveryValue();
  ReportSource getInsulinSource();

  ///< get the bolus value delivered to the Pump
  void setBolusDeliveryValue(double _value);
  void setLastBolusDeliveryValue(double _value);
  void setInsulinSource(ReportSource _value);
  int getLastBolusDeliveryTime();

  ///< get the latest time & date for bolus delivery
  void setLastBolusDeliveryTime(int _value);
  /*
  setup pump initialization :the input argument "characteristic" could be ignored as 'null"
  if the pump bluetooth connection is established
  */
  //set the reservoir injection amount and current timedate into the Pump.
  Future<void> SendSetTimeReservoirRequest(
    int ReservoirAmount,
    int HclMode,
    BluetoothCharacteristic? characteristic,
  );
  //request pump information
  Future<void> sendPumpPatchInfoRequest(
    BluetoothCharacteristic? characteristic,
  );
  //set maximum bolus injection amount value which will be float or int type
  //as like ( 2.5 or 25 ), just put it as String '2.5' or '200.0'
  Future<void> sendSetMaxBolusThreshold(
    String value,
    int type,
    BluetoothCharacteristic? characteristic,
  );
  //send check Safety request to the pump
  Future<void> sendSafetyCheckRequest(BluetoothCharacteristic? characteristic);
  //send cannular insertion request to the pump
  Future<void> sendCannularStatusRequest(
    BluetoothCharacteristic characteristic,
  );
  //send ACK for the response sent from the pump when cannular insertion is
  //complete
  Future<void> sendCannularInsertAck(BluetoothCharacteristic? characteristic);
  //must implement this function to inject the calculated dose (bolus/basal) value to pump device
  // the value which will be float or int type as like ( 0.5  ~ 25 ), just put
  //it as String '0.5' ~ '25.0'
  Future<void> sendSetDoseValue(
    String value,
    int mode,
    BluetoothCharacteristic? characteristic,
  );
  //must implement this function to cancel that on going injection of the calculated dose (bolus/basal) in pump device
  Future<void> cancelSetDoseValue(
    int mode,
    BluetoothCharacteristic? characteristic,
  );
  //discard pump device
  Future<void> sendDiscardPatch(BluetoothCharacteristic? characteristic);
  //send buzzer check request to the pump
  Future<void> sendBuzzerCheck(BluetoothCharacteristic? characteristic);
  //send Buzzer change request to the pump
  Future<void> sendBuzzerChangeRequest(
    bool BuzzerOnOff,
    BluetoothCharacteristic? characteristic,
  );
  //send Application status change indication to the pump when app is transit
  //forground to background vice versa.
  Future<void> sendAppStatusChangeIndication(
    int status,
    int StopTimerValue,
    BluetoothCharacteristic? characteristic,
  );
  //send request for Mac address of the pump to the pump
  Future<void> sendMacAddrRequest(BluetoothCharacteristic? characteristic);
  //send infusion information request to the pump
  Future<void> sendInfusionInfoRequest(
    int type,
    BluetoothCharacteristic? characteristic,
  );
  //send commands and data to the pump
  Future<void> sendDataToPumpDevice(String data);

  //can register RX characteristic value listener to handle the message sent
  //from connected device.
  // if use this then void handlePumpValue(List<int> value) is replaced by new
  // one.
  void registerPumpValueListener(Function(List<int>) listener);
  Future<void> unregisterPumpValueListener();

  //can register RX Battery characteristic value listener to handle the message
  //sent from connected device.
  // if use this then void Function(List<int> value) should be implemented for
  // battery.
  void registerPumpBatLvlValueListener(Function(List<int>) listener);
  void unregisterPumpBatLvlValueListener();

  //can register connected device connection status listener to handle the
  //several connection events sent from connected device.
  // if use this then void Function(BluetoothDeviceState) should be implemented
  //for battery.
  void registerPumpStateCallback(void Function(BluetoothDeviceState) callback);
  void unregisterPumpStateCallback();

  //can enable/disable Battery RX Characteristic Notify which maybe be provided by connected device' service
  // if not supported in the connected device, then do not use this.
  Future<void> pumpBatteryNotify();

  // implement this function to monitor the connection status event for update UI on the screen.
  void pumpConnectionStatus(BluetoothDeviceState state);

  //must implement this function to handle the received data sent from the pump device
  //and also can directly register this function by using registerPumpValueListener() in other widget as like StatefulWidget
  void handlePumpValue(List<int> value);

  // In order to show an message or additional interaction to user
  // can register/unregister the Response Callback Listener which notify a response sent from Pump to user by using
  // the registered callback function of the type 'ResponseCallback'
  void setResponseCallbackListener(ResponseCallback callback);
  void releaseResponseCallbackListener();
  ResponseCallback? getResponseCallbackListener();
}
