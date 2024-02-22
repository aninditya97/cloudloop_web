import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/*
 * @brief kai_20230226
 * Note that the setString, getInt, and setInt methods now use the null-aware ?.
 * and null-coalescing ?? operators to safely call the corresponding methods on the _prefs variable, which
 * may be null if initPrefs is not called before.
 * The setString and setInt methods now return false if the _prefs variable is null,
 * or if the corresponding methods return null.
 * The getInt method now has a default value for defaultValue parameter, which
 * is used as the return value if the getInt method returns null.
 *
 * << Usage example in application >>
 *
 * await cspPreference.initPrefs();
 * // Set a string value
 * await cspPreference.setString('myKey', 'myValue');
 *
 * // Get a string value
 * String myValue = cspPreference.getString('myKey');
 *log(myValue); // Output: "myValue"
 *
 * Note that the setString, setInt, and other setter methods return a Future<bool> that
 * indicates whether the write operation was successful.
 * This allows you to handle errors and react appropriately if the write operation fails.
 *
 */
class CspPreference {
  static const String pumpSetupfirstTimeDone = 'pumpSetupfirstTimeDone';
  static const String pumpSourceTypeKey = 'pumpSourceTypeKey';
  static const String cgmSourceTypeKey = 'cgmSourceTypeKey';
  static const String dex_txid = 'dex_txid';
  static const String share_key = 'share_key';
  static const String g5_firmware_ = 'g5-firmware-';
  static const String g5_battery_warning_level = 'g5-battery-warning-level';
  static const String G5_battery_level_marker = 'g5-battery-level-';
  static const String pumpReservoirInjectionKey = 'pumpReservoirInjectionKey';
  static const String pumpMaxInfusionThresholdKey =
      'pumpMaxInfusionThresholdKey';
  static const String pumpHclDoseInjectionKey = 'pumpHclDoseInjectionKey';
  static const String pumpSetTimeReqDoneKey = 'setTimeReqDoneKey';
  static const String pumpTestPage = 'pumpTestPage';
  static const String disconnectedByUser = 'disconnectedByUser';
  static const String refillTimePumpKey = 'refillTimePump';
  static const String transmitterInsertTimeKey = 'transmitterInsertTime';
  static const String lastCalibrationTimeKey = 'lastCalibrationTimeCgm';
  // snooze switch and time key, alert sound Type : beep1 (low battery sound), beep2 (occlusion beep sound)
  static const String snoozeSwitchKey = 'snoozeSwitch';

  ///< boolean True(On)/False(Off)
  static const String snoozeTimeValueKey = 'snoozeTimeValue';

  ///< 1,2,5,10,15,20,30,60,90,120 mins
  static const String alertSoundTypeKey = 'alertSoundType';

  ///< beep1, beel2
  static const String broadcastingPolicyNetBolus = 'broadcastingPolicyNetBolus';

  ///< broadcasting policynet's bolus to destination app
  static const String destinationPackageName = 'com.kai.bleperipheral';

  ///< default is bleperipheral app's package name

  /// //kai_20231225  dana pump key
  static const String key_danars_v3_randompairingkey = 'key_danars_v3_randompairingkey';
  static const String key_danars_v3_pairingkey = 'key_danars_v3_pairingkey';
  static const String key_danars_v3_randomsynckey = 'key_danars_v3_randomsynckey';
  static const String key_dana_ble5_pairingkey = 'key_dana_ble5_pairingkey';
  static const String key_danars_pairingkey = 'key_danars_pairingkey';

  // alert threshold value ( glucose Low/ High / urgent Low / default Level )
  /*
  (1) 공복상태 혈당 검사 (fasting glucose)
  [정상치] 70~99 ㎎/ℓ 8시간 이상 공복 후 측정한 혈당이 126 mg/dL 이상인 경우 당뇨병으로 진단이 됩니다.
  당뇨병의 증상이 없다면 한번 더 측정한 후 두 번의 결과를 보고 판정을 내리는 것이 정확합니다.
  공복혈당이 100-125 mg/dl 사이로 나온다면 이것도 정상이 아니고 공복혈당장애(impaired fasting glucose)로 분류합니다.
  이는 당뇨병 전단계 또는 당뇨병이 생길 위험도가 높은 상태인데 그 위험도는 공복혈당장애가 있는 사람이 1년이 지나면 약 10%에서 당뇨병이 생긴다고 합니다.

  (2) 75g 경구 당부하 검사
  포도당 75g을 녹인 용액을 마시고 2시간 후 측정한 혈당이 200 mg/dL 이상인 경우 당뇨병으로 진단이 됩니다.
  포도당을 마신 후에는 가만히 앉아 있다가 측정하는 것이 좋습니다.
    * 정맥혈로 혈당검사를 하는 경우의 당뇨병 진단기준*
  · 공복(최소한 8시간 이상 금식 후) 정맥 혈당이 126 mg/dl 이상인 경우, HbA1c≥6.5%
  · 갈증, 소변량의 증가 또는 체중감소 등의 당뇨병 증상이 있으면서 무작위혈당(식사 여부를 안 따지고 하루 중 아무 때나 측정한 혈당)이 200 mg/dl를 넘는 경우
  · 병원에서 경구 당부하검사(공복 시에 75g의 포도당을 마시는 것)를 하여 2시간 혈당이 200 mg/dl를 넘는 경우

  (3)바람직한 혈당 조절 목표는
  식전, 식후 2시간, 당화혈색소를 기준으로 하며,
  일반적으로 식전 혈당 80~130 mg/dL,
  식후 2시간 혈당 180 mg/dL미만, 당화혈색소 6.5% 미만으로 합니다
  =========================================================
  구분	          ||      정상수치	  ||    조절목표
  공복혈당	        ||  70~100 mg/dl	||  80~130 mg/dL
  식후 2시간 혈당	||  90~140 mg/dL	||  <180 mg/dL
  당화혈색소	      ||    5.7% 미만    ||	6.5% 미만
  =========================================================
   */
  static const String glucoseLowLevelKey = 'glucoseLowLevel';

  ///< under 70 mg
  static const String glucoseHighLevelKey = 'glucoseHighLevel';
  static const String glucoseUrgentLowLevelKey = 'glucoseUrgentLowLevel';
  static const String glucoseDefaultLevelKey = 'glucoseDefaultLevel';

  ///<  Target glucose :
  ///in case that before Meal : 70 ~ 130 mg/dL , In case that after Meal : 90 ~ 180 mg/dL

  // alert threshold value ( sensor signal loss / pump refill ) which is depends on the CGM & Pump firmware side
  // don't need to define them here at this time.

  static SharedPreferences? _prefs;

  static String mPUMP_NAME = '';
  static String mCGM_NAME = '';

  static Future<void> initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    mPUMP_NAME = getString(pumpSourceTypeKey);
    log('initPrefs(): mPUMP_NAME.length = ${mPUMP_NAME.length}');
    if (mPUMP_NAME.isEmpty) {
      await setString(pumpSourceTypeKey, 'CareLevo');

      ///< set default value
      mPUMP_NAME = getString(pumpSourceTypeKey);
    }
    mCGM_NAME = getString(cgmSourceTypeKey);
    log('initPrefs(): mCGM_NAME.length = ${mCGM_NAME.length}');
    if (mCGM_NAME.isEmpty) {
      await setString(cgmSourceTypeKey, 'Dexcom');

      ///< set default value
      mCGM_NAME = getString(cgmSourceTypeKey);
    }
  }

  static SharedPreferences? get prefs {
    return _prefs;
  }

  static String getString(String key, {String defaultValue = ''}) {
    if (prefs == null) {
      initPrefs();
    }
    return _prefs?.getString(key) ?? defaultValue;
  }

  static Future<bool> setString(String key, String value) async {
    if (prefs == null) {
      await initPrefs();
    }

    if (key.contains(cgmSourceTypeKey)) {
      mCGM_NAME = value;
    } else if (key.contains(pumpSourceTypeKey)) {
      mPUMP_NAME = value;
    }

    return await _prefs?.setString(key, value) ?? false;
  }

  static int getInt(String key, {int defaultValue = 0}) {
    if (prefs == null) {
      initPrefs();
    }
    return _prefs?.getInt(key) ?? defaultValue;
  }

  static Future<bool> setInt(String key, int value) async {
    if (prefs == null) {
      await initPrefs();
    }
    return await _prefs?.setInt(key, value) ?? false;
  }

  static bool getBool(String key) {
    if (prefs == null) {
      initPrefs();
    }
    return _prefs?.getBool(key) ?? false;
  }

  static Future<bool> setBool(String key, bool value) async {
    if (prefs == null) {
      await initPrefs();
    }
    return await _prefs?.setBool(key, value) ?? false;
  }

  // booleans
  static bool getBooleanDefaultFalse(final String key) {
    if (prefs == null) {
      initPrefs();
    }
    return (_prefs != null) && (_prefs?.getBool(key) ?? false);
  }

// ... add more getters and setters as needed

  static Uint8List getBytes(String name) {
    if (prefs != null) {
      initPrefs();
    }
    return base64.decode(getString(name));
  }

  static void setBytes(String name, Uint8List value) {
    if (prefs == null) {
      initPrefs();
    }
    setString(name, base64.encode(value));
  }

  static int getStringToInt(String key, {String defaultValue = '300'}) {
    if (prefs == null) {
      initPrefs();
    }
    return int.parse(_prefs?.getString(key) ?? defaultValue);
  }

  static Future<int> getLong(String key, int def) async {
    if (prefs == null) {
      await initPrefs();
    }
    return prefs?.getInt(key) ?? def;
  }

  static Future<bool?> setLong(String key, int lng) async {
    if (prefs == null) {
      await initPrefs();
    }
    return await prefs?.setInt(key, lng);
  }

  static Future<bool> removeValue(String key) async {
    if (prefs == null) {
      await initPrefs();
    }

    return await _prefs?.remove(key) ?? false;
  }
}
