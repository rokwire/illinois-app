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
import 'package:flutter/services.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/onboarding2/Onboadring2RolesPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2Widgets.dart';
import 'package:rokwire_plugin/service/app_navigation.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:video_player/video_player.dart';

class Onboarding2VideoTutorialPanel extends StatefulWidget {
  @override
  State<Onboarding2VideoTutorialPanel> createState() => _Onboarding2VideoTutorialPanelState();
}

class _Onboarding2VideoTutorialPanelState extends State<Onboarding2VideoTutorialPanel> implements NotificationsListener {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  List<DeviceOrientation>? _allowedOrientations;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [AppNavigation.notifyEvent]);
    _enableLandscapeOrientations();
    _initVideoPlayer();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _revertToAllowedOrientations();
    _disposeVideoPlayer();
    super.dispose();
  }

  void _initVideoPlayer() {
    String? tutorialUrl = Config().videoTutorialUrl;
    if (StringUtils.isNotEmpty(tutorialUrl)) {
      _controller = VideoPlayerController.network(tutorialUrl!);
      _initializeVideoPlayerFuture =
          _controller!.initialize().then((_) => _controller!.play()); // Automatically play video after initialization
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

  @override
  Widget build(BuildContext context) {
    double buttonWidth = MediaQuery.of(context).textScaleFactor * 100;
    return Scaffold(
        backgroundColor: Styles().colors!.blackTransparent06,
        body: SafeArea(
            child: Stack(alignment: Alignment.center, children: [
          _buildVideoContent(),
          Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Onboarding2BackButton(padding: const EdgeInsets.only(left: 17, top: 11, right: 20, bottom: 27), onTap: _onTapBack)
            ]),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: SizedBox(width: buttonWidth, child: RoundedButton(label: Localization().getStringEx('panel.onboarding2.video.button.title', 'Skip'), fontSize: 16, onTap: _onTapSkip)))
          ])
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
          child: Text(Localization().getStringEx('panel.onboarding2.video.missing.msg', 'Missing video'),
              style: TextStyle(color: Styles().colors!.white, fontSize: 20, fontFamily: Styles().fontFamilies!.bold)));
    }
  }

  void _onTapBack() {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }

  void _onTapSkip() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2RolesPanel()));
  }

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
        _controller!.pause();
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
          // Play again video when the panel is visible
          if (!_controller!.value.isPlaying) {
            _controller!.play();
          }
        }
      }
    }
  }
}
