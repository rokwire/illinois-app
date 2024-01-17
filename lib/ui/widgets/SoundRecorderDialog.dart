
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/Log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'dart:io';

import '../../service/Analytics.dart';
import '../../service/Auth2.dart';
import '../../service/Config.dart';

enum RecorderMode{record, play}
class SoundRecorderDialog extends StatefulWidget {
  final String? initialRecordPath; //TBD update type
  final List<int>? initialRecordBytes; //TBD update type

  const SoundRecorderDialog({super.key, this.initialRecordPath, this.initialRecordBytes});

  @override
  _SoundRecorderDialogState createState() => _SoundRecorderDialogState();

  static Future show(BuildContext context, {String? initialRecordPath, List<int>? initialRecordBytes}) {
    return showDialog(
        context: context,
        builder: (_) =>
            Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.all(Radius.circular(5)),
              child: SoundRecorderDialog(initialRecordPath: initialRecordPath, initialRecordBytes: initialRecordBytes),
            )
    );
  }
}

class _SoundRecorderDialogState extends State<SoundRecorderDialog> {
  late SoundRecorderController _controller;

  RecorderMode get _mode => _controller.hasRecord ? RecorderMode.play : RecorderMode.record;

  @override
  void initState() {
    _controller = SoundRecorderController(
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
              (_) => _controller.preparePlayer());  //automatically load after recording is done

  void _onStartRecording() => _controller.startRecording();

  void _onPlay() => _controller.playRecord();

  void _onPausePlay() => _controller.stopRecord();

  void _onTapReset() {
    _controller.resetRecord();
  }

  void _onTapSave() async {
    //TBD Loading/progress
    try {
      File? audioFile = _controller.recordFile;
      if (audioFile?.existsSync() == true) {
        AudioResult result = await VoiceRecordAPI().uploadVoiceRecord(_controller._audioPath);
        if(result.resultType == AudioResultType.succeeded){
          //TBD notify changed
          Log.d(result.data ?? "");
        } else {
          //TBD error
          Log.d(result.errorMessage ?? "");
        }
      }
    }catch(e){
      Log.e(e.toString());
    }
    _closeModal();
  }

  void _onTapClose() {
    Analytics().logAlert(text: "Sound Recording Dialog", selection: "Close");
    _closeModal();
  }

  void _closeModal() {
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

  String get _hintText{
    if(_mode == RecorderMode.record){
      return _controller.isRecording ?
      Localization().getStringEx("", "Release to stop") :
      Localization().getStringEx("", "Hold to record");
    } else {
      return _controller.isPlaying ? Localization().getStringEx("", "Stop listening to your recording"):Localization().getStringEx("", "Listen to your recording");
    }
  }

  String get _statusText{
    if(_mode == RecorderMode.record){
      return _controller.isRecording ?
        Localization().getStringEx("", "Recording") :
        Localization().getStringEx("", "Record");
    } else {
      return playerDisplayTime;
    }
  }

  String get playerDisplayTime => "$_playerElapsedTime/$_playerLengthTime";

  String get _playerElapsedTime => durationToDisplayTime(_controller._playerTimer) ?? _defaultPlayerTime;

  String get _playerLengthTime => durationToDisplayTime(_controller.playerLength) ?? _defaultPlayerTime ;

  String get _defaultPlayerTime => "0:00";

  bool get _resetEnabled => _mode == RecorderMode.play;

  bool get _saveEnabled => _mode == RecorderMode.play;

  String? durationToDisplayTime(Duration? duration) {
    if(duration == null)
      return null;

    final HH =  (duration.inHours).toString().padLeft(1, '0');
    final mm = (duration.inMinutes % 60).toString().padLeft(1, '0');
    final ss = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return duration.inHours > 1 ? '$HH:$mm:$ss' : '$mm:$ss';
  }
}

class SoundRecorderController {
  final Function(void Function()) notifyChanged;
  final String? initialRecordPath; //TBD update to link when ready

  late Record _audioRecord;
  late AudioPlayer _audioPlayer;
  Duration? _playerTimer;
  String? _audioPath = "";
  bool _recording = false;

  SoundRecorderController({required this.notifyChanged, this.initialRecordPath});

  void init() {
    _audioRecord = Record();
    _audioPlayer = AudioPlayer();
    _audioPlayer.positionStream.listen((elapsedDuration) {
      notifyChanged(() => _playerTimer = elapsedDuration);
    });
    if(initialRecordPath != null){
      _audioPath = initialRecordPath!;
      preparePlayer();
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

  //Sets the audioPath to player. This loads the Time and Length of the audio
  Future<void> preparePlayer() async {
    Log.d("AUDIO PREPARING");
    if(StringUtils.isNotEmpty(_audioPath)) {
      await _audioPlayer.setFilePath(_audioPath!);
      notifyChanged(() {});
    }
  }

  void playRecord() async {
    try {
      if (hasRecord) {
        await preparePlayer(); //Reset
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

  void resetRecord() {
    if(_audioPath != initialRecordPath){ //If newly recorded. Do not delete the Initial record file
      _deleteRecord();
    }
    notifyChanged(() {
      _audioPath = null;
    });
    //TBD additional notification if needed
  }

  Future<void> _deleteRecord() async {
    if (_audioPath?.isNotEmpty == true) {
      try {
        File file = File(_audioPath!);
        if (file.existsSync()) {
          file.deleteSync();
          Log.d("FILE DELETED");
        }
      } catch (e) {
        Log.d("FILE NOT DELETED: ${e}");
      }
    }
  }

  //Getters
  bool get isRecording => _recording;

  bool get hasRecord => StringUtils.isNotEmpty(_audioPath);

  String? get recordPath => _audioPath;

  File? get recordFile => StringUtils.isNotEmpty(recordPath) ? File(recordPath!) : null;

  bool get isPlaying => _audioPlayer.playing;

  Duration? get playerLength => _audioPlayer.duration;

  Duration? get playerTime => _playerTimer;
}

class NamePronouncementWidget extends StatefulWidget { //TBD move to EditProfile widgets

  @override
  State<StatefulWidget> createState() => _NamePronouncementState();
}

class _NamePronouncementState extends State<NamePronouncementWidget>{
  late AudioPlayer _audioPlayer;
  String? _storedRecordPath;
  // List<int>? _storedRecordBytes;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadUserRecord();
    // _prepareAudioPlayer();
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container( padding: EdgeInsets.only(right: 8, top: 4),
                child:  Styles().images?.getImage(_hasStoredPronouncement ? 'icon-soundbyte' : 'plus-circle', excludeFromSemantics: true)
            ),
            Visibility(visible: !_hasStoredPronouncement, child:
            Expanded(
                child: GestureDetector(onTap:  _onRecordNamePronouncement, child:
                  Text( Localization().getStringEx("", "Add name pronunciation and how you prefer to be addressed by students (Ex: Please call me Dr. Last Name,First Name, or Nickname. )"),
                    style: Styles().textStyles?.getTextStyle("widget.info.medium.underline"),
                  ),
                )
              ),
            ),
            Visibility(visible: _hasStoredPronouncement, child:
              GestureDetector(onTap:  _onPlayNamePronouncement, child:
                Text( Localization().getStringEx("", "Your name pronunciation recording"),
                  style: Styles().textStyles?.getTextStyle("widget.info.medium.underline"),
                ),
              )
            ),
            Visibility(visible: _hasStoredPronouncement, child:
              InkWell(onTap: _onEditRecord, child:
                Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 4), child:
                  Styles().images?.getImage('edit', excludeFromSemantics: true)
               )
              )
            ),
            Visibility(visible: _hasStoredPronouncement, child:
              InkWell(onTap: _onDeleteNamePronouncement, child:
                Padding(padding: EdgeInsets.only(left: 8, right: 16, top: 4), child:
                  Styles().images?.getImage('icon-delete-record', excludeFromSemantics: true)
                )
              )
            )
          ],
        )
    );
  }

  void _onPlayNamePronouncement() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      } else {
        _prepareAudioPlayer();
        await _audioPlayer.play();
      }
    } catch (e){
      Log.e(e.toString());
    }
  }

  void _prepareAudioPlayer() async {
    Log.d("AUDIO PREPARING");
    if(_hasStoredPronouncement) {
      await _audioPlayer.setFilePath(_storedAudioPronouncement!);
    }
    // String url = "${Config().contentUrl}/voice_record";
    // Map<String, String> headers = Auth2().networkAuthHeaders ?? {};
    // _audioPlayer.setUrl(url, headers: headers);
  }

  void _onRecordNamePronouncement(){
    SoundRecorderDialog.show(context).then((_) => setStateIfMounted(() { })); //TBD from notify
  }

  void _onEditRecord(){
    SoundRecorderDialog.show(context, initialRecordPath: _storedAudioPronouncement).then((_) => setStateIfMounted(() { }));//TBD from notify
    // SoundRecorderDialog.show(context, initialRecordBytes: _storedAudioPronouncement).then((_) => setStateIfMounted(() { }));//TBD from notify
  }

  void _onDeleteNamePronouncement(){
    //TBD Implement progress/loading
    VoiceRecordAPI().deleteVoiceRecord().then((result) {
      if(result?.resultType == AudioResultType.succeeded){
        setStateIfMounted(() {
          _storedRecordPath = null;
          // _storedRecordBytes = null;
        });
      } else {
        //TBD handle error
      }
    });
  }

  void _loadUserRecord() async { //Call when updated. Implement Proper Notification handling for when Record is uploaded
    //TBD Implement progress/loading
    VoiceRecordAPI().retrieveVoiceRecord().then((result) async {
      if(result?.resultType == AudioResultType.succeeded){
          setStateIfMounted(() {
            _storedRecordPath =  result!.data is String ? result.data as String : null ;//Returns directly the file path
          });
      } else {
        //TBD handle error
      }
    });
  }

  // bool get _hasStoredPronouncement => CollectionUtils.isNotEmpty(_storedAudioPronouncement);

  // List<int>? get _storedAudioPronouncement => _storedRecordBytes;

  bool get _hasStoredPronouncement => StringUtils.isNotEmpty(_storedAudioPronouncement);

  String? get _storedAudioPronouncement => _storedRecordPath;
}

//TBD move methods to content.dart
class VoiceRecordAPI {
  static const String profileVoiceRecordFileName = "profile_voice_record.m4a"; //TBD move to proper place

  Future<AudioResult> uploadVoiceRecord(String? filePath) async{ //TBD return type
    String? serviceUrl = Config().contentUrl;
    if (StringUtils.isEmpty(serviceUrl)) {
      return AudioResult.error(AudioErrorType.serviceNotAvailable, 'Missing voice_record BB url.');
    }
    if (StringUtils.isEmpty(filePath)) {
      return AudioResult.error(AudioErrorType.fileNameNotSupplied, 'Missing file name.');
    }
    String url = "$serviceUrl/voice_record";
    File audioFile = File(filePath!);

    StreamedResponse? response = await Network().multipartPost(
        url: url,
        fileKey: "voiceRecord",
        fileName: "record.m4a",
        // fileName: audioFile.name,
        fileBytes: audioFile.readAsBytesSync(),
        contentType: 'audio/m4a',
        auth: Auth2()
    );

    int responseCode = response?.statusCode ?? -1;
    String? responseString = (await response?.stream.bytesToString());
    if (responseCode == 200) {
      return AudioResult.succeed(responseString);
    } else {
      debugPrint("Failed to upload audio. Reason: $responseCode $responseString");
      return AudioResult.error(AudioErrorType.uploadFailed, "Failed to upload audio. $responseString", response);
    }
  }

  Future<AudioResult?> retrieveVoiceRecord() async {
    String? serviceUrl = Config().contentUrl;
    if (StringUtils.isEmpty(serviceUrl)) {
      return AudioResult.error(AudioErrorType.serviceNotAvailable, 'Missing voice_record BB url.');
    }
    String url = "$serviceUrl/voice_record";

    Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    if (responseCode == 200) {
      Directory fileDir= await getApplicationCacheDirectory();
      String filePath = Path.join(fileDir.path, VoiceRecordAPI.profileVoiceRecordFileName);
      Uint8List? storedRecordBytes = response?.bodyBytes;
      try{
        if(CollectionUtils.isNotEmpty(storedRecordBytes)){
          File(filePath).writeAsBytesSync(storedRecordBytes!);
        }
      }catch (e){
        Log.e(e.toString());
      }
      return AudioResult.succeed(filePath);
    } else {
      debugPrint('Failed to retrieve user audio voice_record');
      return AudioResult.error(AudioErrorType.retrieveFailed, response?.body);
    }
  }

  Future<AudioResult?> deleteVoiceRecord() async {
    //TBD

    return AudioResult.succeed(null);
    // return AudioResult.error(AudioErrorType.deleteFailed, "TBD Implement");
  }
}

enum AudioResultType { error, cancelled, succeeded }
enum AudioErrorType {serviceNotAvailable, fileNameNotSupplied, uploadFailed, retrieveFailed, deleteFailed}

class AudioResult {
  AudioResultType? resultType;
  AudioErrorType? errorType;
  String? errorMessage;
  dynamic data;

  AudioResult.error(this.errorType, this.errorMessage, [this.data]) :
        resultType = AudioResultType.error;

  AudioResult.cancel() :
        resultType = AudioResultType.cancelled;

  AudioResult.succeed(this.data) :
        resultType = AudioResultType.succeeded;
}

extension FileExtention on FileSystemEntity{ //file.name
  String? get name {
    return this.path.split(Platform.pathSeparator).last;
  }
}
