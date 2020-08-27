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

class PollProgressPainter extends CustomPainter {
  final Color progressColor;
  final Color backgroundColor;
  final double progress;
  final Paint _paintBackground = new Paint();
  final Paint _paintProgress = new Paint();

  PollProgressPainter({this.progressColor, this.backgroundColor, this.progress}) {
    if (backgroundColor != null) {
      _paintBackground.color = backgroundColor;
      //_paintBackground.style = PaintingStyle.stroke;
      //_paintBackground.strokeWidth = 20;
    }
    if (progressColor != null) {
      _paintProgress.color = progressColor;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _paintBackground);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * progress, size.height), _paintProgress);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }  
}