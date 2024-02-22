import 'dart:convert';
import 'dart:developer';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/Cgm.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/IBloodGlucoseStream.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

//======================   test flag define here  ==============================//
const bool DEBUG_MESSAGE_FLAG = true;

//======================   define const value here =============================//
//eventStream channel for receiving glucose data from xdrip
const String CHANNEL_BLOODGLUCOSE_PAGE = 'app.channel.bloodglucose.data';

class CgmXdrip extends Cgm implements IBloodGlucoseStream {
  //creator   call Cgm creator by using super()
  CgmXdrip() : super() {
    log('$TAG:kai:Create CgmXdrip():InitDefaultStreamListen()');
    InitDefaultStreamListen();
  }
  final String TAG = 'CgmXdrip:';
  final EventChannel _mGlucoseReceiveStream =
      const EventChannel(CHANNEL_BLOODGLUCOSE_PAGE);
  //bloodGlucose event listener callback
  BGStreamCallback? mBGcallback = null;
  //kai_20230802 add default BGDataStream Listener for keeping default listener as default thru connectivityManager
  BGStreamCallback? mDefaultBGDataStreamCallback = null;

  @override
  // TODO: implement bloodGlucoseDataStream
  Stream get bloodGlucoseDataStream =>
      _mGlucoseReceiveStream.receiveBroadcastStream(CHANNEL_BLOODGLUCOSE_PAGE);
  /*
   * @fn _listenBloodGlucosePageStream(dynamic event)
   * @param[in] event : received event data structure based on json
   * @brief receive the glucose data from android MainActivity thru xdrip
   */
  void _listenBloodGlucoseDataStream(dynamic event) {
    // 전달 받은 데이터를 파싱하고 처리하는 코드 작성
    if (mBGcallback != null) {
      if (DEBUG_MESSAGE_FLAG) {
        log('$TAG:kai:caller registered BGStreamCallback is called');
      }
      mBGcallback!(event);
      return;
    }

    //kai_20230802 add to keep default BG data Stream listener
    if (mDefaultBGDataStreamCallback != null) {
      if (DEBUG_MESSAGE_FLAG) {
        log('$TAG:kai:caller registered mDefaultBGDataStreamCallback is called');
      }
      mDefaultBGDataStreamCallback!(event);
      return;
    }

    //check event here
    if (DEBUG_MESSAGE_FLAG) {
      // {"glucose":"150.0","timestamp":"1669944611002","raw":"0.0","direction":"Flat","source":"G6 Native / G5 Native"}
      log('$TAG:Default _listenBloodGlucoseDataStream: is called');
    }
    //parse json format sent from MaiActivity here
    final jsonData = json.decode(event.toString()) as Map<String, dynamic>;

    if (DEBUG_MESSAGE_FLAG) {
      log('$TAG: gluecose = ${jsonData['glucose']}');
      log('$TAG: timestamp = ${jsonData['timestamp']}');
      log('$TAG: raw = ${jsonData['raw']}');
      log('$TAG: direction = ${jsonData['direction']}');
      log('$TAG: source = ${jsonData['source']}');
    }

    /* save received bloodglucose time  and value here */
    final timeDate = int.parse(jsonData['timestamp'].toString());
    final glucose = jsonData['glucose'].toString();
    setLastTimeBGReceived(timeDate);
    //kai_20230613
    // let's check Glucose String include floating point or not first here
    if (glucose.contains('.')) {
      final glucoseValue = double.parse(glucose);
      final glucoseIntValue = glucoseValue.toInt();
      //log(glucoseIntValue); // output: 491
      setBloodGlucoseValue(glucoseIntValue);
    } else {
      final glucoseIntValue = int.parse(glucose);
      //log(glucoseIntValue); // output: 491
      setBloodGlucoseValue(glucoseIntValue);
    }
    cgmModelName = jsonData['source'].toString();
    cgmSN = jsonData['source'].toString();

    // UI Update here
    if (DEBUG_MESSAGE_FLAG) {
      final mCgmGlucoseReceiveTime = DateFormat('yyyy-MM-dd HH:mm a')
          .format(DateTime.fromMillisecondsSinceEpoch(timeDate));
      final mCgmGlucoseValue = jsonData['glucose'].toString();

      log(
        '$TAG:>>xdrip:$mCgmGlucoseReceiveTime: glucose = $mCgmGlucoseValue} '
        'raw = ${jsonData['raw']}',
      );
    }
    // update chart graph after upload received glucose data to server
    // updateBloodGlucosePageBySensor(Glucose);  ///< send bloodglucose data to the DB or notify PolicyNet Executor
    Future.delayed(const Duration(seconds: 5), () {
      if (DEBUG_MESSAGE_FLAG) {
        log(
          '${TAG}call ():_fetchData() after 5 secs Time = '
          '${DateFormat('yyyy-MM-dd HH:mm:ss a').format(DateTime.now())}',
        );
      }
      // _fetchData(); ///< reload or update Screen
    });
  }

  @override
  Future<void> InitDefaultStreamListen() async {
    log('$TAG:kai:InitDefaultStreamListen()');
    bloodGlucoseDataStream.listen(_listenBloodGlucoseDataStream);
  }

  @override
  Future<void> DeinitDefaultStreamListen() async {
    if (mBGcallback != null) {
      mBGcallback = null;
    }
    log('$TAG:kai:DeinitDefaultStreamListen()');
    await bloodGlucoseDataStream.listen(_listenBloodGlucoseDataStream).cancel();
  }

  @override
  void RegisterBGStreamDataListen(BGStreamCallback bGcallback) {
    // TODO: implement RegisterBGStreamDataListen
    log('$TAG:kai:RegisterBGStreamDataListen()');
    mBGcallback = bGcallback;
  }

  @override
  void UnregisterBGStreamDataListen() {
    // TODO: implement unregisterBGStreamDataListen
    log('$TAG:kai:UnregisterBGStreamDataListen()');
    mBGcallback = null;
  }

  @override
  BGStreamCallback? getBGStreamDataListen() {
    // TODO: implement getBGStreamDataListen
    return mBGcallback;
  }

  /**
   * @brief add to keep default BG Data Listener thru connectivityManager when cloudloop is launched
   */
  void SetDefaultBGDataStreamListener(BGStreamCallback bGcallback) {
    log('$TAG:kai:SetDefaultBGDataStreamListener()');
    mDefaultBGDataStreamCallback = bGcallback;
  }

  void ReleaseDefaultBGDataStreamListener() {
    log('$TAG:kai:ReleaseDefaultBGDataStreamListener()');
    mDefaultBGDataStreamCallback = null;
  }

  BGStreamCallback? getDefaultBGDataStreamListener() {
    return mDefaultBGDataStreamCallback;
  }

  @override
  Future<void> clearDeviceInfo() async {
    log('$TAG:kai:clearDeviceInfo()');
    super.clearDeviceInfo();

    if (mBGcallback != null) {
      UnregisterBGStreamDataListen();
    }
    await DeinitDefaultStreamListen();
  }
}
