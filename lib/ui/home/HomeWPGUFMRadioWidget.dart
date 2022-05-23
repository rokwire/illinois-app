import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

//TBD LOCALIZE
class HomeWPGUFMRadioWidget extends StatefulWidget {
  final StreamController<void>? refreshController;

  const HomeWPGUFMRadioWidget({Key? key, this.refreshController}) : super(key: key);

  @override
  State<HomeWPGUFMRadioWidget> createState() => _HomeWPGUFMRadioWidgetState();
}

class _HomeWPGUFMRadioWidgetState extends State<HomeWPGUFMRadioWidget> implements NotificationsListener {
  AudioPlayer? _player;
  bool _initalizingPlayer = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Config.notifyConfigChanged,
    ]);

    _initAudioSession().then((_) {
      if (_isEnabled) {
        _initPlayer();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEnabled) {
      String? buttonTitle, iconAsset;
      if (_player != null) {
        buttonTitle = _isPlaying ? Localization().getStringEx('widget.home.radio.button.pause.title', 'Pause') :  Localization().getStringEx('widget.home.radio.button.play.title', 'Play');
        iconAsset = _isPlaying ? 'images/button-pause-orange.png' : 'images/button-play-orange.png';
      }
      else if (_initalizingPlayer) {
        buttonTitle = Localization().getStringEx('widget.home.radio.button.initalize.title', 'Initializing');
      }
      else {
        buttonTitle = Localization().getStringEx('widget.home.radio.button.fail.title', 'Not Available');
      }

      return GestureDetector(onTap: _onTapPlayPause, child:
      Container(
        margin: EdgeInsets.only(left: 16, right: 16, bottom: 20),
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3),
              spreadRadius: 2.0,
              blurRadius: 8.0,
              offset: Offset(0, 2))
        ]),
        child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
        Row(children: <Widget>[
          Expanded(child:
          Column(children: <Widget>[
            Container(color: Styles().colors!.fillColorPrimary, child:
            Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(Localization().getStringEx(
                  'widget.home.radio.title', 'WPGUFM Radio'),
                  style: TextStyle(color: Styles().colors!.white,
                      fontFamily: Styles().fontFamilies!.extraBold,
                      fontSize: 20))),
            ])
            ),
            ),
            Container(color: Styles().colors!.white, child:
            Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
            Row(children: <Widget>[
              Expanded(child:
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 8, right: 8, bottom: 8), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        Padding(padding: EdgeInsets.all(16), child:
                          Container(decoration: BoxDecoration(border: Border(left: BorderSide(color: Styles().colors!.fillColorSecondary! , width: 3))), child:
                            Padding(padding: EdgeInsets.only(left: 10), child:
                            Row(children: [Expanded(child: Text(buttonTitle, style: TextStyle(fontFamily: Styles().fontFamilies?.extraBold, fontSize: 24, color: Styles().colors?.fillColorPrimary)))]))))),
                    ],),
                  ),
                ),
              ),
              (iconAsset != null) ? Semantics(button: true,
                  excludeSemantics: true,
                  label: buttonTitle,
                  hint: Localization().getStringEx(
                      'widget.home.radio.button.add_radio.hint', ''),
                  child: 
                  IconButton(color: Styles().colors!.fillColorPrimary,
                    icon: Image.asset(iconAsset, excludeFromSemantics: true),
                    onPressed: _onTapPlayPause)
              ) : Container(),
            ]),
            ),
            ),
          ]),
          ),
        ]),
        ),
      ),
      );
    }
    else {
      return Container();
    }
  }

  bool get _isEnabled => StringUtils.isNotEmpty(Config().wpgufmRadioUrl);
  bool get _isPlaying => (_player?.playing == true);

  void _onTapPlayPause() {
    Analytics().logSelect(target: 'Play/Pause');
    if (_player != null) {
      if (_isPlaying) {
        _player?.pause();
      }
      else {
        _player?.play();
      }
    }
  }

  Future<void> _initAudioSession() async {
    AudioSession session = await AudioSession.instance;
    session.configure(const AudioSessionConfiguration.speech());
  }

  void _initPlayer() async {
    if (mounted) {
      setState(() {
        _initalizingPlayer = true;
      });
    }

    _createPlayer().then((AudioPlayer? player) {
      if (mounted) {
        setState(() {
          _player = player;
          _initalizingPlayer = false;
        });
      }
    });
  }

  Future<AudioPlayer?> _createPlayer() async {
    AudioPlayer player = AudioPlayer();

    try {
      await player.setAudioSource(AudioSource.uri(Uri.parse(Config().wpgufmRadioUrl!)));

      player.playbackEventStream.listen((PlaybackEvent event) {
        print('PlaybackEvent: ${event.processingState.toString()}');
        _onPlaybackEvent(event);
      },
      onError: (Object e, StackTrace stackTrace) {
        print('A stream error occurred: $e');
      });

      player.playerStateStream.listen((PlayerState state) {
        print('PlayerState: ${state.playing}');
        _onPlayerState(state);
      });

      return player;
    } catch (e) {
      print("Error loading audio source: $e");
    }

    player.dispose();
    return null;
  }

  void _onPlaybackEvent(PlaybackEvent event) {
  }


  void _onPlayerState(PlayerState state) {
    if (mounted) {
      setState(() {
      });
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == Config.notifyConfigChanged) {
      _onConfigChnaged();
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
    }
    else if (state == AppLifecycleState.resumed) {
    }
  }
  void _onConfigChnaged() {
    if (_isEnabled && (_player == null)) {
      _initPlayer();
    }
    else if (!_isEnabled && (_player != null)) {
      _player?.dispose();
      _player = null;
      if (mounted) {
        setState(() {
        });
      }
    }
  }
} 