// ignore_for_file: deprecated_member_use

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

//import 'package:flutter/services.dart';
//import 'package:fluttertoast/fluttertoast.dart';
//import 'package:android_intent/intents.dart';

/*
 * @brief  kai_20230227  To use this class
 * below should be registered in XDrip+ androidmanifest.xml
 *
 * <activity
    android:name=".Home"
    android:label="@string/app_name_launcher"
    android:launchMode="singleTask">
    <intent-filter>
    <action android:name="android.intent.action.MAIN" />

    <category android:name="android.intent.category.LAUNCHER" />
    <category android:name="android.intent.category.MULTIWINDOW_LAUNCHER" />
    </intent-filter>

    <!-- kai_20230227 add to use url_launcher in flutter
     app in order to invoke xdrip
    This intent filter will handle the URL scheme -->
    <intent-filter>
    <action android:name="android.intent.action.VIEW" />

    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />

    <!-- The scheme should match the one you want to use -->
    <data android:scheme="xdrip" />
    </intent-filter>
    </activity>
 *
 * also need to configure belwo in browser
 * there may be an additional step needed to launch the app when you type "xdrip://" in the Chrome browser.
 * You can try the following steps:
 * Open the Chrome browser on your Android device.
 * Type "chrome://flags" in the address bar and press Enter.
 * In the search bar, type "enable-url-handling-api" and press Enter.
 * Tap the drop-down menu and select "Enabled".
 * Restart Chrome.
 * Type "xdrip://" in the address bar and press Enter. This should launch the xDrip+ app on your device.
 * that's why we are not recommed to use openXDrip API, instead use
 * launchXDrip API
 */

class XDripLauncher {
  static const String _packageName = 'com.eveningoutpost.dexdrip';
  static const String _activityName = 'com.eveningoutpost.dexdrip.Home';
  static const String _CareSensAirPkgName = 'com.isens.csair'; //'com.isens.csair.ui.activity.LauncherActivity';

  static Future<void> openXDrip() async {
    if (await canLaunch('package:$_packageName')) {
      await launch('package:$_packageName/$_activityName');
    } else {
      debugPrint('Could not launch XDrip');
    }
  }

  static Future<void> launchXDripHome() async {
    const intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      package: 'com.eveningoutpost.dexdrip',
      data: 'xdrip://',
    );
    await intent.launch();
  }

  /*
   * @brief if use below API then we should add exported = true to  xdrip's
   * androidmanifest.xml as below;
   *
   *  <activity
      android:name=".StartNewSensor"
      android:exported="true"
      android:configChanges="orientation|screenSize"
      android:label="@string/title_activity_start_new_sensor" />
   */
  static Future<void> startNewSensor() async {
/*
    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      package: 'com.eveningoutpost.dexdrip',
      componentName: 'com.eveningoutpost.dexdrip.StartNewSensor',
    );
    await intent.launch();

 */
    const intent = AndroidIntent(
      action: 'com.eveningoutpost.dexdrip.START_SENSOR',
      package: 'com.eveningoutpost.dexdrip',
      componentName: 'com.eveningoutpost.dexdrip.StartNewSensor',
    );

    await intent.launch();
  }

  static Future<void> bgHistory() async {
/*
    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      package: 'com.eveningoutpost.dexdrip',
      componentName: 'com.eveningoutpost.dexdrip.BGHistory',
    );
    await intent.launch();

 */
    const intent = AndroidIntent(
      action: 'com.eveningoutpost.dexdrip.BGHistory',
      package: 'com.eveningoutpost.dexdrip',
      componentName: 'com.eveningoutpost.dexdrip.BGHistory',
    );

    await intent.launch();
  }

  static Future<void> bluetoothScan() async {
/*
    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      package: 'com.eveningoutpost.dexdrip',
      componentName: 'com.eveningoutpost.dexdrip.BluetoothScan',
    );
    await intent.launch();

 */
    const intent = AndroidIntent(
      action: 'com.eveningoutpost.dexdrip.BluetoothScan',
      package: 'com.eveningoutpost.dexdrip',
      componentName: 'com.eveningoutpost.dexdrip.BluetoothScan',
    );

    await intent.launch();
  }

  static Future<void> fakeNumbers() async {
    const intent = AndroidIntent(
      action: 'com.eveningoutpost.dexdrip.FakeNumbers',
      package: 'com.eveningoutpost.dexdrip',
      componentName: 'com.eveningoutpost.dexdrip.FakeNumbers',
    );

    await intent.launch();
  }


  static Future<bool> isXdripInstalled() async {
    final isinstalled = await isAppExists(_packageName);

    if(isinstalled == false)
    {
      final isinstalled2 = await canLaunch('package:$_packageName');
      if(isinstalled2 == false) {
        debugPrint('kai:$_packageName does not exist');
      }
      return isinstalled2;
    }
    //return isAppExists(_packageName);
    return isinstalled;
  }

  static Future<bool> isCareSensAirInstalled()
  async {
    final isinstalled = await isAppExists(_CareSensAirPkgName);

    if(isinstalled == false)
    {
      final isinstalled2 = await canLaunch('package:$_CareSensAirPkgName');
      if(isinstalled2 == false) {
        debugPrint('kai:$_CareSensAirPkgName does not exist');
      }
      return isinstalled2;
    }

   // return isAppExists(_CareSensAirPkgName);
   return isinstalled;
  }

  static Future<bool> isAppExists(String packageName) async {
    IAppLauncher appLauncher = IAppLauncher(); // 인스턴스 생성
    final isAppInstalled = await appLauncher.isAppInstalled(packageName);
    return isAppInstalled;
  }

  static Future<void> launchCareSensAir() async {
    /*
    IAppLauncher appLauncher = IAppLauncher(); // 인스턴스 생성
    await appLauncher.launchApp(_CareSensAirPkgName);
*/

    //main Launcher
    /*
    const intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      package: _CareSensAirPkgName,
    //  data: 'https://',
      componentName: 'com.isens.csair.ui.activity.LauncherActivity',
    );
*/
    //Login
    const intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      package: _CareSensAirPkgName,
      data: 'https://',
      componentName: 'com.isens.csair.ui.activity.LogInActivity',
    );
    await intent.launch();

  }

}

/*
*@brief IAppLauncher provide APIs as below;
*       check application package is installed on the platform or not
*       and launch the application
 */
class IAppLauncher {
  final String TAG = 'IAppLauncher:';
  final MethodChannel _channel = MethodChannel('iapplauncher');
 // final _channel = const MethodChannel('app_check_plugin');

  Future<bool> isAppInstalled(String packageName) async {
    try {
      final dynamic result = await _channel.invokeMethod<bool>('isAppInstalled', {"packageName": packageName});
      return (result == null) ? false : result as bool;
    } on PlatformException catch (e) {
      debugPrint("${TAG}kai:Failed to check app installed: '${e.message}'.");
      return false;
    }
  }

  Future<void> launchApp(String packageName) async {
    try {
      await _channel.invokeMethod<void>('launchApp', {"packageName": packageName});
    } on PlatformException catch (e) {
      debugPrint("${TAG}kai:Failed to launch app: '${e.message}'.");
    }
  }

}

/*
import 'package:flutter_appavailability/flutter_appavailability.dart';
import 'package:android_intent/android_intent.dart';

class XDripLauncher {
  static void launch() async {
    String xdripPackageName = 'com.eveningoutpost.dexdrip';
    bool isXDripInstalled = 
    await AppAvailability.isAppEnabled(xdripPackageName);
    if (isXDripInstalled) {
      await AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        data: 'dexdrip://com.eveningoutpost.dexdrip.Home',
      ).launch();
    } else {
      // show error message or redirect to app store
    }
  }
}

 */
