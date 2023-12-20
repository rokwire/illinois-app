
import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

import '../../service/Analytics.dart';

enum RecorderMode{record, play}
class SoundRecorderDialog extends StatefulWidget {
  final RecorderMode? mode;

  const SoundRecorderDialog({super.key, this.mode});

  @override
  _SoundRecorderDialogState createState() => _SoundRecorderDialogState();

  static show(BuildContext context, {RecorderMode?mode}) {
    showDialog(
        context: context,
        builder: (_) =>
            Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.all(Radius.circular(5)),
              child: SoundRecorderDialog(mode: mode),
            )
    );
  }
}

class _SoundRecorderDialogState extends State<SoundRecorderDialog> {
  late RecorderMode _mode;
  late PlayerController _controller;
  bool  _processing = false;

  @override
  void initState() {
    _mode = widget.mode ?? RecorderMode.record;
    _controller = PlayerController();
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
                          padding: EdgeInsets.symmetric(horizontal: 38, vertical: 16),
                          child: Column(children: [
                            GestureDetector(
                              onTap:(){
                                  if(_mode == RecorderMode.play){
                                    if(_processing){
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
                                padding: EdgeInsets.all(12),
                                // height: 48, width: 48,
                                decoration: BoxDecoration(
                                    color: _playButtonColor,
                                    shape: BoxShape.circle,
                                ),
                                child: _playButtonIcon ?? Container()
                              ),
                            ),
                            Container(height: 6,),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              child: Text(_statusText, style: Styles().textStyles?.getTextStyle("widget.detail.regular.fat"),)
                            ),
                            Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                child: Text(_hintText, style: Styles().textStyles?.getTextStyle("widget.item.small"),)
                            ),
                            Container(height: 16,),
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
                                Container(width: 24,),
                                SmallRoundedButton( rightIcon: Container(),
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                  label: Localization().getStringEx("", "Save"),
                                  onTap: _onTapSave,
                                  enabled: _saveEnabled,
                                  borderColor: _saveEnabled ? null : Styles().colors?.disabledTextColor,
                                  textColor: _saveEnabled ? null : Styles().colors?.disabledTextColor,
                                ),
                            ],),
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

  void _onStartRecording(){
    setStateIfMounted(() {
      _processing = true;
    });
    _controller.startRecording();
  }

  void _onStopRecording(){
    setStateIfMounted(() {
      _processing = false;
    });
    _controller.stopRecording();

    setStateIfMounted(() { //TBD REMOVE AFTER TEST
      _mode = RecorderMode.play;
    });
  }

  void _onPlay(){
    setStateIfMounted(() {
      _processing = !_processing;
    });
    _controller.playRecord();
  }

  void _onPausePlay(){
    setStateIfMounted(() {
      _processing = !_processing;
    });
    _controller.pauseRecord();
  }

  void _onTapSave(){
    //TBD
  }

  void _onTapReset(){
    _controller.resetRecord();
    setStateIfMounted((){
      _mode = RecorderMode.record;
    });
  }

  void _onTapClose() {
    Analytics().logAlert(text: "Sound Recording Dialog", selection: "Close");
    _closeModal();
  }

  void _closeModal() {
    Navigator.of(context).pop();
  }

  bool get _resetEnabled => _mode == RecorderMode.play;

  bool get _saveEnabled => _mode == RecorderMode.play;

  Color? get _playButtonColor => _mode == RecorderMode.record && _processing ?
    Styles().colors?.fillColorSecondary : Styles().colors?.fillColorPrimary;

  Widget? get _playButtonIcon {
    double iconSize = 58;
    if(_mode == RecorderMode.play){
      return _processing ?
        Styles().images?.getImage('play-circle-white', excludeFromSemantics: true, size: iconSize) : //TBD
        Styles().images?.getImage('play-circle-white', excludeFromSemantics: true, size: iconSize); //TBD
    } else {
      return Styles().images?.getImage('play-circle-white', excludeFromSemantics: true, size: iconSize); //TBD
    }
  }

  String get _statusText{
    if(_mode == RecorderMode.record){
      return _processing ?
        Localization().getStringEx("", "Recording") :
        Localization().getStringEx("", "Record");
    } else {
      return _controller.timerText;
    }
  }

  String get _hintText{
    if(_mode == RecorderMode.record){
      return _processing ?
      Localization().getStringEx("", "Release to stop") :
      Localization().getStringEx("", "Hold to record");
    } else {
      return _processing ? Localization().getStringEx("", "Pause listening"):Localization().getStringEx("", "Listen to your recording");
    }
  }
}

class PlayerController{

  void init(){
    //TBD
  }

  void dispose(){
    //TBD
  }

  void startRecording(){
    //TBD
  }

  void stopRecording(){
    //TBD
  }

  void playRecord(){
    //TBD
  }

  void pauseRecord(){
    //TBD
  }

  void resetRecord(){

  }

  dynamic get record{
    //TBD
  }

  String get timerText{
    return "0:05/0:15"; //TBD implement
  }
}