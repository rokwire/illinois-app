import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Uint8ListAudioSource extends StreamAudioSource {
  final Uint8List _data;
  final String? contentType;

  Uint8ListAudioSource(this._data, {this.contentType});

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // Returning the stream audio response with the parameters
    return StreamAudioResponse(
      sourceLength: _data.length,
      contentLength: (end ?? _data.length) - (start ?? 0),
      offset: start ?? 0,
      stream: Stream.fromIterable([_data.sublist(start ?? 0, end)]),
      contentType: contentType ?? (_isWav(_data) ? 'audio/wav' : 'audio/mp4'),
    );
  }

  bool _isWav(List<int> bytes) {
    return bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WAVE';
  }
}

class ResourceAudioSound {
  final String resourcePath;
  AudioPlayer? _audioPlayer;

  ResourceAudioSound(this.resourcePath);

  Future<bool> play() async {
    if (_audioPlayer == null) {
      ByteData? resourceData = await AppBundle.loadBytes(resourcePath);
      if (resourceData != null) {
        _audioPlayer = AudioPlayer();
        _audioPlayer?.playerStateStream.listen((PlayerState playerState) {
          //debugPrint("AudioPlayer state changed: ${playerState.processingState}");
          if (playerState.processingState == ProcessingState.completed) {
            _audioPlayer = null;
          }
        },
        onError: (error) {
          //debugPrint("AudioPlayer error: $error");
          _audioPlayer = null;
        },
        onDone: () {
          //debugPrint("AudioPlayer done.");
          _audioPlayer = null;
        });
        await _audioPlayer?.setAudioSource(Uint8ListAudioSource(Uint8List.sublistView(resourceData)));
        await _audioPlayer?.play();
        return true;
      }
    }
    return false;
  }
}
