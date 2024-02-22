/*
 * @brief ConnectivityMgr class manages Cgm/Pump Device connection.
 */
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/Cgm.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/CgmDexcom.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/CgmIsense.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/CgmIsenseBC.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/CgmXdrip.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/IBloodGlucoseStream.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/IDevice.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/IPolicyNet.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/Pump.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/PumpCsp1.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/PumpDanars.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ResponseCallback.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/featureFlag.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/serviceUuid.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum CGMType { DEXCOM, ISENSE, XDRIP, MAX_CGM, NOT_INITIALIZED }

enum PUMPType { CARELEVO, CSP1, DANARS, MAX_PUMP }

class ConnectivityMgr with ChangeNotifier {
  ConnectivityMgr() {
    changeCGM();
    changePUMP();
    //init policynet
    initPolicyNet();
  }
  //kai_20230720  add to use the context in all widgets
  static BuildContext? _appContext;
  static void setAppContext(BuildContext context) {
    _appContext = context;
  }

  BuildContext? get appContext => _appContext;

  //kai_20230802 add to keep default BGdata Stream Listener for cgm which use broadcasting method as like xdrip
  static BGStreamCallback? mDefaultBGDataStreamCallback;
  static ResponseCallback? mDefaultCgmResponselistener;
  static ResponseCallback? mDefaultPumpResponselistener;

  Cgm? mCgm;
  late Pump? mPump = null;
  late IPolicyNet? mPN = null;
  int _scanTimeout = 5;

  int get scanTimeout => _scanTimeout;
  set scanTimeout(int value) {
    _scanTimeout = value;
  }

  Future<void> initPolicyNet() async {
    debugPrint('ConnectivityMgr:InitPolicyNet()');
    mPN ??= IPolicyNet();
    if (mPN != null) {
      await mPN!.init();
    }
  }

  Future<void> changeCGM() async {
    final mCGMNAME = CspPreference.getString('cgmSourceTypeKey');
    debugPrint('changeCGM():mCGM_NAME = $mCGMNAME');
    switch (mCGMNAME) {
      case serviceUUID.Dexcom_PUMP_NAME:
        await createCGM(CGMType.DEXCOM);
        break;

      case serviceUUID.Xdrip_CGM_NAME:
        await createCGM(CGMType.XDRIP);
        break;

      case serviceUUID.ISENSE_CGM_NAME:
        await createCGM(CGMType.ISENSE);
        break;

      default:
        await createCGM(CGMType.NOT_INITIALIZED);
        break;
    }
  }

  Future<void> changePUMP() async {
    final mPUMPNAME = CspPreference.getString('pumpSourceTypeKey');
    debugPrint('changePUMP():mPUMP_NAME = $mPUMPNAME');
    switch (mPUMPNAME) {
      case serviceUUID.DANARS_PUMP_NAME:
        await createPUMP(PUMPType.DANARS);
        break;

      case serviceUUID.CareLevo_PUMP_NAME:
        await createPUMP(PUMPType.CARELEVO);
        break;

      case serviceUUID.CSP_PUMP_NAME:
        await createPUMP(PUMPType.CSP1);
        break;

      default:
        await createPUMP(PUMPType.CARELEVO);
        break;
    }
  }

  Future<void> createCGM(CGMType type) async {
    // create a CGM object
    // kai_20230509 let's consider previous instance is the same as new one
    // then skip new one because previous one already served.
    // In this case, previous registered listener or callback should be canceled.
    // but sometimes, unregistered listener as like eventChannel's callback sink
    // might be called. this cause RuntimeException
    if (mCgm != null) {
      /*
      if(mCgm is CgmXdrip && type == CGMType.XDRIP)
      {
        print('kai:createCGM():mCgm is CgmXdrip && type == CGMType.XDRIP:skip');
        return;
      }
      else if(mCgm is CgmDexcom && type == CGMType.DEXCOM)
      {
        print('kai:createCGM():mCgm is CgmDexcom && type == 
        CGMType.DEXCOM:skip');
        return;
      }
      else if(mCgm is CgmIsense && type == CGMType.ISENSE)
      {
        print('kai:createCGM():mCgm is CgmIsense && type == 
        CGMType.ISENSE:  skip');
        return;
      }
      else

       */
      {
        await disconnectCGM();
      }
    }

    switch (type) {
      case CGMType.DEXCOM:
        // mCgm = new CgmDexcom();
        mCgm = CgmDexcom();
        break;

      case CGMType.ISENSE:
        // mCgm = new CgmIsense();
        if (USE_ISENSE_BROADCASTING == true) {
          mCgm = CgmIsenseBC();
        } else {
          mCgm = CgmIsense();
        }

        break;

      case CGMType.XDRIP:
        // mCgm = new CgmXdrip();
        mCgm = CgmXdrip();
        break;

      case CGMType.MAX_CGM:
        // TODO: Handle this case.
        break;
      case CGMType.NOT_INITIALIZED:
        mCgm = null;
        break;
    }

    //kai_20230807 add to set default response listener here
    if (mCgm != null) {
      debugPrint('kai:RegisterDefaultCgmResponseListener(mCMgr.mCgm)');
      RegisterDefaultCgmResponseListener(mCgm);
      debugPrint('kai:RegisterDefaultBGDataStreamListener(mCMgr.mCgm)');
      RegisterDefaultBGDataStreamListener(mCgm);
    }
    //notifyListeners();
  }

  Future<void> createPUMP(PUMPType type) async {
    if (mPump != null) {
      await disconnectPUMP();
    }
    switch (type) {
      case PUMPType.CARELEVO:
        // mPump = new Pump();
        mPump = Pump(appContext!);
        break;

      case PUMPType.CSP1:
        // mPump = new PumpCsp1();
        mPump = PumpCsp1(appContext!);
        break;

      case PUMPType.DANARS:
        // mPump = new PumpDanars();
        mPump = PumpDanars(appContext!);
        break;

      default:
        // mPump = new Pump();
        mPump = Pump(appContext!);
        break;
    }

    //kai_20230807 add to set default response listener here
    if (mPump != null) {
      debugPrint('kai:mCMgr.RegisterDefaultPumpResponseListener(mCMgr.mPump)');
      RegisterDefaultPumpResponseListener(mPump);
    }
  }

  Future<void> disconnectCGM() async {
    // release previous  cgm object
    if (mCgm != null) {
      debugPrint('kai:disconnectCGM() is call');
      try {
        await mCgm!.disconnectFromDevice();
        mCgm!.clearDeviceInfo();

        ///<  clear previous device information shown on screen.
        // mCgm = null;  ///< kai_20230430  don't need to set null here because mCgm always have one regardless of changing instance
      } catch (e) {
        debugPrint('Error disconnectCGM: $e');
        //kai_20230619 in this case we need to call below due to exception is
        //skip to call clearDeviceInfo()
        mCgm!.clearDeviceInfo();
      }
      // notifyListeners();
    }
  }

  Future<void> disconnectPUMP() async {
    // release previous  Pump object
    if (mPump != null) {
      try {
        await mPump!.disconnectFromDevice();
        mPump!.clearDeviceInfo();

        ///<  clear previous device information shown on screen.
        // mPump = null; ///< kai_20230430  don't need to set null here because mCgm always have one regardless of changing instance
      } catch (e) {
        debugPrint('Error disconnectPUMP: $e');
        //kai_20230619 in this case we need to call below due to exception is
        //skip to call clearDeviceInfo()
        mPump!.clearDeviceInfo();
      }
      // notifyListeners();

    }
  }

  //=======================  IDevice =====================================//
  Future<void> startScan(IDevice? device) async {
    if (device != null) {
      if (device is Pump) {
        await device.startScan(scanTimeout);
      } else if (device is Cgm) {
        await device.startScan(scanTimeout);
      }
      notifyListeners();
    }
  }

  Future<void> stopScan(IDevice? device) async {
    if (device != null) {
      if (device is Pump) {
        device.stopScan();
      } else if (device is Cgm) {
        device.stopScan();
      }
      notifyListeners();
    }
  }

  /*
   * @brief get the scanned cache lists for IDevice and this is available when 
   * scan is complete
   */
  List<BluetoothDevice>? getScannedDeviceLists(IDevice? device) {
    if (device != null) {
      if (device is Pump) {
        return device.getScannedDeviceLists();
      } else if (device is Cgm) {
        return device.getScannedDeviceLists();
      }
    }
  }

  /*
   * @brief try to connect to the specific device
   */
  Future<void> connect(IDevice? device, BluetoothDevice btdevice) async {
    if (device != null) {
      if (device is Pump) {
        await device.connectToDevice(btdevice);
      } else if (device is Cgm) {
        await device.connectToDevice(btdevice);
      }
    }
    notifyListeners();
  }

  /*
   * @brief try to disconnect from the specified device
   */
  Future<void> disconnect(IDevice? device) async {
    if (device != null) {
      if (device is Pump) {
        await device.disconnectFromDevice();
      } else if (device is Cgm) {
        await device.disconnectFromDevice();
      }
    }
    notifyListeners();
  }

  /*
   * @brief get current connected device
   */
  BluetoothDevice? getConnectedDevice(IDevice? device) {
    if (device != null) {
      if (device is Pump) {
        device.getConnectedDevice();
      } else if (device is Cgm) {
        device.getConnectedDevice();
      }
    }
    return null;
  }

  /*
   * @brief get the connected device's model name
   */
  String? getModelName(IDevice? device) {
    if (device != null) {
      if (device is Pump) {
        device.getModelName();
      } else if (device is Cgm) {
        device.getModelName();
      }
    }
    return null;
  }

  /*
   * @brief get device manufacturer Name
   */
  String? getManufacturerName(IDevice? device) {
    if (device != null) {
      if (device is Pump) {
        device.getManufacturerName();
      } else if (device is Cgm) {
        device.getManufacturerName();
      }
    }
    return null;
  }

  /*
   * @brief get the firmware version of the connected device
   */
  String? getFirmwareVersion(IDevice? device) {
    if (device != null) {
      if (device is Pump) {
        device.getFirmwareVersion();
      } else if (device is Cgm) {
        device.getFirmwareVersion();
      }
    }
    return null;
  }

  /*
   * @brief serial number of the connected device
   */
  String? getSerialNumber(IDevice? device) {
    if (device != null) {
      if (device is Pump) {
        device.getSerialNumber();
      } else if (device is Cgm) {
        device.getSerialNumber();
      }
    }
    return null;
  }

  /*
   * @brief get the validation code of the connected device
   */
  String? getVerificationCode(IDevice? device) {
    if (device != null) {
      if (device is Pump) {
        device.getVerificationCode();
      } else if (device is Cgm) {
        device.getVerificationCode();
      }
    }
    return null;
  }

  /*
   * @brief get Battery status Level
   */
  String? getBatteryLevel(IDevice? device) {
    if (device != null) {
      if (device is Pump) {
        device.getBatteryLevel();
      } else if (device is Cgm) {
        device.getBatteryLevel();
      }
    }
    return null;
  }

  /*
   * @brief get current connected device's first connection time.
   */
  int? getConnectedTime(IDevice? device) {
    if (device != null) {
      if (device is Pump) {
        device.getConnectedTime();
      } else if (device is Cgm) {
        device.getConnectedTime();
      }
    }
    return null;
  }

  /*
   * @brief register ResponseCallback to get a notification sent from connected device
   *      for the updating UI as like widgets, dialog, etc..
   *      please refer to the void setResponseMessage(RSPType indexRsp, String message, String ActionType) in Pump class.
   *      and define as like void handleResponseEvent(RSPType indexRsp, String message, String ActionType) and implement it.
   */
  void registerResponseCallbackListener(
    IDevice? device,
    ResponseCallback callback,
  ) {
    if (device != null) {
      if (device is Pump) {
        device.setResponseCallbackListener(callback);
      } else if (device is Cgm) {
        device.setResponseCallbackListener(callback);
      }
    }
  }

  void unRegisterResponseCallbackListener(
    IDevice? device,
    ResponseCallback callback,
  ) {
    if (device != null) {
      if (device is Pump) {
        device.releaseResponseCallbackListener();
      } else if (device is Cgm) {
        device.releaseResponseCallbackListener();
      }
    }
  }

  ResponseCallback? getResponseCallbackListener(IDevice? device) {
    if (device != null) {
      if (device is Cgm) {
        device.getResponseCallbackListener();
      } else if (device is Pump) {
        // Pump does not support IBloodGlucoseStream interface
        device.getResponseCallbackListener();
      }
    }
  }

  //=========================== IPump Specific Functions =======================//
  /*
   * send Dose amount value to the connected Pump device
   */
  void sendSetDose(IDevice? device, String value, int mode) {
    if (device != null) {
      if (device is Pump) {
        // let's consider several type Pump class which have additional APIs here
        if (device is Pump) {
          device.sendSetDoseValue(value, mode, null);
        }
        /*
        else if(device is PumpA)
        {
          (device as PumpA).sendSomething(value, mode, null);
        }
        */
      }
    }
  }

  //=========================== ICgm Specific Functions ========================//
  int getBloodGlucose(IDevice? device) {
    if (device != null) {
      if (device is Cgm) {
        return device.getBloodGlucoseValue();
      }
    }
    return 0;
  }

  int getLastTimeBGReceived(IDevice? device) {
    if (device != null) {
      if (device is Cgm) {
        return device.getLastTimeBGReceived();
      }
    }
    return 0;
  }

  /*
   * @brief this BGStreamCallback registration is only available for CgmXdrip
   *        that implemented IBloodGlucoseStream interface.
   */
  void registerBGStreamDataListen(
      IDevice? device, BGStreamCallback BGcallback) {
    if (device != null) {
      if (device is Cgm) {
        if (device is CgmXdrip) {
          device.RegisterBGStreamDataListen(BGcallback);
        } else {
          //
        }
      } else if (device is Pump) {
        // Pump does not support IBloodGlucoseStream interface
      }
    }
  }

  void UnregisterBGStreamDataListen(IDevice? device) {
    if (device != null) {
      if (device is Cgm) {
        if (device is CgmXdrip) {
          device.UnregisterBGStreamDataListen();
        } else {
          //
        }
      } else if (device is Pump) {
        // Pump does not support IBloodGlucoseStream interface
      }
    }
  }

  BGStreamCallback? getBGStreamDataListener(IDevice? device) {
    if (device != null) {
      if (device is Cgm) {
        if (device is CgmXdrip) {
          device.getBGStreamDataListen();
        } else {
          //
          return null;
        }
      } else if (device is Pump) {
        // Pump does not support IBloodGlucoseStream interface
        return null;
      }
    }
  }

  //kai_20230802  add to keep default BG Data Stream Listener for the cgm that use broadcasting method as like xdrip
  void SetDefaultBGDataStreamListener(BGStreamCallback bGcallback) {
    mDefaultBGDataStreamCallback = bGcallback;
  }

  void RegisterDefaultBGDataStreamListener(IDevice? device) {
    if (mDefaultBGDataStreamCallback != null) {
      if (device != null) {
        if (device is Cgm) {
          if (device is CgmXdrip) {
            device.SetDefaultBGDataStreamListener(
                mDefaultBGDataStreamCallback!);
          } else {
            //
          }
        } else if (device is Pump) {
          // Pump does not support IBloodGlucoseStream interface
        }
      }
    }
  }

  void ReleaseDefaultBGDataStreamListener() {
    mDefaultBGDataStreamCallback = null;
  }

  void SetDefaultCgmResponseListener(ResponseCallback bGcallback) {
    mDefaultCgmResponselistener = bGcallback;
  }

  void RegisterDefaultCgmResponseListener(IDevice? device) {
    if (mDefaultCgmResponselistener != null) {
      if (device != null) {
        if (device is Cgm) {
          device
              .setDefaultResponseCallbackListener(mDefaultCgmResponselistener!);
        } else if (device is Pump) {
          // Pump does not support IBloodGlucoseStream interface
        }
      }
    }
  }

  void ReleaseDefaultCgmResponseListener() {
    mDefaultCgmResponselistener = null;
  }

  void SetDefaultPumpResponseListener(ResponseCallback bGcallback) {
    mDefaultPumpResponselistener = bGcallback;
  }

  void RegisterDefaultPumpResponseListener(IDevice? device) {
    if (mDefaultPumpResponselistener != null) {
      if (device != null) {
        if (device is Cgm) {
        } else if (device is Pump) {
          // Pump does not support IBloodGlucoseStream interface
          device.setDefaultResponseCallbackListener(
              mDefaultPumpResponselistener!);
        }
      }
    }
  }

  void ReleaseDefaultPumpResponseListener() {
    mDefaultPumpResponselistener = null;
  }

  void changeNotifier() {
    notifyListeners();
  }
}
