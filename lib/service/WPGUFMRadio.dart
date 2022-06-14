
import 'package:illinois/service/Config.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WPGUFMRadio with Service implements NotificationsListener {

  static const String notifyInitializeStatusChanged  = "edu.illinois.rokwire.wpgufmradio.initialize.status.changed";
  static const String notifyPlaybackEvent            = "edu.illinois.rokwire.wpgufmradio.playback.event";
  static const String notifyPlaybackError            = "edu.illinois.rokwire.wpgufmradio.playback.error";
  static const String notifyPlayerStateChanged       = "edu.illinois.rokwire.wpgufmradio.player.state.changed";

  AudioPlayer? _audioPlayer;
  bool _initalizing = false;
  bool _audioSessionInitialized = false;
  
  PlaybackEvent? _playbackEvent;
  Object? _playbackError;
  PlayerState? _playerState;

  // Singleton Factory

  static final WPGUFMRadio _service = WPGUFMRadio._internal();
  WPGUFMRadio._internal();
  factory WPGUFMRadio() => _service;
  WPGUFMRadio get instance => _service;

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, Config.notifyConfigChanged);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    _destroy();
  }

  @override
  Future<void> initService() async {
    await super.initService();
    _init(); // initialize asynchronously
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Config.notifyConfigChanged) {
      _onConfigChnaged();
    }
  }

  // Implementation

  bool get isEnabled => StringUtils.isNotEmpty(Config().wpgufmRadioUrl);
  bool get isInitialized => (_audioPlayer != null);
  bool get isInitializing => _initalizing;
  bool get isPlaying => (_audioPlayer?.playing == true);

  PlaybackEvent? get playbackEvent => _playbackEvent;
  Object? get playbackError => _playbackError;
  PlayerState? get playerState => _playerState;

  void play() => _audioPlayer?.play();
  void pause() => _audioPlayer?.pause();

  void togglePlayPause() {
    if (_audioPlayer?.playing == false) {
      _audioPlayer?.play();
    }
    else if (_audioPlayer?.playing == true) {
      _audioPlayer?.pause();
    }
  }

  // Accessories

  Future<void> _init() async {
    if (isEnabled) {
      _initalizing = true;
      await _initAudioSession();
      await _initAudioPlayer();
      _initalizing = false;
      NotificationService().notify(notifyInitializeStatusChanged);
    }
  }

  void _destroy() {
    if (_audioPlayer != null) {
      _audioPlayer?.dispose();
      _audioPlayer = null;
    }
  }

  Future<void> _initAudioSession() async {
    if (!_audioSessionInitialized && isEnabled) {
      AudioSession session = await AudioSession.instance;
      session.configure(const AudioSessionConfiguration.speech());
      _audioSessionInitialized = true;
    }
  }

  Future<void> _initAudioPlayer() async {
    if ((_audioPlayer == null) && isEnabled) {
      AudioPlayer player = AudioPlayer();

      try {
        player.playbackEventStream.listen((PlaybackEvent event) {
          print('PlaybackEvent: ${event.processingState.toString()}');
          _onPlaybackEvent(event);
        },
        onError: (Object e, StackTrace stackTrace) {
          print('A stream error occurred: $e');
          _onPlaybackError(e);
        });

        player.playerStateStream.listen((PlayerState state) {
          print('PlayerState: ${state.playing}');
          _onPlayerState(state);
        });

        await player.setAudioSource(AudioSource.uri(Uri.parse(Config().wpgufmRadioUrl!)));

        _audioPlayer = player;
      } catch (e) {
        print("Error loading audio source: $e");
        player.dispose();
      }
    }
  }

  void _onPlaybackEvent(PlaybackEvent event) {
    NotificationService().notify(notifyPlaybackEvent, _playbackEvent = event);
  }


  void _onPlaybackError(Object error) {
    NotificationService().notify(notifyPlaybackError, _playbackError = error);
  }

  void _onPlayerState(PlayerState state) {
    NotificationService().notify(notifyPlayerStateChanged, _playerState = playerState);
  }

  void _onConfigChnaged() {
    if (isEnabled && !isInitialized) {
      _init();
    }
    else if (!isEnabled && isInitialized) {
      destroyService();
      NotificationService().notify(notifyInitializeStatusChanged);
   }
  }

}