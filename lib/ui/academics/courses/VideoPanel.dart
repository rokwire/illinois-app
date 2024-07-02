import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/widgets/VideoPlayButton.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:video_player/video_player.dart';

class VideoPanel extends StatefulWidget {
  final String? resourceKey;
  final String? resourceName;
  VideoPanel({Key? key, this.resourceName, this.resourceKey}) : super(key: key);

  @override
  State<VideoPanel> createState() => _VideoPanelState();
}

class _VideoPanelState extends State<VideoPanel> {
  VideoPlayerController? _controller;
  DateTime? _refreshTime;
  Future<void>? _initializeVideoPlayerFuture;
  List<DeviceOrientation>? _allowedOrientations;

  @override
  void initState() {
    super.initState();
    _enableLandscapeOrientations();
    _initVideoPlayer();
  }

  @override
  void dispose() {
    _revertToAllowedOrientations();
    _disposeVideoPlayer();
    super.dispose();
  }

  void _initVideoPlayer() {
    if (StringUtils.isNotEmpty(widget.resourceKey)) {
      //first try to parse the resource key as a uri; if it doesn't have a host then try to use it as a file name and use content BB as the host
      Uri? videoUri = Uri.tryParse(widget.resourceKey!);
      if (StringUtils.isEmpty(videoUri?.host) && StringUtils.isNotEmpty(Config().essentialSkillsCoachKey) && StringUtils.isNotEmpty(Config().contentUrl)) {
        Map<String, String> queryParams = {
          'fileName': widget.resourceKey!,
          'category': Config().essentialSkillsCoachKey!,
        };
        String url = "${Config().contentUrl}/files";
        if (queryParams.isNotEmpty) {
          url = UrlUtils.addQueryParameters(url, queryParams);
        }
        videoUri = Uri.tryParse(url);
      }

      if (videoUri != null) {
        _controller = VideoPlayerController.networkUrl(videoUri, httpHeaders: Auth2().networkAuthHeaders ?? {});
        if (mounted) {
          setState(() {
            _initializeVideoPlayerFuture = _controller?.initialize().then((_) {
              _controller?.setLooping(true);
              if (mounted) {
                _playVideo();
              }
            }).onError((e, st) {
              // try refreshing token if last refresh was more than 30 minutes ago
              if (_refreshTime == null || DateTime.now().isAfter(_refreshTime!.add(Duration(minutes: 30)))) {
                Auth2().refreshToken(Auth2().networkAuthToken).then((token) {
                  if (token != null) {
                    _refreshTime = DateTime.now();
                    _initVideoPlayer();
                  }
                });
              }
            });
          });
        }
      }
    }
  }

  void _disposeVideoPlayer() {
    _logAnalyticsVideoEvent(event: Analytics.LogAttributeVideoEventStopped);
    _controller?.dispose();
  }

  void _playVideo() {
    _logAnalyticsVideoEvent(event: Analytics.LogAttributeVideoEventStarted);
    _controller?.play();
  }

  void _pauseVideo() {
    _logAnalyticsVideoEvent(event: Analytics.LogAttributeVideoEventPaused);
    _controller?.pause();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.background,
      appBar: HeaderBar(title: widget.resourceName ?? Localization().getStringEx('panel.essential_skills_coach.video.header.title', 'Video'),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: Center(child: _controller != null ? _buildVideoContent() : _buildErrorWidget()),
    );
  }

  Widget _buildVideoContent() {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          double playerAspectRatio = _controller!.value.aspectRatio;
          Orientation deviceOrientation = MediaQuery.of(context).orientation;
          double deviceWidth = MediaQuery.of(context).size.width;
          double deviceHeight = MediaQuery.of(context).size.height;
          double playerWidth = (deviceOrientation == Orientation.portrait) ? deviceWidth : (deviceHeight * playerAspectRatio);
          double playerHeight = (deviceOrientation == Orientation.landscape) ? deviceHeight : (deviceWidth / playerAspectRatio);
          return GestureDetector(
            onTap: _onTapPlayPause,
            child: Center(
              child: SizedBox(
                width: playerWidth,
                height: playerHeight,
                child: Stack(alignment: Alignment.center, children: [
                  Center(child: AspectRatio(aspectRatio: playerAspectRatio, child: VideoPlayer(_controller!))),
                  Visibility(visible: (_controller!.value.isInitialized && !_controller!.value.isPlaying), child: VideoPlayButton())
                ])
              )
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      }
    );
  }

  Widget _buildErrorWidget() => Text(
    Localization().getStringEx('panel.essential_skills_coach.video.error.message', 'Failed to load video. Please try again later.'),
    style: Styles().textStyles.getTextStyle("widget.detail.regular"),
  );

  void _onTapPlayPause() {
    if (!_controller!.value.isInitialized) {
      return;
    }
    if (_controller!.value.isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
    setState(() {});
  }

  void _enableLandscapeOrientations() {
    NativeCommunicator().enabledOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight, DeviceOrientation.portraitUp]).then((orientationList) {
      _allowedOrientations = orientationList;
    });
  }

  void _revertToAllowedOrientations() {
    if (_allowedOrientations != null) {
      NativeCommunicator().enabledOrientations(_allowedOrientations!).then((orientationList) {
        _allowedOrientations = null;
      });
    }
  }

  void _logAnalyticsVideoEvent({required String event}) {
    Analytics().logVideo(
        videoId: widget.resourceKey,
        videoTitle: widget.resourceName,
        videoEvent: event,
        duration: _controller!.value.duration.inSeconds,
        position: _controller!.value.position.inSeconds);
  }
}