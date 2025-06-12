/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:illinois/model/Video.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/VideoPauseButton.dart';
import 'package:illinois/ui/widgets/VideoPlayButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_navigation.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/swipe_detector.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:video_player/video_player.dart';

class Onboarding2VideoTutorialPanel extends StatefulWidget with Onboarding2Panel {
  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  final Video? video;
  Onboarding2VideoTutorialPanel({ super.key, this.onboardingCode = '', this.onboardingContext, this.video});

  _Onboarding2VideoTutorialPanelState? get _currentState => JsonUtils.cast(globalKey?.currentState);

  @override
  bool get onboardingProgress => (_currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => _currentState?.onboardingProgress = value;

  @override
  State<StatefulWidget> createState() => _Onboarding2VideoTutorialPanelState();
}

class _Onboarding2VideoTutorialPanelState extends State<Onboarding2VideoTutorialPanel> with NotificationsListener {
  Video? _video;
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool _isVideoEnded = false;
  List<DeviceOrientation>? _allowedOrientations;
  String? _currentCaptionText;
  bool _ccEnabled = false;
  bool _ccVisible = false;
  bool _onboardingProgress = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [AppNavigation.notifyEvent]);
    _enableLandscapeOrientations();
    _loadOnboardingVideoTutorial();
    _initVideoPlayer();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _revertToAllowedOrientations();
    _disposeVideoPlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Styles().colors.blackTransparent06, body:
      SafeArea(child:
          Stack(children: [
            Positioned.fill(child:
            SwipeDetector(onSwipeLeft: _onboardingNext, onSwipeRight: _onboardingBack, child:
                Container(color: Styles().colors.blackTransparent06,)
              )
            ),
            Center(child:
              _buildVideoContent(),
            ),
            Onboarding2BackButton(padding: const EdgeInsets.only(left: 17, top: 11, right: 20, bottom: 27), onTap: _onTapBack),
            Positioned.fill(child:
              Align(alignment: (_isPortrait ? Alignment.bottomCenter : Alignment.bottomLeft), child:
                LinkButton(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5), title: _skipButtonLabel(), onTap: _onTapContinue, textColor: Styles().colors.white)
              ),
            ),
            Positioned.fill(child:
              Align(alignment: Alignment.bottomRight, child:
                _buildCcButton()
              ),
            ),
          ])
      )
    );
  }

  Widget _buildVideoContent() {
    if (_controller != null) {
      return FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              double playerAspectRatio = _controller!.value.aspectRatio;
              Orientation deviceOrientataion = MediaQuery.of(context).orientation;
              double deviceWidth = MediaQuery.of(context).size.width;
              double deviceHeight = MediaQuery.of(context).size.height;
              double playerWidth = (deviceOrientataion == Orientation.portrait) ? deviceWidth : (deviceHeight * playerAspectRatio);
              double playerHeight = (deviceOrientataion == Orientation.landscape) ? deviceHeight : (deviceWidth / playerAspectRatio);
              return Semantics(
                focused: true,
                label: "Onboarding Video",
                hint: "Double tap to " + (_isPlaying == true ? "Pause" : "Play"),
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: _onTapPlayPause,
                  child: Center(child: SizedBox(
                      width: playerWidth,
                      height: playerHeight,
                      child: Stack(alignment: Alignment.center, children: [
                        Stack(children: [
                          Center(child: AspectRatio(aspectRatio: playerAspectRatio, child: VideoPlayer(_controller!))),
                          ClosedCaption(
                              text: _currentCaptionText, textStyle: Styles().textStyles.getTextStyle("panel.onboarding2.video_tutorial.caption.text"))
                        ]),
                        Visibility(visible: (_isPlayerInitialized && !_isPlaying), child: VideoPlayButton()),
                        // Visibility(visible: (_isPlayerInitialized && _isPlaying), child: VideoPauseButton())
                      ])))));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          });
    } else {
      return Center(
          child: Text(Localization().getStringEx('panel.onboarding2.video.missing.msg', 'Missing video'),
              style: Styles().textStyles.getTextStyle("panel.onboarding2.video_tutorial.message.empty")));
    }
  }

  Widget _buildCcButton() =>
    Visibility(visible: _ccVisible, child:
      InkWell(onTap: _onTapCc, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: (_ccEnabled ? Styles().colors.white : Styles().colors.disabledTextColorTwo), width: 2),
              borderRadius: BorderRadius.all(Radius.circular(6))
            ),
            child: Text('CC', style: _ccEnabled? Styles().textStyles.getTextStyle("panel.onboarding2.video_tutorial.cc.enabled") : Styles().textStyles.getTextStyle("panel.onboarding2.video_tutorial.cc.disabled"))
          )
        )
      )
    );

  void _initVideoPlayer() {
    if (_video != null) {
      String? tutorialUrl = _video?.videoUrl;
      Uri? tutorialUri = (tutorialUrl != null) ? Uri.tryParse(tutorialUrl) : null;
      if (tutorialUri != null) {
        String? ccUrl = _video!.ccUrl;
        _controller = VideoPlayerController.networkUrl(tutorialUri, closedCaptionFile: _loadClosedCaptions(ccUrl));
        _controller!.addListener(_checkVideoStateChanged);
        _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
          _currentCaptionText = _controller!.value.caption.text;
          _ccEnabled = true;
          _showCc(true);
          if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
            _playVideo();// Automatically play video after initialization
          }
        });
      }
    }
  }

  void _disposeVideoPlayer() {
    _logAnalyticsVideoEvent(event: Analytics.LogAttributeVideoEventStopped);
    _controller?.dispose();
  }

  void _playVideo() {
    _logAnalyticsVideoEvent(event: Analytics.LogAttributeVideoEventStarted);
    _controller!.play();
  }

  void _pauseVideo() {
    _logAnalyticsVideoEvent(event: Analytics.LogAttributeVideoEventPaused);
    _controller!.pause();
  }

  void _loadOnboardingVideoTutorial() {
    _video = widget.video ?? _loadVideoTutorial();
  }

  Future<ClosedCaptionFile> _loadClosedCaptions(String? closedCaptionsUrl) async {
    String? fileContents;
    if (StringUtils.isNotEmpty(closedCaptionsUrl)) {
      Response? response = await Network().get(closedCaptionsUrl);
      int? responseCode = response?.statusCode;
      if (responseCode == 200) {
        fileContents = response?.body;
      }
    }
    return SubRipCaptionFile(StringUtils.ensureNotEmpty(fileContents));
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

  void _onTapPlayPause() {
    if (!_isPlayerInitialized) {
      return;
    }
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
    setState(() {});
  }

  void _showCc(bool ccVisible) {
    setStateIfMounted((){
      _ccVisible = ccVisible;
    });
  }

  void _onTapCc() {
    setStateIfMounted((){
      _ccEnabled = !_ccEnabled;
      _currentCaptionText = _ccEnabled ? _controller?.value.caption.text : null;
    });
  }

  void _checkVideoStateChanged() {
    if (_controller != null) {
      if ((_currentCaptionText != _controller?.value.caption.text) && _ccEnabled) {
        setState(() {
          _currentCaptionText = _controller?.value.caption.text;
        });
      } else {
        if (_isPlayerInitialized) {
          bool videoEnded = (_controller!.value.position == _controller!.value.duration);
          if (_isVideoEnded != videoEnded) {
            setStateIfMounted((){
              _isVideoEnded = videoEnded;
            });
          }
        }
      }
    }
  }

  void _logAnalyticsVideoEvent({required String event}) {
    Analytics().logVideo(
        videoId: _video?.id,
        videoTitle: _video?.title,
        videoEvent: event,
        duration: _controller?.value.duration.inSeconds,
        position: _controller?.value.position.inSeconds);
  }

  bool get _isPlaying {
    return (_controller?.value.isPlaying ?? false);
  }

  bool get _isPlayerInitialized {
    return (_controller?.value.isInitialized ?? false);
  }

  String _skipButtonLabel({String? language}) {
    return _isVideoEnded
        ? Localization().getStringEx('panel.onboarding2.video.button.continue.title', 'Continue', language: language)
        : Localization().getStringEx('panel.onboarding2.video.button.skip.title', 'Skip', language: language);
  }

  bool get _isPortrait => (MediaQuery.of(context).orientation == Orientation.portrait);

  void _onTapBack() {
    Analytics().logSelect(target: "Back");
    _onboardingBack();
  }

  void _onTapContinue() {
    Analytics().logSelect(target: _skipButtonLabel(language: 'en'));
    _onboardingNext();
  }

  // Onboarding

  bool get onboardingProgress => _onboardingProgress;
  set onboardingProgress(bool value) {
    setStateIfMounted(() {
      _onboardingProgress = value;
    });
  }

  void _onboardingBack() => Navigator.of(context).pop();
  void _onboardingNext() => Onboarding2().next(context, widget);

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == AppNavigation.notifyEvent) {
      if (param is Map) {
        AppNavigationEvent? event = param[AppNavigation.notifyParamEvent];
        Route? previousRoute = param[AppNavigation.notifyParamPreviousRoute];
        _handleAppNavigationEvent(event, previousRoute);
      }
    }
  }

  void _handleAppNavigationEvent(AppNavigationEvent? event, Route? previousRoute) {
    if (!mounted || (_controller == null)) {
      // Do not do anything if the state is not in the tree or the video controller is null
      return;
    }
    if (event == AppNavigationEvent.push) {
      // Pause video when the panel is not on top
      if (_controller!.value.isPlaying) {
        _pauseVideo();
      }
      // Revert allowed orientations if the panel is not on top
      if (previousRoute != null) {
        bool isCurrent = (AppNavigation.routeRootWidget(previousRoute, context: context)?.runtimeType == widget.runtimeType);
        if (isCurrent) {
          _revertToAllowedOrientations();
        }
      }
    } else if (event == AppNavigationEvent.pop) {
      if (previousRoute != null) {
        bool isCurrent = (AppNavigation.routeRootWidget(previousRoute, context: context)?.runtimeType == widget.runtimeType);
        if (isCurrent) {
          // Enable landscape orientations when the panel is visible
          _enableLandscapeOrientations();
          // Play again video when the panel is visible if it has not already ended
          if (!_controller!.value.isPlaying && !_isVideoEnded) {
            _playVideo();
          }
        }
      }
    }
  }

  static Video? _loadVideoTutorial(){
    Map<String, dynamic>? videoTutorials = Content().videoTutorials;
    List<dynamic>? videos = JsonUtils.listValue(videoTutorials?['videos']) ;
    if (CollectionUtils.isEmpty(videos)) {
      return null;
    }
    Map<String, dynamic>? strings = JsonUtils.mapValue(videoTutorials?['strings']);
    Map<String, dynamic>? onboardingMap = videoTutorials?['onboarding'];
    String? onboardingVideoId;
    String? envKey = configEnvToString(Config().configEnvironment);
    if (StringUtils.isNotEmpty(envKey)) {
      onboardingVideoId = onboardingMap?[envKey];
    }
    Map<String, dynamic>? videoMap;
    if (StringUtils.isNotEmpty(onboardingVideoId)) {
      for(dynamic video in videos!) {
        if (onboardingVideoId == video['id']) {
          videoMap = video;
          break;
        }
      }
    }
    if (videoMap == null) {
      videoMap = videos!.first;
    }
    videoMap!['title'] = Localization().getContentString(strings, videoMap['id']);
    return Video.fromJson(videoMap);
  }
}

class VideoTutorialThumbButton extends StatefulWidget{
  final VoidCallback? onTap;

  const VideoTutorialThumbButton({super.key, this.onTap});
  @override
  State<StatefulWidget> createState() =>_VideoTutorialThumbState();

}

class _VideoTutorialThumbState extends State<VideoTutorialThumbButton>{
  Video? _video;

  @override
  void initState() {
  _video = _Onboarding2VideoTutorialPanelState._loadVideoTutorial();
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
    Semantics(label: "Onboarding video tutorial",
      hint: "Double tap to Play video",
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onTap,
          // () {
          // Onboarding2().privacyReturningUser = false;
          // Navigator.push(context, CupertinoPageRoute(builder: (context) =>
          //     Onboarding2VideoTutorialPanel(onboardingCode: widget.onboardingCode, onboardingContext: widget.onboardingContext, video: _video,)));
          // },
        child: Container(
            child: Visibility(visible:_video?.thumbUrl != null,
              child: Stack(alignment: Alignment.center, children: [
                _video?.thumbUrl != null ? Image.network(_video?.thumbUrl ?? "") : Container(),
                VideoPlayButton()
              ])
            )
          )
        )
    );

}