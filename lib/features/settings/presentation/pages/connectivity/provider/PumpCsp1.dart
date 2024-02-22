import 'dart:developer';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/Pump.dart';
import 'package:flutter/material.dart';

class PumpCsp1 extends Pump {
  final String TAG = 'PumpCsp1:';
  //creator   call Pump creator by using super()
  PumpCsp1(BuildContext context) : super(context) {
    log('kai:Create PumpCsp1():init()');
    init();
  }

  void init() {}
}
