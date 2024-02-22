import 'dart:developer';

import 'CgmXdrip.dart';

class CgmIsenseBC extends CgmXdrip {
  final String TAG = 'CgmIsenseBC:';

  //creator   call Cgm creator by using super()
  CgmIsenseBC() : super() {
    log('$TAG:kai:Create CgmIsenseBC():init()');
    InitDefaultStreamListen();
    init();
  }

  void init() {}

}