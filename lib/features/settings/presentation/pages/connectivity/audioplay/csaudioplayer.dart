import 'dart:developer';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_tts/flutter_tts.dart';

const bool _useAudioCache = true;

class CsaudioPlayer {
  // AudioPlayer? csaudioplayer; // = AudioPlayer();
  // AudioCache? maudioCacheplayer;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  set isPlaying(bool value) {
    _isPlaying = value;
  }

  //kai_20230515 let's use assetAudioPlayer
  //sometimes previous implementation API does not work properly.
  AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();

  static String mapSoundToDisplayName(String sound) {
    switch (sound) {
      case 'low_battery_sound.mp3':
        return 'Sound 1';
      case 'bleep_sound.mp3':
        return 'Sound 2';
      default:
        return sound; // Return the original if not found in mapping
    }
  }

  static List<String> getSoundOptions() {
    return [
      'low_battery_sound.mp3',
      'bleep_sound.mp3',
    ];
  }

  void playAssetsAudio() {
    if (assetsAudioPlayer == null) {
      assetsAudioPlayer = AssetsAudioPlayer();
    }
    if (assetsAudioPlayer != null) {
      assetsAudioPlayer
        ..open(
          Audio('assets/sound/low_battery_sound.mp3'),
        )
        ..play();
    }
  }

  void loopAssetsAudio() {
    if (assetsAudioPlayer == null) {
      assetsAudioPlayer = AssetsAudioPlayer();
    }
    if (assetsAudioPlayer != null) {
      assetsAudioPlayer
        ..open(
          Audio('assets/sound/low_battery_sound.mp3'),
        )
        ..setLoopMode(LoopMode.single)
        ..play();
    }
  }

  void playAssetsAudioOcclusion() {
    if (assetsAudioPlayer == null) {
      assetsAudioPlayer = AssetsAudioPlayer();
    }
    if (assetsAudioPlayer != null) {
      assetsAudioPlayer
        ..open(
          Audio('assets/sound/bleep_sound.mp3'),
        )
        ..play();
    }
  }

  void loopAssetsAudioOcclusion() {
    if (assetsAudioPlayer == null) {
      assetsAudioPlayer = AssetsAudioPlayer();
    }
    if (assetsAudioPlayer != null) {
      assetsAudioPlayer
        ..open(
          Audio('assets/sound/bleep_sound.mp3'),
        )
        ..setLoopMode(LoopMode.single)
        ..play();
    }
  }

  void stopAssetsAudio() {
    if (assetsAudioPlayer != null) {
      assetsAudioPlayer.stop();
    }
  }

  /*
   * @brief play alert sound for low battery and occlusion.
   *        this function only consider to play a resource file which is included under the directory "assets/"
   * @param[in] _type : including "battery"  or "occlusion",
   */
  Future<void> playAlertOneTime(String _type) async {
    try {
      var _fname = '';
      if (_type.isNotEmpty && _type.toLowerCase().contains('battery')) {
        _fname = 'low_battery_sound.mp3';
      } else if (_type.isNotEmpty &&
          _type.toLowerCase().contains('occlusion')) {
        _fname = 'bleep_sound.mp3';
      } else {
        _fname = 'low_battery_sound.mp3';
      }
      final filePath = 'assets/sound/$_fname';

      if (_useAudioCache == true) {
        //     if (maudioCacheplayer == null) {
        //       maudioCacheplayer = AudioCache();
        //     }

        //     if (maudioCacheplayer != null) {
        //       //kai_20231020   let's check the case that  previous playback is not stopped while using maudioCacheplayer!.loop()
        //       // csaudioplayer = await maudioCacheplayer!.loop('sound/$_fname', volume: 0.8);
        //       // csaudioplayer =
        //       //     await maudioCacheplayer!.play('sound/$_fname', volume: 0.8);
        //     } else {
        //       log('kai:maudioCacheplayer is null: can not start playAlertOneTime(): isPlaying(${isPlaying}');
        //       return;
        //     }

        //     ///< repeat playback
        //   } else {
        //     final bytes = await rootBundle.load(filePath);
        //     csaudioplayer ??= AudioPlayer();
        //     // await csaudioplayer!.playBytes(bytes.buffer.asUint8List(), volume: 0.8);
      }
      //   isPlaying = true;
      //   // await csaudioplayer!.onPlayerCompletion.first.then((_) {
      //   //   //kai_20231021 add
      //   //   isPlaying = false;
      //   //   log('kai:csaudioplayer!.onPlayerCompletion is called: isPlaying(${isPlaying}');
      //   // });
    } catch (e) {
      log('kai:playAlert(${_type.toString()}): isPlaying(${isPlaying}: catch error( ${e.toString()})');
      //kai_20231021 add to clear
      if (isPlaying == true) {
        isPlaying = false;
        // stopAlert();
      }
    }
  }

  Future<void> playAlert(String _type) async {
    try {
      var _fname = '';
      if (_type.isNotEmpty && _type.toLowerCase().contains('battery')) {
        _fname = 'low_battery_sound.mp3';
      } else if (_type.isNotEmpty &&
          _type.toLowerCase().contains('occlusion')) {
        _fname = 'bleep_sound.mp3';
      } else {
        _fname = 'low_battery_sound.mp3';
      }
      final filePath = 'assets/sound/$_fname';

      //   if (_useAudioCache == true) {
      //     if (maudioCacheplayer == null) {
      //       maudioCacheplayer = AudioCache();
      //     }

      //     if (maudioCacheplayer != null) {
      //       // maudioPlayer = await maudioCacheplayer.play(_fname); ///< playback onetime
      //       //kai_20231020   let's check the case that  previous playback is not stopped while using maudioCacheplayer!.loop()
      //       // csaudioplayer = await maudioCacheplayer!.loop('sound/$_fname', volume: 0.8);
      //       // csaudioplayer =
      //       //     await maudioCacheplayer!.play('sound/$_fname', volume: 0.8);
      //     } else {
      //       log('kai:maudioCacheplayer is null: can not start playAlert(): isPlaying(${isPlaying}');
      //       return;
      //     }

      //     ///< repeat playback
      //   } else {
      //     final bytes = await rootBundle.load(filePath);
      //     csaudioplayer ??= AudioPlayer();
      //     // await csaudioplayer!.playBytes(bytes.buffer.asUint8List(), volume: 0.8);
      //     /*
      //     //below have a error that not find file for the case of using "assets/"
      //     //await checkAssetsFolder();
      //     //await checkFileExists(filePath);
      //     //await maudioPlayer.play('assets/Low-battery-sound.mp3', isLocal: true);
      //     Directory appDocumentsDirectory =
      //     await getApplicationDocumentsDirectory();
      //     log('kai: appDocumentsDirectory = '
      //     + appDocumentsDirectory.path.toString());
      //     await maudioPlayer.play(
      //       'file://${await appDocumentsDirectory.path}/low_battery_sound.mp3',
      //       isLocal: true,
      //     );
      //     */
      //   }
      //   isPlaying = true;
      //   // await csaudioplayer!.onPlayerCompletion.first.then((_) {
      //   //   log(
      //   //     'kai: csaudioplayer!.onPlayerCompletion is called: '
      //   //     'call playAlert() again!!',
      //   //   );
      //   //   //kai_20231021 add
      //   //   isPlaying = false;

      //   //   playAlert(_type);
      //   // });
    } catch (e) {
      log('kai:playAlert(${_type.toString()}): isPlaying(${isPlaying}: catch error( ${e.toString()})');
      //kai_20231021 add to clear
      if (isPlaying == true) {
        isPlaying = false;
        stopAlert();
      }
    }
  }

  /**
      Future<void> playAlertNotification(String _type, String soundFileName) async {
      try {
      var _fname = soundFileName.isNotEmpty ? soundFileName : 'low_battery_sound.mp3';
      if (_type.isNotEmpty && _type.toLowerCase().contains('battery')) {
      _fname = 'low_battery_sound.mp3';
      } else if (_type.isNotEmpty &&
      _type.toLowerCase().contains('occlusion')) {
      _fname = 'bleep_sound.mp3';
      } else {
      _fname = 'low_battery_sound.mp3';
      }
      final filePath = 'assets/sound/$_fname';

      if (_useAudioCache == true) {
      if(maudioCacheplayer == null) {
      maudioCacheplayer = AudioCache();
      }

      if(maudioCacheplayer != null)
      {

      csaudioplayer = await maudioCacheplayer!.play('sound/$_fname', volume: 0.8);
      }
      else
      {
      log('kai:maudioCacheplayer is null: can not start playAlert(): isPlaying(${isPlaying}');
      return;
      }
      ///< repeat playback
      } else {
      final bytes = await rootBundle.load(filePath);
      csaudioplayer ??= AudioPlayer();
      await csaudioplayer!.playBytes(bytes.buffer.asUint8List(), volume: 0.8);

      }
      isPlaying = true;
      await csaudioplayer!.onPlayerCompletion.first.then((_) {
      log(
      'kai: csaudioplayer!.onPlayerCompletion is called: '
      'call playAlert() again!!',
      );
      //kai_20231021 add
      isPlaying = false;

      playAlert(_type);
      });
      } catch (e) {
      log('kai:playAlert(${_type.toString()}): isPlaying(${isPlaying}: catch error( ${e.toString()})');
      //kai_20231021 add to clear
      if(isPlaying == true) {
      isPlaying = false;
      stopAlert();
      }
      }
      }
   **/

  static String mapDisplayNameToSound(String displayName) {
    switch (displayName) {
      case 'Sound 1':
        return 'low_battery_sound.mp3';
      case 'Sound 2':
        return 'bleep_sound.mp3';
      default:
        return displayName; // Return the original if not found in mapping
    }
  }

  Future<void> playAlertNotificationNew(String soundFileName) async {
    try {
      log('inserting playAlertNotificationNew');
      // Selecting the correct sound file
      var soundFile = mapDisplayNameToSound(soundFileName);
      log('on playAlertNotificationNew checking for value on soundFile >> ${soundFile}');

      var _fname = soundFile.isNotEmpty ? soundFile : 'low_battery_sound.mp3';
      log('on playAlertNotificationNew checking for value on _fname >> ${_fname}');

      final filePath = 'assets/sound/$_fname';
      log('checking on playAlertNotificationNew for value on filePath >> ${filePath}');
      // Playing the sound

      void startSound() async {
        // if (_useAudioCache) {
        //   maudioCacheplayer ??= AudioCache();
        //   // csaudioplayer =
        //   //     await maudioCacheplayer!.play('sound/$_fname', volume: 0.8);
        // } else {
        //   final bytes = await rootBundle.load(filePath);
        //   csaudioplayer ??= AudioPlayer();
        //   // await csaudioplayer!
        //   //     .playBytes(bytes.buffer.asUint8List(), volume: 0.8);
        // }
        // isPlaying = true;

        // // When sound completes, restart it if still needed
        // // await csaudioplayer!.onPlayerCompletion.first.then((_) {
        // //   if (isPlaying) {
        // //     startSound(); // Restart sound
        // //   }
        // // });
      }

      log('checking on playAlertNotificationNew for startSound >> ${startSound}');
      startSound();
    } catch (e) {
      // Error handling
      isPlaying = false;
      // stopAlert();
      log('Error in playAlertNotification: ${e.toString()}');
    }
  }

  Future<void> playAlertNotificationCGM(String _type) async {
    try {
      log('inserting playAlertNotificationCGM');
      var _fname = '';
      if (_type.isNotEmpty && _type.toLowerCase().contains('battery')) {
        _fname = 'low_battery_sound.mp3';
      } else if (_type.isNotEmpty &&
          _type.toLowerCase().contains('occlusion')) {
        _fname = 'bleep_sound.mp3';
      } else {
        _fname = 'low_battery_sound.mp3';
      }
      final filePath = 'assets/sound/$_fname';
      log('checking on playAlertNotificationCGM for value on filePath >> ${filePath}');
      // Playing the sound

      void startSound() async {
        if (_useAudioCache) {
          // maudioCacheplayer ??= AudioCache();
          // csaudioplayer =
          //     await maudioCacheplayer!.play('sound/$_fname', volume: 0.8);
        } else {
          final bytes = await rootBundle.load(filePath);
          // csaudioplayer ??= AudioPlayer();
          // await csaudioplayer!
          //     .playBytes(bytes.buffer.asUint8List(), volume: 0.8);
        }
        isPlaying = true;

        // When sound completes, restart it if still needed
        // await csaudioplayer!.onPlayerCompletion.first.then((_) {
        //   if (isPlaying) {
        //     startSound(); // Restart sound
        //   }
        // });
      }

      log('checking on playAlertNotificationCGM for startSound >> ${startSound}');
      startSound();
    } catch (e) {
      // Error handling
      isPlaying = false;
      // stopAlert();
      log('Error in playAlertNotificationCGM: ${e.toString()}');
    }
  }

  Future<void> playAlertNotification(String _type, String soundFileName) async {
    try {
      log('inserting playAlertNotification');
      // Selecting the correct sound file
      var soundFile = mapDisplayNameToSound(soundFileName);
      log('on playAlerNotification checking for value on soundFile >> ${soundFile}');

      var _fname = soundFile.isNotEmpty ? soundFile : 'low_battery_sound.mp3';
      log('on playAlerNotification checking for value on _fname >> ${_fname}');
      log('on playAlertNotificationNew checking for value on _type >> ${_type}');
      if (_type.isNotEmpty && _type.toLowerCase().contains('battery')) {
        _fname = 'low_battery_sound.mp3';
      } else if (_type.isNotEmpty &&
          _type.toLowerCase().contains('occlusion')) {
        _fname = 'bleep_sound.mp3';
      } else {
        _fname = 'low_battery_sound.mp3';
      }
      log('checking on playAlerNotification for value on _fname after condition _type >> ${_fname}');
      final filePath = 'assets/sound/$_fname';

      // Playing the sound
      if (_useAudioCache) {
        // maudioCacheplayer ??= AudioCache();
        // csaudioplayer =
        //     await maudioCacheplayer!.play('sound/$_fname', volume: 0.8);
      } else {
        final bytes = await rootBundle.load(filePath);
        // csaudioplayer ??= AudioPlayer();
        // await csaudioplayer!.playBytes(bytes.buffer.asUint8List(), volume: 0.8);
      }

      isPlaying = true;

      // Handling completion
      // await csaudioplayer!.onPlayerCompletion.first.then((_) {
      //   isPlaying = false;
      //   // Optionally call playAlert(_type) or handle it differently
      // });
    } catch (e) {
      // Error handling
      isPlaying = false;
      // stopAlert();
      log('Error in playAlertNotification: ${e.toString()}');
    }
  }

  Future<void> stopAlert() async {
    try {
      // if (csaudioplayer != null) {
      //   await csaudioplayer!.stop();
      //   isPlaying = false;
      //   log('kai:stopAlert():isPlaying(${isPlaying}):csaudioplayer!.stop()');

      //   if (maudioCacheplayer != null) {
      //     log('kai:stopAlert():isPlaying(${isPlaying}):call maudioCacheplayer!.clearAll()');
      //     await maudioCacheplayer!.clearAll();
      //     maudioCacheplayer = null;
      //   } else {
      //     log('kai:stopAlert():isPlaying(${isPlaying}):maudioCacheplayer is null');
      //   }
      // } else {
      //   log('kai:stopAlert():isPlaying(${isPlaying}):csaudioplayer is null!!');
      // }

      // Dispose of assetsAudioPlayer
      assetsAudioPlayer.dispose();
    } catch (e) {
      log('kai:stopAlert(): Exception: $e');
      // Handle the exception as needed
    }
  }

  /*
  late FlutterTts mflutterTts;
  late bool tts_playing = false;  ///< set false if U want to stop tts playback

  Future speak(String msg) async {

      await mflutterTts.setLanguage("en-US");
      await mflutterTts.setPitch(1);
      if (msg.isEmpty) {
        await mflutterTts.speak("low battery");
      }
      else {
        await mflutterTts.speak(msg);
      }

  }

  Future repeatSpeak(String msg) async {
    await speak(msg);
    //await Future.delayed(Duration(seconds: 1)); // 일정 시간 대기
    Future.delayed(Duration(seconds: 3),(){
    if(tts_playing == true)
    {
      repeatSpeak(msg); // 재귀 호출
    }
    });

  }
*/

  Future<bool> checkAssetsFolder() async {
    final directory = await getApplicationDocumentsDirectory();
    final assetsPath = '${directory.path}/assets/sound';
    if (await Directory(assetsPath).exists()) {
      return true;
    } else {
      log('assets/sound directory not found !!');
      return false;
    }
  }

  Future<bool> checkFileExists(String filePath) async {
    final file = File(filePath);
    if (file.existsSync()) {
      log('File exists: $filePath');
      return true;
    } else {
      log('File not found: $filePath');
      return false;
      // throw FileSystemException('File not found: $filePath');
    }
  }

  Future<void> play(String filePath) async {
    // final hasPermission = await _handleStoragePermission();
    // if (hasPermission) {
    //   // csaudioplayer ??= AudioPlayer();

    //   // final result = await csaudioplayer!.play(filePath, isLocal: true);
    //   // if (result == 1) {
    //   //   // success
    //   //   log('kai: play : Music started playing.');
    //   // }
    // } else {
    //   // do something when permission not granted
    //   log('kai: play: Permission not granted.');
    // }
  }

  Future<void> playRepeat(String filePath) async {
    // csaudioplayer ??= AudioPlayer();
    // await csaudioplayer!.setReleaseMode(ReleaseMode.LOOP);
    // final result = await csaudioplayer!.play(filePath, isLocal: true);
    // if (result == 1) {
    //   // success
    //   log('kai: playRepeat: Music started playing in repeat mode.');
    // } else {
    //   log('kai: playRepeat  is not started!! : csaudioplayer!.play.result = ${result.toString()}');
    // }
  }

  Future<void> stop() async {
    // if (csaudioplayer != null) {
    //   final result = await csaudioplayer!.stop();
    //   if (result == 1) {
    //     // success
    //     log('kai: Playback is stopped.');
    //   } else {
    //     log('kai: Playback  stop is not complete!! : csaudioplayer!.stop().result = ${result.toString()}');
    //   }
    // }
  }

  Future<void> release() async {
    // if (csaudioplayer != null) {
    //   await csaudioplayer!.dispose();
    //   log('kai: csaudioplayer is released.');
    //   csaudioplayer = null;
    // }
  }

  Future<String> getMusicDirectory() async {
    final directory = await getExternalStorageDirectory();
    log('kai: getExternalStorageDirectory() = $directory');
    return '${directory?.path}/Music';
  }

  Future<void> playMusic(String fileName) async {
    // if (await requestPermission()) {
    //   final musicDirectory = await getMusicDirectory();
    //   log('kai: getMusicDirectory() = $musicDirectory');
    //   final filePath = '$musicDirectory/$fileName';
    //   log('kai: filePath() = $musicDirectory');
    //   if (await checkFileExists(filePath) == true) {
    //     csaudioplayer ??= AudioPlayer();
    //     // await csaudioplayer!.play(filePath, isLocal: true);
    //   } else {
    //     log('kai: playMusic  = $filePath failed');
    //   }
    // }
  }

  Future<void> playMusicRepeat(String fileName) async {
    // if (await requestPermission()) {
    //   final musicDirectory = await getMusicDirectory();
    //   final filePath = '$musicDirectory/$fileName';

    //   if (await checkFileExists(filePath) == true) {
    //     csaudioplayer ??= AudioPlayer();
    //     // await csaudioplayer!.setReleaseMode(ReleaseMode.LOOP);
    //     // await csaudioplayer!.play(filePath, isLocal: true);
    //   } else {
    //     log('kai: playMusicRepeat  = $filePath failed');
    //   }
    // }
  }

  Future<void> playLowBatAlert() async {
    final bytes = await rootBundle.load('assets/sound/low_battery_sound.mp3');
    // csaudioplayer ??= AudioPlayer();
    // await csaudioplayer!.playBytes(bytes.buffer.asUint8List(), volume: 0.8);
  }

  Future playLowBatAlertRepeat() async {
    final bytes = await rootBundle.load('assets/sound/low_battery_sound.mp3');
    // csaudioplayer ??= AudioPlayer();
    // final result =
    //     await csaudioplayer!.playBytes(bytes.buffer.asUint8List(), volume: 0.8);
    //int result = await maudioPlayer.play('assets/Low-battery-sound.mp3', isLocal: true);
    // if (result == 1) {
    //   await csaudioplayer!.onPlayerCompletion.first.then((_) {
    //     // 재생이 완료될 때 실행될 코드
    //     playLowBatAlertRepeat(); // 반복 재생
    //   });
    // }
  }

  Future<void> playOcclusionAlert() async {
    final bytes = await rootBundle.load('assets/sound/bleep_sound.mp3');
    // csaudioplayer ??= AudioPlayer();
    // await csaudioplayer!.playBytes(bytes.buffer.asUint8List(), volume: 0.8);
  }

  Future playOcclusionAlertRepeat() async {
    final bytes = await rootBundle.load('assets/sound/bleep_sound.mp3');
    // csaudioplayer ??= AudioPlayer();
    // final result =
    //     await csaudioplayer!.playBytes(bytes.buffer.asUint8List(), volume: 0.8);
    //int result = await maudioPlayer.play('assets/Low-battery-sound.mp3', isLocal: true);
    // if (result == 1) {
    //   await csaudioplayer!.onPlayerCompletion.first.then((_) {
    //     // 재생이 완료될 때 실행될 코드
    //     playOcclusionAlertRepeat(); // 반복 재생
    //   });
    // }
  }

  Future<bool> _handleStoragePermission() async {
    if (!(await Permission.storage.status.isGranted)) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  Future<bool> requestPermission() async {
    final storagePermission = await Permission.storage.status;
    if (storagePermission != PermissionStatus.granted) {
      final permissions = await [
        Permission.storage,
      ].request();
      if (permissions[Permission.storage] != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }
}
