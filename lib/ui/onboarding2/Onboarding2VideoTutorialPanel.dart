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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/onboarding2/Onboadring2RolesPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
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
    //TBD: another url? url in config etc
    _controller =
        VideoPlayerController.network('https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Videos/illinois_app_overview+(1080p).mp4');
    _initializeVideoPlayerFuture = _controller.initialize().then((_) => _controller.play()); // Automatically play video after initialization
  }

  void _disposeVideoPlayer() {
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Styles().colors!.blackTransparent06,
        body: SafeArea(
            child: Stack(alignment: Alignment.center, children: [
          FutureBuilder(
              future: _initializeVideoPlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Center(child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              }),
          Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Onboarding2BackButton(padding: const EdgeInsets.only(left: 17, top: 11, right: 20, bottom: 27), onTap: _onTapBack)
            ]),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: RoundedButton(label: Localization().getStringEx('panel.onboarding2.video.button.title', 'Skip'), onTap: _onTapSkip))
          ])
        ])));
  }

  void _onTapBack() {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }

  void _onTapSkip() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2RolesPanel()));
  }
}
