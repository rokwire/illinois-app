
import 'package:flutter/material.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/Log.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'dart:io';

import '../../service/Analytics.dart';

enum RecorderMode{record, play}
class SoundRecorderDialog extends StatefulWidget {
  //TMP:
  static final String storage_key = "profile_audio_pronouncement";
  final String? initialRecordPath; //TBD update type

  const SoundRecorderDialog({super.key, this.initialRecordPath});

  @override
  _SoundRecorderDialogState createState() => _SoundRecorderDialogState();

  static Future show(BuildContext context, {String? initialRecordPath}) {
    return showDialog(
        context: context,
        builder: (_) =>
            Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.all(Radius.circular(5)),
              child: SoundRecorderDialog(initialRecordPath: initialRecordPath),
            )
    );
  }
}

class _SoundRecorderDialogState extends State<SoundRecorderDialog> {
  late PlayerController _controller;

  RecorderMode get _mode => _controller.hasRecord ? RecorderMode.play : RecorderMode.record;

  @override
  void initState() {
    _controller = PlayerController(
      initialRecordPath: widget.initialRecordPath,
      notifyChanged: (fn) =>setStateIfMounted(fn)
    );
    _controller.init();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return SafeArea(child: Container(
        // color: Colors.transparent,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        child: Container(
          padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(5)),
              color: Styles().colors!.background,
            ),
            child: Stack(
                alignment: Alignment.topRight,
                children:[
                  Row(mainAxisSize: MainAxisSize.min, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          child: Column(children: [
                            GestureDetector(
                              onTap:(){
                                  if(_mode == RecorderMode.play){
                                    if(_controller.isPlaying){
                                      _onPausePlay();
                                    }else {
                                      _onPlay();
                                    }
                                  }
                              },
                              onLongPressStart: (_){
                                if(_mode == RecorderMode.record) {
                                  _onStartRecording();
                                }
                              },
                              onLongPressEnd:(_){
                                if(_mode == RecorderMode.record){
                                  _onStopRecording();
                                }
                              } ,
                              child: Container(
                                // padding: EdgeInsets.all(12),
                                // height: 48, width: 48,
                                // decoration: BoxDecoration(
                                //     color: _playButtonColor,
                                //     shape: BoxShape.circle,
                                // ),
                                child: _playButtonIcon ?? Container()
                              ),
                            ),
                            Container(height: 8,),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              child: Text(_statusText, style: Styles().textStyles?.getTextStyle("widget.detail.regular.fat"),)
                            ),
                            Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                child: Text(_hintText, style: Styles().textStyles?.getTextStyle("widget.detail.regular"),)
                            ),
                            Container(height: 16,),
                            Container(padding: EdgeInsets.symmetric(horizontal: 24), child:
                              Row(
                                children: [
                                  SmallRoundedButton( rightIcon: Container(),
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                    label: Localization().getStringEx("", "Reset"),
                                    onTap: _onTapReset,
                                    enabled: _resetEnabled,
                                    borderColor: _resetEnabled ? null : Styles().colors?.disabledTextColor,
                                    textColor: _resetEnabled ? null : Styles().colors?.disabledTextColor,
                                  ),
                                  Container(width: 16,),
                                  SmallRoundedButton( rightIcon: Container(),
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                    label: Localization().getStringEx("", "Save"),
                                    onTap: _onTapSave,
                                    enabled: _saveEnabled,
                                    borderColor: _saveEnabled ? null : Styles().colors?.disabledTextColor,
                                    textColor: _saveEnabled ? null : Styles().colors?.disabledTextColor,
                                  ),
                              ],),
                            ),
                          ],)
                        )
                      ]),
                  ]),
                  Semantics(
                      label: Localization().getStringEx('dialog.close.title', 'Close'),
                      button: true,
                      excludeSemantics: true,
                      child: InkWell(
                          onTap: () {
                            _onTapClose();
                          },
                          child: Container( padding: EdgeInsets.all(16), child:
                          Styles().images?.getImage('close', excludeFromSemantics: true)))),
                ]
            )
        )));
  }

  void _onStopRecording() =>
      _controller.stopRecording().then(
              (_) => _controller.loadPlayer());  //automatically load after recording is done

  void _onStartRecording() => _controller.startRecording();

  void _onPlay() => _controller.playRecord();

  void _onPausePlay() => _controller.stopRecord();

  void _onTapReset() {
    _controller.resetRecord();
    Storage().setStringWithName(SoundRecorderDialog.storage_key, null); //TBD remove
  }

  void _onTapSave(){
    //TBD
    AppToast.show("TBD implement SAVE");
    //TMP: TBD REMOVE
    Storage().setStringWithName(SoundRecorderDialog.storage_key, _controller._audioPath);
    _closeModal();
  }

  void _onTapClose() {
    Analytics().logAlert(text: "Sound Recording Dialog", selection: "Close");
    _closeModal();
  }

  void _closeModal(){
    _controller.stopRecord();
    _controller.stopRecord();
    Navigator.of(context).pop();
  }

  Widget? get _playButtonIcon {
    if(_mode == RecorderMode.play){
      return Styles().images?.getImage('icon-play', excludeFromSemantics: true,);
        // _controller.isPlaying ?
        // Container(padding: EdgeInsets.all(20), child: Container(width: 20, height: 20, color: Styles().colors?.white,)) : //TBD do we need another icon for stop?
        //Styles().images?.getImage('icon-play', excludeFromSemantics: true, size: iconSize);
    } else {
      return _controller.isRecording ?
        Styles().images?.getImage('icon-recording', excludeFromSemantics: true,) :
        Styles().images?.getImage('icon-record', excludeFromSemantics: true,);
    }
  }

  String get _statusText{
    if(_mode == RecorderMode.record){
      return _controller.isRecording ?
        Localization().getStringEx("", "Recording") :
        Localization().getStringEx("", "Record");
    } else {
      return _controller.playerDisplayTime;
    }
  }

  String get _hintText{
    if(_mode == RecorderMode.record){
      return _controller.isRecording ?
      Localization().getStringEx("", "Release to stop") :
      Localization().getStringEx("", "Hold to record");
    } else {
      return _controller.isPlaying ? Localization().getStringEx("", "Stop listening to your recording"):Localization().getStringEx("", "Listen to your recording");
    }
  }

  bool get _resetEnabled => _mode == RecorderMode.play;

  bool get _saveEnabled => _mode == RecorderMode.play;
}

class PlayerController {
  final Function(void Function()) notifyChanged;
  final String? initialRecordPath; //TBD update to link when ready

  late Record _audioRecord;
  late AudioPlayer _audioPlayer;
  Duration? _playerTimer;
  String _audioPath = "";
  bool _recording = false;

  PlayerController({required this.notifyChanged, this.initialRecordPath});

  void init() {
    _audioRecord = Record();
    _audioPlayer = AudioPlayer();
    _audioPlayer.positionStream.listen((elapsedDuration) {
      notifyChanged(() => _playerTimer = elapsedDuration);
    });
    if(initialRecordPath != null){
      _audioPath = initialRecordPath!;
      loadPlayer();
    }
  }

  void dispose() {
    _audioRecord.dispose();
    _audioPlayer.dispose();
  }

  void startRecording() async {
    try {
      Log.d("START RECODING");
      if (await _audioRecord.hasPermission()) {
        notifyChanged(() => _recording = true);
        await _audioRecord.start();
        _recording = await _audioRecord.isRecording();
      }
    } catch (e, stackTrace) {
      Log.d("START RECODING: ${e} - ${stackTrace}");
    }
  }

  Future<void> stopRecording() async {
    Log.d("STOP RECODING");
    try {
      String? path = await _audioRecord.stop();
      _recording = await _audioRecord.isRecording();
      notifyChanged(() {
        _audioPath = path!;
      });
      Log.d("STOP RECODING audioPath = $_audioPath");
    } catch (e) {
      Log.d("STOP RECODING: ${e}");
    }
  }

  Future<void> loadPlayer() async {
    Log.d("AUDIO PREPARING");
    await _audioPlayer.setFilePath(_audioPath);
    notifyChanged(() {});
  }

  void playRecord() async {
    try {
      if (hasRecord) {
        await loadPlayer(); //Reset
        await _audioPlayer.play().then((_) => stopRecord());
      }
    } catch (e) {
      Log.d("AUDIO PLAYING: ${e}");
    }
  }

  void pauseRecord() async {
    try {
      if (_audioPlayer.playing) {
        Log.d("AUDIO PAUSED");
        _audioPlayer.pause();
      }
    } catch (e) {
      Log.d("AUDIO PAUSED: ${e}");
    }
  }

  void stopRecord() async {
    try {
      if (_audioPlayer.playing) {
        Log.d("AUDIO STOPPED");
        _audioPlayer.stop().then((_) => _playerTimer = null);
      }
    } catch (e) {
      Log.d("AUDIO STOPPED: ${e}");
    }
  }

  Future<void> deleteRecording() async {
    if (_audioPath.isNotEmpty) {
      try {
        File file = File(_audioPath);
        if (file.existsSync()) {
          file.deleteSync();
          Log.d("FILE DELETED");
        }
      } catch (e) {
        Log.d("FILE NOT DELETED: ${e}");
      }

      notifyChanged(() {
        _audioPath = "";
      });
    }
  }

  void resetRecord() {
    deleteRecording();
  }

  //Getters
  bool get isRecording => _recording;

  bool get hasRecord => StringUtils.isNotEmpty(_audioPath);

  String get recordPath => _audioPath;

  bool get isPlaying => _audioPlayer.playing;

  String get playerDisplayTime {
    return "$_playerElapsedTime/$_playerLengthTime";
  }

  String get _playerElapsedTime =>
      _playerTimer != null ? displayDuration(_playerTimer!) : "0:00";

  String get _playerLengthTime =>
      _audioPlayer.duration != null ? displayDuration(_audioPlayer.duration!) : "0:00";

  String displayDuration(Duration duration) {
    final HH =  (duration.inHours).toString().padLeft(1, '0');
    final mm = (duration.inMinutes % 60).toString().padLeft(1, '0');
    final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return duration.inHours > 1 ? '$HH:$mm:$ss' : '$mm:$ss';
  }
}

class NamePronouncementPlayer{
  static void play(String filePath) async { //TBD play from url
    try{
    AudioPlayer _audioPlayer = AudioPlayer();
    await _audioPlayer.setFilePath(filePath);
    _audioPlayer.play().then(
            (_) => _audioPlayer.dispose());
    }catch(e){
      print(e);
    }
  }
}