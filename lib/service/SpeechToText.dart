import 'dart:io';

import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToText {
  static const String notifyStatus     = "edu.illinois.rokwire.speech_to_text.status";
  static const String notifyError     = "edu.illinois.rokwire.speech_to_text.error";

  // Singleton Factory

  static final SpeechToText _instance = SpeechToText._internal();
  factory SpeechToText() => _instance;
  SpeechToText._internal();

  stt.SpeechToText? _speechToText;

  bool get isEnabled => ((_speechToText == null) || (_speechToText?.isAvailable == true));
  bool get isListening => (_speechToText?.isListening == true);

  Future<bool?> listen({required Function(String, bool) onResult}) async {
    //debugPrint("SpeechToText Start");
    if (_speechToText == null) {
      _speechToText = stt.SpeechToText();
      await _speechToText?.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
    }

    await _speechToText?.listen(
      onResult: (result) => _onSpeechResult(result, onResult),
      listenOptions: stt.SpeechListenOptions(cancelOnError: true),
    );

    return _speechToText?.isListening;
  }

  Future<void> stopListening() async {
    //debugPrint("SpeechToText Stop");
    await _speechToText?.stop();
    if (Platform.isIOS) {
      _speechToText = null; // [#4364] Assistant does not turn microphone off
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result, Function(String, bool) onResult) {
    //debugPrint("SpeechToText Result: ${result.recognizedWords}");
    onResult(result.recognizedWords, result.finalResult);
  }

  void _onStatus(String status) {
    //debugPrint("SpeechToText Status: $status");
    NotificationService().notify(notifyStatus);
  }

  void _onError(SpeechRecognitionError error) {
    //debugPrint("SpeechToText Error: $error");
    NotificationService().notify(notifyError);
  }
}