import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToText with Service {
  static const String notifyStatus     = "edu.illinois.rokwire.speech_to_text.status";
  static const String notifyError     = "edu.illinois.rokwire.speech_to_text.error";

  // Singleton Factory

  static final SpeechToText _instance = SpeechToText._internal();
  factory SpeechToText() => _instance;
  SpeechToText._internal();

  stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _initialized = false;

  bool get isEnabled => !_initialized || _speechToText.isAvailable;
  bool get isListening => _speechToText.isListening;

  @override
  Future<void> initService() async {
    await super.initService();
  }

  void listen({required Function(String, bool) onResult}) async {
    if (!_initialized) {
      await _speechToText.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
      _initialized = true;
    }

    _speechToText.listen(
      onResult: (result) => _onSpeechResult(result, onResult),
      cancelOnError: true
    );
  }

  Future<void> stopListening() async {
    return _speechToText.stop();
  }

  void _onSpeechResult(SpeechRecognitionResult result, Function(String, bool) onResult) {
    onResult(result.recognizedWords, result.finalResult);
  }

  void _onStatus(String status) {
    NotificationService().notify(notifyStatus);
  }

  void _onError(SpeechRecognitionError error) {
    NotificationService().notify(notifyError);
  }
}