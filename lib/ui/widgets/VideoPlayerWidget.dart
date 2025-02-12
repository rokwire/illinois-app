import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/ui/widgets/VideoPlayButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:universal_io/io.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String? url;
  final Uri? uri;
  final String? filePath;
  final bool useAuthHeaders;
  final bool showControls;
  final String? videoID;
  final String? videoTitle;
  final bool muted;
  VideoPlayerWidget({super.key, this.url, this.uri, this.filePath,
    this.useAuthHeaders = false, this.showControls = true, this.muted = false,
    this.videoID, this.videoTitle});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  DateTime? _refreshTime;
  Future<void>? _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  @override
  void dispose() {
    _disposeVideoPlayer();
    super.dispose();
  }

  void _initVideoPlayer() {
    if (widget.filePath != null) {
      _controller = VideoPlayerController.file(File(widget.filePath ?? ''));
    } else if (widget.uri != null || widget.url != null) {
      Uri? uri = widget.uri ?? Uri.tryParse(widget.url ?? '');
      if (uri != null) {
        _controller = VideoPlayerController.networkUrl(uri,
            httpHeaders: widget.useAuthHeaders
                ? Auth2().networkAuthHeaders ?? {} : {});
      }
    }
    if (mounted) {
      setState(() {
        _initializeVideoPlayerFuture = _controller?.initialize().then((_) {
          _controller?.setLooping(true);
          _controller?.setVolume(widget.muted ? 0 : 1);
          if (mounted) {
            _playVideo();
          }
        }).onError((e, st) {
          // try refreshing token if last refresh was more than 30 minutes ago
          if (widget.useAuthHeaders) {
            if (_refreshTime == null || DateTime.now().isAfter(_refreshTime!.add(Duration(minutes: 30)))) {
              Auth2().refreshToken(token: Auth2().networkAuthToken).then((token) {
                if (token != null) {
                  _refreshTime = DateTime.now();
                  _initVideoPlayer();
                }
              });
            }
          }
        });
      });
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
    VideoPlayerController? controller = _controller;
    if (controller == null) {
      return _buildErrorWidget();
    }
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          double playerAspectRatio = controller.value.aspectRatio;
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
                  Center(child: AspectRatio(aspectRatio: playerAspectRatio, child: VideoPlayer(controller))),
                  Visibility(visible: widget.showControls && (controller.value.isInitialized && !controller.value.isPlaying), child: VideoPlayButton())
                ])
              )
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      }
    );
  }

  Widget _buildErrorWidget() => Container(
    color: Styles().colors.backgroundVariant,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Styles().images.getImage('exclamation') ?? SizedBox(),
        // SizedBox(height: 8),
        // Text(
        //   Localization().getStringEx('panel.essential_skills_coach.video.error.message', 'Failed to load video. Please try again later.'),
        //   style: Styles().textStyles.getTextStyle("widget.detail.small"),
        //   textAlign: TextAlign.center,
        // ),
      ],
    ),
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

  String? get _videoId => widget.videoID ?? widget.uri?.toString() ?? widget.url ?? widget.filePath;

  void _logAnalyticsVideoEvent({required String event}) {
    Analytics().logVideo(
        videoId: _videoId,
        videoTitle: widget.videoTitle,
        videoEvent: event,
        duration: _controller?.value.duration.inSeconds,
        position: _controller?.value.position.inSeconds);
  }
}