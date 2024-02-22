import 'dart:developer';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/Cgm.dart';

class CgmIsense extends Cgm {
  //creator   call Cgm creator by using super()
  CgmIsense() : super() {
    log('kai:Create CgmIsense():init()');
    init();
  }

  void init() {}

  @override
  void handleIsenseCgm(List<int> value) {
    log('kai:CgmIsense.handleIsenseCgm()');
  }

  @override
  void handleCgmAuthenValue(List<int> value) {
    log('kai:CgmIsense.handleCgmAuthenValue()');
  }

  @override
  void clearDeviceInfo() {
    log('kai:CgmIsense.clearDeviceInfo()');
    super.clearDeviceInfo();
  }
}
