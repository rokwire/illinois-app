import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:illinois/utils/AudioUtils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String? url;
  final Uint8List? bytes;
  AudioPlayerWidget({super.key, this.url, this.bytes});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _handlePlaybackError({bool showAlert = false}) {
    _pausePlayer();
    setState(() {
      _audioPlayer?.dispose();
      _audioPlayer = null;
    });
    if (showAlert) {
      AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.info.playback.failed.text', 'Failed to play audio stream.'));
    }
  }

  void _initAudioPlayer() async {
    if (widget.bytes != null || widget.url != null) {
      _audioPlayer = AudioPlayer();

      try {
        Uri? uri = widget.url != null ? Uri.tryParse(widget.url ?? '') : null;
        Uint8List? bytes = widget.bytes;
        if (uri != null) {
          await _audioPlayer?.setAudioSource(AudioSource.uri(uri), preload: false);
        }
        else if (bytes != null) {
          await _audioPlayer?.setAudioSource(Uint8ListAudioSource(bytes));
        }
        _audioPlayer?.playerStateStream.listen((state) {
          if ((state.processingState == ProcessingState.completed) && mounted) {
            setStateIfMounted(() {
              _audioPlayer?.pause();
              _audioPlayer?.seek(Duration(seconds: 0));
            });
          }
        });
      }
      catch(e) {
        _handlePlaybackError();
      }
    }
    else {
      _handlePlaybackError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      GestureDetector(onTap: _onTogglePlay, child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Styles().colors.surface),
        child: Center(child: _playIcon ?? SizedBox()),
      )),
      SizedBox(width: 8.0),
      Expanded(
        child: StreamBuilder(
          stream: _audioPlayer?.positionStream,
          builder: (context, snapshot) {
            final data = snapshot.data;
            int position = 0;
            if (data is Duration) {
              position = data.inMilliseconds;
            }
            return  LinearProgressIndicator(
              value: position / (_audioPlayer?.duration?.inMilliseconds ?? 1),
            );
          },
        ),
      ),
      SizedBox(width: 8.0),
    ]);
  }


  Widget? get _playIcon => (_audioPlayer?.playing == true) ? Styles().images.getImage('pause') : Styles().images.getImage('play');

  void _onTogglePlay() {
    if (_audioPlayer?.playing == true) {
      _pausePlayer();
      return;
    }
    if (mounted) {
      Duration? duration = _audioPlayer?.duration;
      if (widget.url != null || (duration != null && duration.inMilliseconds > 0)) {
        setState(() {
          _audioPlayer?.play();
        });
      }
      else {
        _handlePlaybackError(showAlert: true);
      }
    }
  }

  void _pausePlayer() {
    setState(() {
      _audioPlayer?.pause();
    });
  }
}