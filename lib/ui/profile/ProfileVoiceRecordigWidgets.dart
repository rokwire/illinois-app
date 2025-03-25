import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/AudioUtils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/Log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'dart:io';


class ProfileNamePronouncementWidget extends StatefulWidget {

  final EdgeInsets margin;

  ProfileNamePronouncementWidget({super.key, this.margin = const EdgeInsets.symmetric(horizontal: 16)});

  @override
  State<StatefulWidget> createState() => _ProfileNamePronouncementState();

  EdgeInsetsGeometry get horzMargin => EdgeInsets.only(left: margin.left, right: margin.right);
  EdgeInsetsGeometry get vertMargin => EdgeInsets.only(top: margin.top, bottom: margin.bottom);
}

class _ProfileNamePronouncementState extends State<ProfileNamePronouncementWidget> with NotificationsListener {
  AudioPlayer? _audioPlayer;
  bool _playbackActivity = false;
  bool _editActivity = false;
  bool _deleteActivity = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [Auth2.notifyProfileNamePronunciationChanged]);
    super.initState();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(padding: widget.vertMargin, child:
    _hasStoredPronouncement ? _pronouncementContent : _addPronouncementContent,
  );

  Widget get _pronouncementContent => Row(children: [
    Padding(padding: EdgeInsets.only(left: widget.margin.left, right: 8), child:
      _playbackActivity ? _progressIndicator : _playIcon,
    ),

    Expanded(child:
      InkWell(onTap:  _onPlayNamePronouncement, child:
        Text( Localization().getStringEx("", "Your name pronunciation recording"),
          style: Styles().textStyles.getTextStyle("widget.info.regular.thin.underline"),
        ),
      ),
    ),

    InkWell(onTap: _onEditRecord, child:
      Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8), child:
        _editActivity ? _progressIndicator : _editIcon
      )
    ),

    InkWell(onTap: _onDeleteNamePronouncement, child:
      Padding(padding: EdgeInsets.only(left: 8, right: widget.margin.right, top: 8, bottom: 8), child:
      _deleteActivity ? _progressIndicator : _trashIcon
      )
    ),

  ],);

  Widget get _addPronouncementContent => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: EdgeInsets.only(left: widget.margin.left, right: 8, top: 4), child:
      _addIcon,
    ),

    Expanded(child:
      Padding(padding: EdgeInsets.only(right: widget.margin.right), child:
        InkWell(onTap:  _onRecordNamePronouncement, child:
          Text(Localization().getStringEx("", "Add name pronunciation and how you prefer to be addressed (Ex: Please call me Dr. Last Name, First Name, or Nickname. )"),
            style: Styles().textStyles.getTextStyle("widget.info.regular.thin.underline"),
          ),
        ),
      ),
    ),
  ]);


  @override
  void onNotification(String name, param) {
    if(name == Auth2.notifyProfileNamePronunciationChanged){
      setStateIfMounted(() { });
    }
  }

  Widget get _progressIndicator => SizedBox(width: 16, height: 16, child:
    CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,)
  );

  Widget? get _playIcon => (_audioPlayer?.playing == true) ? _highVolumeIcon : _volumeIcon;
  Widget? get _highVolumeIcon => Styles().images.getImage('volume', size: 16, excludeFromSemantics: true);
  Widget? get _volumeIcon => Styles().images.getImage('volume', size: 16, excludeFromSemantics: true);
  Widget? get _addIcon => Styles().images.getImage('plus-circle', size: 16, excludeFromSemantics: true);
  Widget? get _trashIcon => Styles().images.getImage('trash', size: 16, excludeFromSemantics: true);
  Widget? get _editIcon => Styles().images.getImage('edit', size: 16, excludeFromSemantics: true);

  void _onPlayNamePronouncement() async {
    if (_audioPlayer == null) {
      if (_playbackActivity == false) {
        setState(() {
          _playbackActivity = true;
        });

        AudioResult? result = await Content().loadUserNamePronunciation();

        if (mounted) {
          Uint8List? audioData = (result?.resultType == AudioResultType.succeeded) ? result?.audioData : null;
          if (audioData != null) {
            _audioPlayer = AudioPlayer();

            _audioPlayer?.playerStateStream.listen((PlayerState state) {
              if ((state.processingState == ProcessingState.completed) && mounted) {
                setState(() {
                  _audioPlayer?.dispose();
                  _audioPlayer = null;
                });
              }
            });

            Duration? duration;
            try { duration = await _audioPlayer?.setAudioSource(Uint8ListAudioSource(audioData)); }
            catch(e) {}

            if (mounted) {
              if ((duration != null) && (duration.inMilliseconds > 0)) {
                setState(() {
                  _playbackActivity = false;
                  _audioPlayer?.play();
                });
              }
              else {
                _handlePronunciationPlaybackError();
              }
            }
          }
          else {
            _handlePronunciationPlaybackError();
          }
        }
      }
      else {
        // ignore taps while initializing
      }
    }
    else if (_audioPlayer?.playing == true) {
      setState(() {
        _audioPlayer?.pause();
      });
    }
    else {
      setState(() {
        _audioPlayer?.play();
      });
    }
  }

  void _handlePronunciationPlaybackError() {
    setState(() {
      _playbackActivity = false;
      _audioPlayer?.dispose();
      _audioPlayer = null;
    });
    AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.info.playback.failed.text', 'Failed to play audio stream.'));
  }

  void _onRecordNamePronouncement(){
    ProfileSoundRecorderDialog.show(context);
  }

  void _onEditRecord() async {
    Uint8List? audioData;
    if (_hasStoredPronouncement && !_editActivity) {
      setStateIfMounted(() { _editActivity = true; });

      AudioResult? audioResult = await Content().loadUserNamePronunciation();
      audioData = (audioResult?.resultType == AudioResultType.succeeded) ? audioResult?.audioData : null;

      setStateIfMounted(() { _editActivity = false; });
    }
    if (mounted) {
      AudioResult? audioResult = await ProfileSoundRecorderDialog.show(context, initialRecordBytes: audioData);
      if (mounted && (audioResult?.resultType == AudioResultType.succeeded)) {
        setState(() { _editActivity = true; });
        Auth2UserProfile profile = Auth2UserProfile.fromOther(Auth2().profile,
          override: Auth2UserProfile(
            pronunciationUrl: Content().getUserNamePronunciationUrl(accountId: Auth2().accountId),
          ),
          scope: { Auth2UserProfileScope.pronunciationUrl }
        );
        bool profileResult = await Auth2().saveUserProfile(profile);
        if (mounted) {
          setState(() { _editActivity = false; });
          if (profileResult != true) {
            AppAlert.showTextMessage(context, Localization().getStringEx("panel.profile_info.pronunciation.upload.failed.msg", "Failed to upload pronunciation audio. Please try again later."));
          }
        }
      }
    }
  }

  void _onDeleteNamePronouncement() async {
    bool? promptResult = await ProfileNamePronouncementConfirmDeleteDialog.show(context);
    
    if (mounted && (promptResult == true)) {
      setState(() => _deleteActivity = true);
      
      AudioResult? audioResult = await Content().deleteUserNamePronunciation(); 
      if (audioResult?.resultType == AudioResultType.succeeded) {
        Auth2UserProfile profile = Auth2UserProfile.fromOther(Auth2().profile,
          override: Auth2UserProfile(),
          scope: { Auth2UserProfileScope.pronunciationUrl }
        );
        bool profileResult = await Auth2().saveUserProfile(profile);
        if (mounted) {
          setState(() => _deleteActivity = false);
          if (profileResult != true) {
            AppAlert.showTextMessage(context, Localization().getStringEx("panel.profile_info.pronunciation.delete.failed.msg", "Failed to delete pronunciation audio. Please try again later."));
          }
        }
      }
      else if (mounted) {
        setState(() => _deleteActivity = false);
        AppAlert.showTextMessage(context, Localization().getStringEx("panel.profile_info.pronunciation.delete.failed.msg", "Failed to delete pronunciation audio. Please try again later."));
      }
    }
  }

  bool get _hasStoredPronouncement => StringUtils.isNotEmpty(Auth2().profile?.pronunciationUrl);

  //Uint8List? get _storedAudioPronouncement => Auth2().authVoiceRecord;
}

enum _RecorderMode {record, play}

class ProfileSoundRecorderDialog extends StatefulWidget {
  final Uint8List? initialRecordBytes;

  // ignore: unused_element
  const ProfileSoundRecorderDialog({super.key, this.initialRecordBytes});

  @override
  _ProfileSoundRecorderDialogState createState() => _ProfileSoundRecorderDialogState();

  // ignore: unused_element
  static Future<AudioResult?> show(BuildContext context, {String? initialRecordPath, Uint8List? initialRecordBytes}) {
    return showDialog<AudioResult?>(
        context: context,
        builder: (_) =>
            Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.all(Radius.circular(5)),
              child: ProfileSoundRecorderDialog(initialRecordBytes: initialRecordBytes),
            )
    );
  }
}

class _ProfileSoundRecorderDialogState extends State<ProfileSoundRecorderDialog> {
  late _ProfileSoundRecorderController _controller;
  bool _loading = false;

  _RecorderMode get _mode => _controller.canPlay ? _RecorderMode.play : _RecorderMode.record;

  @override
  void initState() {
    _controller = _ProfileSoundRecorderController(
      initialAudio: widget.initialRecordBytes,
      notifyChanged: (fn) =>setStateIfMounted(fn)
    );
    _controller.init();
    WidgetsBinding.instance.addPostFrameCallback((_){
        _controller.requestPermission();
    });
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
                                  if(_mode == _RecorderMode.play){
                                    if(_controller.isPlaying){
                                      _onPausePlay();
                                    }else {
                                      _onPlay();
                                    }
                                  }
                              },
                              onLongPressStart: (_){
                                if(_mode == _RecorderMode.record) {
                                  _onStartRecording();
                                }
                              },
                              onLongPressEnd:(_){
                                if(_mode == _RecorderMode.record){
                                  _onStopRecording();
                                }
                              } ,
                              child: Container(
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
                          Styles().images.getImage('close-circle', excludeFromSemantics: true)))),
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
        AudioResult result = await Content().uploadUserNamePronunciation(audioBytes);
        if(result.resultType == AudioResultType.succeeded){
          setStateIfMounted(() => _loading = false);
          _closeModal(result: result);
        } else {
          Log.d(result.errorMessage ?? "");
          AppAlert.showTextMessage(context, Localization().getStringEx("panel.profile_info.pronunciation.upload.failed.msg", "Failed to upload pronunciation audio. Please try again later."));
        }
      } else {
        AppAlert.showTextMessage(context, Localization().getStringEx("panel.profile_info.pronunciation.upload.failed.msg", "Failed to upload pronunciation audio. Please try again later."));
      }
    }catch(e){
      Log.e(e.toString());
    }
  }

  void _onTapClose() {
    Analytics().logAlert(text: "Sound Recording Dialog", selection: "Close");
    _closeModal();
  }

  void _closeModal({ AudioResult? result }) {
    _controller.stopRecord();
    Navigator.of(context).pop(result);
  }

  Widget? get _playButtonIcon {
    if(_mode == _RecorderMode.play){
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
    if(_mode == _RecorderMode.record){
      return _controller.isRecording ?
      Localization().getStringEx("", "Release to stop") :
      Localization().getStringEx("", "Hold to record");
    } else {
      return _controller.isPlaying ? Localization().getStringEx("", "Stop listening to your recording"):Localization().getStringEx("", "Listen to your recording");
    }
  }

  String get _statusText{
    if(_mode == _RecorderMode.record){
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

  bool get _resetEnabled => _mode == _RecorderMode.play;

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

class _ProfileSoundRecorderController {
  final Function(void Function()) notifyChanged;
  final Uint8List? initialAudio;

  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  Duration? _playerTimer;
  String? _audioRecordPath = ""; //The path of the tmp audio Record so we can delete it.
  Uint8List? _audio;//The bytes of the recorded audio
  bool _recording = false;

  _ProfileSoundRecorderController({required this.notifyChanged, this.initialAudio});

  void init() {
    _audioRecorder = AudioRecorder();
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
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }

  void startRecording() async {
    try {
      Log.d("START RECODING");
      if (await _audioRecorder.hasPermission()) {
        notifyChanged(() => _recording = true);
        String? filePath = await _constructFilePath;
        if (filePath != null) {
          await _audioRecorder.start(const RecordConfig(), path: filePath);
        }
        _recording = await _audioRecorder.isRecording();
      }
    } catch (e, stackTrace) {
      Log.d("START RECODING: ${e} - ${stackTrace}");
    }
  }

  Future<void> stopRecording() async {
    Log.d("STOP RECODING");
    try {
      String? path = await _audioRecorder.stop();
      _recording = await _audioRecorder.isRecording();
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

  Future<bool> requestPermission() async => _audioRecorder.hasPermission();

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

  AudioSource? get _audioSource => _haveAudio ? Uint8ListAudioSource(_audio!) : null;

  bool get _haveAudio => CollectionUtils.isNotEmpty(_audio);

  Future<String?> get _constructFilePath async {
    Directory? dir = kIsWeb ? null : await getApplicationDocumentsDirectory();

    return (dir?.existsSync() == true) ? Path.join(dir!.path, "tmp_audio.m4a") : null;
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

class ProfileNamePronouncementConfirmDeleteDialog extends StatelessWidget {

  static Future<bool?> show(BuildContext context) => showDialog<bool?>(context: context, builder: (_) => ProfileNamePronouncementConfirmDeleteDialog());

  @override
  Widget build(BuildContext context) => Material(type: MaterialType.transparency, borderRadius: BorderRadius.all(Radius.circular(8)), child:
    SafeArea(child:
      Container(alignment: Alignment.center, padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24), child:
        Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), decoration: BoxDecoration(color: Styles().colors.background, borderRadius: BorderRadius.all(Radius.circular(5)),), child:
          Column(mainAxisSize: MainAxisSize.min, children: [
            Container(height: 8,),
              Text(Localization().getStringEx("panel.profile_info.pronunciation.delete.confirmation.msg", "Are you sure you want to remove this pronunciation audio?"), textAlign: TextAlign.center, style:
                Styles().textStyles.getTextStyle("widget.detail.regular"),
              ),
            Container(height: 16,),
            Container(padding: EdgeInsets.symmetric(horizontal: 24), child:
              Row(mainAxisSize: MainAxisSize.min, children: [
                SmallRoundedButton( rightIcon: Container(),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  label: Localization().getStringEx("", "Yes"),
                  onTap: () => Navigator.pop(context, true),
                ),
                Container(width: 16,),
                SmallRoundedButton( rightIcon: Container(),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  label: Localization().getStringEx("", "No"),
                  onTap: () => Navigator.pop(context, false),
                ),
              ],),
            ),
          ],)
        )
      )
    )
  );
}

