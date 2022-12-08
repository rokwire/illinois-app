/*
 * Copyright 2022 Board of Trustees of the University of Illinois.
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
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

class VideoPlayButton extends StatelessWidget {
  final bool hasBackground;

  VideoPlayButton({this.hasBackground = true});

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = 80;
    final double buttonHeight = 50;
    return Container(
            decoration: BoxDecoration(color: (hasBackground ? Styles().colors!.iconColor : Colors.transparent), borderRadius: BorderRadius.all(Radius.circular(10))),
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
            ])));
  }

}
