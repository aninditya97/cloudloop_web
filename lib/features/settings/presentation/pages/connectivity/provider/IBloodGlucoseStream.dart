/*
 * @brief this interface provide default API to listen the bloodglucose data stream sent from XDrip.
 *        If caller want to handle directly,
 *        then caller also can register/unregister the BGStreamCallback that caller implemented
 *        by using RegisterBGStreamDataListen()/UnregisterBGStreamDataListen()
 * @author kai_20230429
 */
typedef BGStreamCallback = void Function(dynamic event);

///< callback function type

abstract class IBloodGlucoseStream {
  Stream<dynamic> get bloodGlucoseDataStream;

  void InitDefaultStreamListen();
  void DeinitDefaultStreamListen();
  void RegisterBGStreamDataListen(BGStreamCallback BGcallback);
  void UnregisterBGStreamDataListen();
  BGStreamCallback? getBGStreamDataListen();
}
