import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

class Uint8ListAudioSource extends StreamAudioSource {
  final Uint8List _data;

  Uint8ListAudioSource(this._data);

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
