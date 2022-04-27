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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:video_player/video_player.dart';

class SettingsVideoTutorialPanel extends StatefulWidget {
  @override
  State<SettingsVideoTutorialPanel> createState() => _SettingsVideoTutorialPanelState();
}

class _SettingsVideoTutorialPanelState extends State<SettingsVideoTutorialPanel> {
  VideoPlayerController? _controller;
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
    String? tutorialUrl = Config().videoTutorialUrl;
    if (StringUtils.isNotEmpty(tutorialUrl)) {
      _controller = VideoPlayerController.network(tutorialUrl!);
      _controller!.addListener(_checkVideoEnded);
      _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
        setState(() {});
      });
    }
  }

  void _disposeVideoPlayer() {
    _controller?.dispose();
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
      _controller?.pause();
    } else {
      _controller?.play();
    }
    setState(() {});
  }

  void _checkVideoEnded() {
    if (_controller != null) {
      bool videoEnded = (_controller!.value.position == _controller!.value.duration);
      if (videoEnded && mounted) {
        setState(() {});
      }
    }
  }

  bool get _isPlaying {
    return (_controller?.value.isPlaying ?? false);
  }

  bool get _isPlayerInitialized {
    return (_controller?.value.isInitialized ?? false);
  }

  String get _playButtonLabel {
    return _isPlaying
        ? Localization().getStringEx('panel.settings.video_tutorial.button.pause.title', 'Pause')
        : Localization().getStringEx('panel.settings.video_tutorial.button.play.title', 'Play');
  }

  @override
  Widget build(BuildContext context) {
    double playButtonWidth = MediaQuery.of(context).textScaleFactor * 120;
    return Scaffold(
        backgroundColor: Styles().colors!.blackTransparent06,
        appBar: HeaderBar(title: Localization().getStringEx("panel.settings.video_tutorial.header.title", "Video Tutorial")),
        body: Center(
            child: Stack(children: [
          _buildVideoContent(),
          Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: SizedBox(
                      width: playButtonWidth,
                      child: RoundedButton(
                          enabled: _isPlayerInitialized,
                          label: _playButtonLabel,
                          fontSize: 16,
                          textColor: (_isPlayerInitialized ? Styles().colors!.fillColorPrimary : Styles().colors!.disabledTextColor),
                          borderColor: (_isPlayerInitialized ? Styles().colors!.fillColorSecondary : Styles().colors!.mediumGray),
                          onTap: _onTapPlayPause))))
        ])));
  }

  Widget _buildVideoContent() {
    if (_controller != null) {
      return FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Center(child: AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!)));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          });
    } else {
      return Center(
          child: Text(Localization().getStringEx('panel.settings.video_tutorial.video.missing.msg', 'Missing video'),
              style: TextStyle(color: Styles().colors!.white, fontSize: 20, fontFamily: Styles().fontFamilies!.bold)));
    }
  }
}
