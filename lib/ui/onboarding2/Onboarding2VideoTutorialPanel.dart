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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/onboarding2/Onboadring2RolesPanel.dart';
import 'package:video_player/video_player.dart';

class Onboarding2VideoTutorialPanel extends StatefulWidget {
  @override
  State<Onboarding2VideoTutorialPanel> createState() => _Onboarding2VideoTutorialPanelState();
}

class _Onboarding2VideoTutorialPanelState extends State<Onboarding2VideoTutorialPanel> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

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
    _controller = VideoPlayerController.network('https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Videos/illinois_app_overview+(1080p).mp4');
    _controller.addListener(() { });
    //TBD: another url? url in config etc
    _initializeVideoPlayerFuture = _controller.initialize();
  }

  void _disposeVideoPlayer() {
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ));
  }

  void _onTapBack() {
    Navigator.pop(context);
  }

  void _onTapSkip() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2RolesPanel()));
  }
}
