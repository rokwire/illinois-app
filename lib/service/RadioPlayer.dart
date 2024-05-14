
import 'package:illinois/service/Config.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum RadioStation { will, willfm, willhd, wpgufm, }

class RadioPlayer with Service implements NotificationsListener {

  static const String notifyInitializeStatusChanged  = "edu.illinois.rokwire.wpgufmradio.initialize.status.changed";
  static const String notifyPlayerStateChanged       = "edu.illinois.rokwire.wpgufmradio.player.state.changed";

  static String? radioStationUrl(RadioStation radioStation) {
    switch (radioStation) {
      case RadioStation.will: return Config().willRadioUrl;
      case RadioStation.willfm: return Config().willFmRadioUrl;
      case RadioStation.willhd: return Config().willHdRadioUrl;
      case RadioStation.wpgufm: return Config().wpgufmRadioUrl;
    }
  }

  AudioSession? _audioSession;
  Map<RadioStation, AudioPlayer> _audioPlayers = <RadioStation, AudioPlayer>{};
  Map<RadioStation, PlayerState> _playerStates = <RadioStation, PlayerState>{};
  bool _initalizing = false;

  // Singleton Factory

  static final RadioPlayer _service = RadioPlayer._internal();
  RadioPlayer._internal();
  factory RadioPlayer() => _service;
  RadioPlayer get instance => _service;

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

  bool get isInitializing => _initalizing;

  bool get isPlaying {
    for (AudioPlayer audioPlayer in _audioPlayers.values) {
      if (audioPlayer.playing == true) {
        return true;
      }
    }
    return false;
  }

  void pause() {
    _audioPlayers.forEach((station, player) {
      if (player.playing) {
        player.pause();
      }
    });
  }

  bool isStationEnabled(RadioStation radioStation) => StringUtils.isNotEmpty(radioStationUrl(radioStation));
  bool isStationInitialized(RadioStation radioStation) => (_audioSession != null) && (_audioPlayers[radioStation] != null);
  bool isStationPlaying(RadioStation radioStation) => (_audioPlayers[radioStation]?.playing == true);

  PlayerState? stationPlayerState(RadioStation radioStation) => _playerStates[radioStation];

  void playStation(RadioStation radioStation) {
    AudioPlayer? audioPlayer = _audioPlayers[radioStation];
    if (audioPlayer != null) {
      _audioPlayers.forEach((station, player) {
        if ((station != radioStation) && player.playing) {
          player.pause();
        }
      });
      audioPlayer.play();
    }
  }

  void pauseStation(RadioStation radioStation) {
    AudioPlayer? audioPlayer = _audioPlayers[radioStation];
    if (audioPlayer != null) {
      audioPlayer.pause();

    }
  }

  void toggleStationPlayPause(RadioStation radioStation) {
    AudioPlayer? audioPlayer = _audioPlayers[radioStation];
    if (audioPlayer != null) {
      if (audioPlayer.playing == false) {
        _audioPlayers.forEach((station, player) {
          if ((station != radioStation) && player.playing) {
            player.pause();
          }
        });
        audioPlayer.play();
      }
      else if (audioPlayer.playing == true) {
        audioPlayer.pause();
      }
    }
  }

  // Accessories

  Future<void> _init() async {
    _initalizing = true;
    _audioSession = await _initAudioSession();
    _audioPlayers = await _initAudioPlayers();
    _initalizing = false;
    NotificationService().notify(notifyInitializeStatusChanged);
  }

  void _destroy() {
    _audioPlayers.forEach((station, player) => player.dispose());
    _audioPlayers.clear();
  }

  Future<AudioSession> _initAudioSession() async {
    AudioSession session = await AudioSession.instance;
    session.configure(const AudioSessionConfiguration.speech());
    return session;
  }

  Future<Map<RadioStation, AudioPlayer>> _initAudioPlayers() async {
    Map<RadioStation, AudioPlayer> result = <RadioStation, AudioPlayer>{};

    List<Future<AudioPlayer?>> futures = <Future<AudioPlayer?>>[];
    for (RadioStation radioStation in RadioStation.values) {
      futures.add(_initAudioPlayer(radioStation));
    }

    List<AudioPlayer?> players = await Future.wait(futures);

    int playerIndex = 0;
    for (RadioStation radioStation in RadioStation.values) {
      AudioPlayer? radioStationPlayer = players[playerIndex++];
      if (radioStationPlayer != null) {
        result[radioStation] = radioStationPlayer;
      }
    }
    return result;
  }

  Future<AudioPlayer?> _initAudioPlayer(RadioStation radioStation) async {
    String? radioUrl = radioStationUrl(radioStation);
    if (radioUrl != null) {
      AudioPlayer player = AudioPlayer();

      try {
        player.playerStateStream.listen((PlayerState state) {
          _onPlayerState(radioStation, state);
        });

        await player.setAudioSource(AudioSource.uri(Uri.parse(radioUrl)));

        return player;
      } catch (e) {
        print("Error loading audio source: $e");
        player.dispose();
      }
    }
    return null;
  }

  void _onPlayerState(RadioStation radioStation, PlayerState state) {
    _playerStates[radioStation] = state;
    NotificationService().notify(notifyPlayerStateChanged, radioStation);
  }

  void _onConfigChnaged() {
    for (RadioStation radioStation in RadioStation.values) {
      if (isStationEnabled(radioStation) && !isStationInitialized(radioStation)) {
        _initAudioPlayer(radioStation).then((AudioPlayer? stationPlayer) {
          if (stationPlayer != null) {
            _audioPlayers[radioStation] = stationPlayer;
            NotificationService().notify(notifyInitializeStatusChanged, radioStation);
          }
        });
      }
      else if (!isStationEnabled(radioStation) && isStationInitialized(radioStation)) {
        _audioPlayers[radioStation]?.dispose();
        _audioPlayers.remove(radioStation);
        _playerStates.remove(radioStation);
        NotificationService().notify(notifyInitializeStatusChanged, radioStation);
     }
    }
  }
}