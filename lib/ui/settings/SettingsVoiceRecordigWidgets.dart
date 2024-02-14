
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/Log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'dart:io';

import '../../service/Analytics.dart';

class NamePronouncementWidget extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _NamePronouncementState();
}

class _NamePronouncementState extends State<NamePronouncementWidget> implements NotificationsListener {
  late AudioPlayer _audioPlayer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Auth2.notifyVoiceRecordChanged]);
    _audioPlayer = AudioPlayer();
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
                child:  _loading ? _progressIndicator :
                Styles().images.getImage(_hasStoredPronouncement ? 'icon-soundbyte' : 'plus-circle', excludeFromSemantics: true)
            ),
            Visibility(visible: !_hasStoredPronouncement, child:
            Expanded(
                child: GestureDetector(onTap:  _onRecordNamePronouncement, child:
                Text( Localization().getStringEx("", "Add name pronunciation and how you prefer to be addressed (Ex: Please call me Dr. Last Name, First Name, or Nickname. )"),
                  style: Styles().textStyles.getTextStyle("widget.info.medium.underline"),
                ),
                )
            ),
            ),
            Visibility(visible: _hasStoredPronouncement, child:
            GestureDetector(onTap:  _onPlayNamePronouncement, child:
            Text( Localization().getStringEx("", "Your name pronunciation recording"),
              style: Styles().textStyles.getTextStyle("widget.info.medium.underline"),
            ),
            )
            ),
            Visibility(visible: _hasStoredPronouncement, child:
            InkWell(onTap: _onEditRecord, child:
            Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 4), child:
            Styles().images.getImage('edit', excludeFromSemantics: true)
            )
            )
            ),
            Visibility(visible: _hasStoredPronouncement, child:
            InkWell(onTap: _onDeleteNamePronouncement, child:
            Padding(padding: EdgeInsets.only(left: 8, right: 16, top: 4), child:
            Styles().images.getImage('icon-delete-record', excludeFromSemantics: true)
            )
            )
            )
          ],
        )
    );
  }

  @override
  void onNotification(String name, param) {
    if(name == Auth2.notifyVoiceRecordChanged){
      setStateIfMounted(() { });
    }
  }

  Widget get _progressIndicator => SizedBox(width: 16, height: 16, child:
  CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,));

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
      await _audioPlayer.setAudioSource(BytesAudioSource(_storedAudioPronouncement!));
    }
  }

  void _onRecordNamePronouncement(){
    SoundRecorderDialog.show(context);
  }

  void _onEditRecord(){
    SoundRecorderDialog.show(context, initialRecordBytes: _storedAudioPronouncement);
  }

  void _onDeleteNamePronouncement(){
    setStateIfMounted(() => _loading = true);
    Content().deleteVoiceRecord().then((result) {
      setStateIfMounted(() => _loading = false);
      if(result?.resultType != AudioResultType.succeeded){
        AppAlert.showMessage(context, Localization().getStringEx("", "Unable to delete. Please try again."));
      }
    });
  }

  bool get _hasStoredPronouncement => CollectionUtils.isNotEmpty(_storedAudioPronouncement);

  Uint8List? get _storedAudioPronouncement => Auth2().authVoiceRecord;
}

enum RecorderMode{record, play}
class SoundRecorderDialog extends StatefulWidget {
  final Uint8List? initialRecordBytes;

  const SoundRecorderDialog({super.key, this.initialRecordBytes});

  @override
  _SoundRecorderDialogState createState() => _SoundRecorderDialogState();

  static Future show(BuildContext context, {String? initialRecordPath, Uint8List? initialRecordBytes}) {
    return showDialog(
        context: context,
        builder: (_) =>
            Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.all(Radius.circular(5)),
              child: SoundRecorderDialog(initialRecordBytes: initialRecordBytes),
            )
    );
  }
}

class _SoundRecorderDialogState extends State<SoundRecorderDialog> {
  late SoundRecorderController _controller;
  bool _loading = false;

  RecorderMode get _mode => _controller.canPlay ? RecorderMode.play : RecorderMode.record;

  @override
  void initState() {
    _controller = SoundRecorderController(
      initialAudio: widget.initialRecordBytes,
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
              color: Styles().colors.background,
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
                              child: Text(_statusText, style: Styles().textStyles.getTextStyle("widget.detail.regular.fat"),)
                            ),
                            Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                child: Text(_hintText, style: Styles().textStyles.getTextStyle("widget.detail.regular"),)
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
                                    borderColor: _resetEnabled ? null : Styles().colors.disabledTextColor,
                                    textColor: _resetEnabled ? null : Styles().colors.disabledTextColor,
                                  ),
                                  Container(width: 16,),
                                  SmallRoundedButton( rightIcon: Container(),
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                    label: Localization().getStringEx("", "Save"),
                                    progress: _loading,
                                    onTap: _onTapSave,
                                    enabled: _saveEnabled,
                                    borderColor: _saveEnabled ? null : Styles().colors.disabledTextColor,
                                    textColor: _saveEnabled ? null : Styles().colors.disabledTextColor,
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
                          Styles().images.getImage('close', excludeFromSemantics: true)))),
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
    if(_saveEnabled == false)
      return;

    try {
      Uint8List? audioBytes = _controller.record;
      if (audioBytes != null) {
        setStateIfMounted(() => _loading = true);
        AudioResult result = await Content().uploadVoiceRecord(audioBytes);
        if(result.resultType == AudioResultType.succeeded){
          setStateIfMounted(() => _loading = false);
          Log.d(result.data ?? "");
          _closeModal();
        } else {
          Log.d(result.errorMessage ?? "");
          AppAlert.showMessage(context, Localization().getStringEx("", "Unable to Save. Please try again."));
        }
      } else {
        AppAlert.showMessage(context, Localization().getStringEx("", "Unable to Save. Please try again."));
        Log.d("No File to save");
      }
    }catch(e){
      Log.e(e.toString());
    }
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
      return Styles().images.getImage('icon-play', excludeFromSemantics: true,);
        // _controller.isPlaying ?
        // Container(padding: EdgeInsets.all(20), child: Container(width: 20, height: 20, color: Styles().colors.white,)) : //TBD do we need another icon for stop?
        //Styles().images.getImage('icon-play', excludeFromSemantics: true, size: iconSize);
    } else {
      return _controller.isRecording ?
        Styles().images.getImage('icon-recording', excludeFromSemantics: true,) :
        Styles().images.getImage('icon-record', excludeFromSemantics: true,);
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
      return _playerDisplayTime;
    }
  }

  String get _playerDisplayTime => "$_playerElapsedTime/$_playerLengthTime";

  String get _playerElapsedTime => durationToDisplayTime(_controller._playerTimer) ?? _defaultPlayerTime;

  String get _playerLengthTime => durationToDisplayTime(_controller.playerLength) ?? _defaultPlayerTime ;

  String get _defaultPlayerTime => "0:00";

  bool get _resetEnabled => _mode == RecorderMode.play;

  bool get _saveEnabled => _controller.hasRecord;

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
  final Uint8List? initialAudio;

  late Record _audioRecord;
  late AudioPlayer _audioPlayer;
  Duration? _playerTimer;
  String? _audioRecordPath = ""; //The path of the tmp audio Record so we can delete it.
  Uint8List? _audio;//The bytes of the recorded audio
  bool _recording = false;

  SoundRecorderController({required this.notifyChanged, this.initialAudio});

  void init() {
    _audioRecord = Record();
    _audioPlayer = AudioPlayer();
    _audioPlayer.positionStream.listen((elapsedDuration) {
      notifyChanged(() => _playerTimer = elapsedDuration);
    });
    if(initialAudio!= null){
      _audio = initialAudio;
      preparePlayer();
    }
  }

  void dispose() {
    _deleteRecord(); //clean the tmp file
    _audioRecord.dispose();
    _audioPlayer.dispose();
  }

  void startRecording() async {

    try {
      Log.d("START RECODING");
      if (await _audioRecord.hasPermission()) {
        notifyChanged(() => _recording = true);
        await _audioRecord.start(path: await _constructFilePath);
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
      var audioBytes = await getFileAsBytes(path);
      notifyChanged(() {
        _audio = audioBytes;
        _audioRecordPath = path;
      });
      Log.d("STOP RECODING audioPath = $_audioRecordPath");
    } catch (e) {
      Log.d("STOP RECODING: ${e}");
    }
  }

  //Sets the audioPath to player. This loads the Time and Length of the audio
  Future<void> preparePlayer() async {
    Log.d("AUDIO PREPARING");
    try {
      if(_haveAudio)
        await _audioPlayer.setAudioSource(_audioSource!);
      notifyChanged(() {});
    } catch(e){
      Log.d(e.toString());
    }
  }

  void playRecord() async {
    try {
      if (canPlay) {
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
      _deleteRecord();
      notifyChanged(() {
        _audioRecordPath = null;
        _audio = null;
      });
  }

  Future<void> _deleteRecord() async {
    if (_audioRecordPath?.isNotEmpty == true) {
      try {
        File file = File(_audioRecordPath!);
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

  bool get hasRecord => _haveAudio;

  Uint8List? get record => _audio;

  bool get canPlay => _haveAudio;

  bool get isPlaying => _audioPlayer.playing;

  Duration? get playerLength => _audioPlayer.duration;

  Duration? get playerTime => _playerTimer;

  AudioSource? get _audioSource => _haveAudio ? BytesAudioSource(_audio!) : null;

  bool get _haveAudio => CollectionUtils.isNotEmpty(_audio);

  Future<String?> get _constructFilePath async {
    Directory dir = await getApplicationDocumentsDirectory();

    return dir.existsSync() ? Path.join(dir.path, "tmp_audio.m4a") : null;
  }

  Future<Uint8List?> getFileAsBytes(String? filePath) async{
    if(StringUtils.isNotEmpty(filePath)){
      File file = File(filePath!);
      try{
        if(file.existsSync()){
          return file.readAsBytes();
        }
      } catch(e) {
        Log.e(e.toString());
      }
    }

    return null;
  }
}

class BytesAudioSource extends StreamAudioSource{
  final Uint8List _data;

  BytesAudioSource(this._data);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // Returning the stream audio response with the parameters
    return StreamAudioResponse(
      sourceLength: _data.length,
      contentLength: (end ?? _data.length) - (start ?? 0),
      offset: start ?? 0,
      stream: Stream.fromIterable([_data.sublist(start ?? 0, end)]),
      contentType: 'audio/mp4',
    );
  }
}
