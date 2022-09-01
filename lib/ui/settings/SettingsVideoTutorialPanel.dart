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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:video_player/video_player.dart';

class SettingsVideoTutorialPanel extends StatefulWidget {
  final Map<String, dynamic> videoTutorial;

  SettingsVideoTutorialPanel({required this.videoTutorial});

  @override
  State<SettingsVideoTutorialPanel> createState() => _SettingsVideoTutorialPanelState();
}

class _SettingsVideoTutorialPanelState extends State<SettingsVideoTutorialPanel> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  List<DeviceOrientation>? _allowedOrientations;
  String? _currentCaptionText;
  bool _ccEnabled = false;
  bool _ccVisible = false;

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
    String? tutorialUrl = widget.videoTutorial['video_url'];
    if (StringUtils.isNotEmpty(tutorialUrl)) {
      _controller = VideoPlayerController.network(tutorialUrl!, closedCaptionFile: _loadClosedCaptions());
      _controller!.addListener(_checkVideoStateChanged);
      _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
        _currentCaptionText = _controller!.value.caption.text;
        _ccEnabled = true;
        _showCc(true);
        _startCcHidingTimer();
        if (mounted) {
          _controller!.play(); // Automatically play video after initialization
        }
      });
    }
  }

  void _disposeVideoPlayer() {
    _controller?.dispose();
  }

  Future<ClosedCaptionFile> _loadClosedCaptions() async {
    String? fileContents;
    String? closedCaptionsUrl = widget.videoTutorial['cc_url'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Styles().colors!.blackTransparent06,
        appBar: HeaderBar(
            title: StringUtils.ensureNotEmpty(widget.videoTutorial['title'],
                defaultValue: Localization().getStringEx("panel.settings.video_tutorial.header.title", "Video Tutorial"))),
        body: Center(child: _buildVideoContent()));
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
              return GestureDetector(
                  onTap: _onTapPlayPause,
                  child: Stack(children: [
                    Center(
                        child: SizedBox(
                            width: playerWidth,
                            height: playerHeight,
                            child: Stack(alignment: Alignment.center, children: [
                              Stack(children: [
                                Center(child: AspectRatio(aspectRatio: playerAspectRatio, child: VideoPlayer(_controller!))),
                                Visibility(
                                    visible: StringUtils.isNotEmpty(_currentCaptionText),
                                    child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Padding(
                                            padding: const EdgeInsets.only(bottom: 24.0),
                                            child: DecoratedBox(
                                                decoration:
                                                    BoxDecoration(color: const Color(0xB8000000), borderRadius: BorderRadius.circular(2.0)),
                                                child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                                    child: Text(StringUtils.ensureNotEmpty(_currentCaptionText),
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(fontSize: 16, color: Styles().colors!.white)))))))
                              ]),
                              _buildPlayButton()
                            ]))),
                    _buildCcButton()
                  ]));
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

  Widget _buildPlayButton() {
    final double buttonWidth = 80;
    final double buttonHeight = 50;
    bool buttonVisible = _isPlayerInitialized && !_isPlaying;
    return Visibility(
        visible: buttonVisible,
        child: Container(
            decoration: BoxDecoration(color: Styles().colors!.iconColor, borderRadius: BorderRadius.all(Radius.circular(10))),
            width: buttonWidth,
            height: buttonHeight,
            child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                  width: (buttonHeight / 2),
                  child: CustomPaint(
                      painter: TrianglePainter(
                          painterColor: Styles().colors!.white,
                          horzDir: TriangleHorzDirection.rightToLeft,
                          vertDir: TriangleVertDirection.topToBottom),
                      child: Container(height: (buttonHeight / 4)))),
              Container(
                  width: (buttonHeight / 2),
                  child: CustomPaint(
                      painter: TrianglePainter(
                          painterColor: Styles().colors!.white,
                          horzDir: TriangleHorzDirection.rightToLeft,
                          vertDir: TriangleVertDirection.bottomToTop),
                      child: Container(height: (buttonHeight / 4))))
            ]))));
  }

  Widget _buildCcButton() {
    return Visibility(
        visible: _ccVisible,
        child: Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
                onTap: _onTapCc,
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Container(
                        width: 40,
                        height: 30,
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: (_ccEnabled ? Styles().colors!.white! : Styles().colors!.disabledTextColorTwo!), width: 2),
                            borderRadius: BorderRadius.all(Radius.circular(6))),
                        child: Center(
                            child: Text('CC',
                                style: TextStyle(
                                    color: (_ccEnabled ? Styles().colors!.white! : Styles().colors!.disabledTextColorTwo!),
                                    fontSize: 18,
                                    fontFamily: Styles().fontFamilies!.bold))))))));
  }

  void _onTapPlayPause() {
    if (!_isPlayerInitialized) {
      return;
    }
    if (_isPlaying) {
      _controller?.pause();
      _showCc(true);
    } else {
      _controller?.play();
      _startCcHidingTimer();
    }
    setState(() {});
  }

  void _showCc(bool ccVisible) {
    _ccVisible = ccVisible;
    if (mounted) {
      setState(() {});
    }
  }

  void _startCcHidingTimer() {
    Timer(Duration(seconds: 5), () => _showCc(false));
  }

  void _onTapCc() {
    _ccEnabled = !_ccEnabled;
    _currentCaptionText = _ccEnabled ? _controller?.value.caption.text : null;
    if (mounted) {
      setState(() {});
    }
  }

  void _checkVideoStateChanged() {
    if (_controller != null) {
      if ((_currentCaptionText != _controller?.value.caption.text) && _ccEnabled) {
        setState(() {
          _currentCaptionText = _controller?.value.caption.text;
        });
      } else {
        bool videoEnded = (_controller!.value.position == _controller!.value.duration);
        if (videoEnded) {
          _showCc(true);
        }
      }
    }
  }

  bool get _isPlaying {
    return (_controller?.value.isPlaying ?? false);
  }

  bool get _isPlayerInitialized {
    return (_controller?.value.isInitialized ?? false);
  }
}
