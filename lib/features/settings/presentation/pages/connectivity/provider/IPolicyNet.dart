import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';

class IPolicyNet {
  static const MethodChannel _channel = MethodChannel('ipolicynet');

  Future<void> init() async {
    try {
      // await _channel.invokeMethod('init');
      await _channel.invokeMethod<void>('init');
    } on PlatformException catch (e) {
      throw 'Failed to init: ${e.message}';
    }
  }

  Future<void> broadcasting({
    required double bolus,
    required String pkgName,
  }) async {
    try {
      // await _channel.invokeMethod('broadcasting');
      await _channel.invokeMethod<void>(
        'broadcasting',
        {
          'policyNetBolus': bolus,
          'destinationPkgName': pkgName,
        },
      );
    } on PlatformException catch (e) {
      throw 'Failed to broadcasting: ${e.message}';
    }
  }

  Future<double> execution({
    required List<double> cgmHist,
    required List<String> timeHist,
    required double lastInsulin,
    required int announceMeal,
    required double totalDailyDose,
    required double basalRate,
    required double insulinCarbRatio,
    required double iob,
  }) async {
    try {
      //kai_20230613
      /*
       analysis_options.yaml 파일에서 implicit-dynamic 옵션을 제거하거나 주석 처리하고 프로젝트를 다시 빌드
       implicit-dynamic 옵션을 제거하거나 주석 처리하면, 분석기가 암시적인 동적 유형을 허용하지 않게 됨
      */
      log('kai:IPolicyNet(): execution() is called');
      // final double result =
      // await _channel.invokeMethod('execution', {'cgm_hist': cgmHist});
      // return result;
      final dynamic result = await _channel.invokeMethod<dynamic>(
        'execution',
        {
          'cgm_hist': cgmHist,
          'time_hist': timeHist,
          'last_insulin': lastInsulin,
          'announce_meal': announceMeal,
          'total_daily_dose': totalDailyDose,
          'basal_rate': basalRate,
          'insulin_carb_ratio': insulinCarbRatio,
          'iob': iob,
        },
      );
      final doubleResult = result != null
          ? (result is double ? result : double.parse(result.toString()))
          : 0.0;

      log('kai:IPolicyNet():execution(${doubleResult.toString()})');
      return doubleResult;
    } on PlatformException catch (e) {
      throw 'Failed to execution: ${e.message}';
    }
  }

  Future<double> iobCalculate({
    required double lastInsulin,
  }) async {
    try {
      //kai_20230613
      /*
       analysis_options.yaml 파일에서 implicit-dynamic 옵션을 제거하거나 주석 처리하고 프로젝트를 다시 빌드
       implicit-dynamic 옵션을 제거하거나 주석 처리하면, 분석기가 암시적인 동적 유형을 허용하지 않게 됨
      */
      log('kai:IPolicyNet(): iobCalculate() is called');
      // final double result =
      // await _channel.invokeMethod('execution', {'cgm_hist': cgmHist});
      // return result;
      final dynamic result = await _channel.invokeMethod<dynamic>(
        'iob',
        {
          'last_insulin': lastInsulin,
        },
      );
      final doubleResult = result != null
          ? (result is double ? result : double.parse(result.toString()))
          : 0.0;

      log('kai:IPolicyNet():iobCalculate(${doubleResult.toString()})');
      return doubleResult;
    } on PlatformException catch (e) {
      throw 'Failed to execution: ${e.message}';
    }
  }
}
