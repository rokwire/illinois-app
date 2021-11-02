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

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:path_provider/path_provider.dart';

class ImageUtils {

  ///
  /// imageBytes - the content of the image
  ///
  /// fileName - the name of the file without file extension
  ///
  /// returns true if save operation succeed and false otherwise
  ///
  static Future<bool> saveToFs(Uint8List imageBytes, String fileName) async {
    if ((imageBytes == null) || AppString.isStringEmpty(fileName)) {
      return false;
    }
    final String dir = (await getApplicationDocumentsDirectory()).path;
    final String fullPath = '$dir/$fileName.png';
    File capturedFile = File(fullPath);
    await capturedFile.writeAsBytes(imageBytes);
    bool saveResult = false;
    try {
      saveResult = await GallerySaver.saveImage(capturedFile.path);
    } catch (e) {
      Log.e('Failed to save image to fs. \nException: ${e?.toString()}');
    }
    return saveResult;
  }

  ///
  /// imageBytes - the bytes of the original image
  ///
  /// label - the string that would be displayed over the image
  ///
  /// width - the width of the original image
  ///
  /// height - the height of the original image
  ///
  /// returns the bytes of the updated image
  ///
  static Future<Uint8List> applyLabelOverImage(Uint8List imageBytes, String label, {double width = 1024, double height = 1024}) async {
    if (imageBytes != null) {
      final double labelHeight = 156;
      double newHeight = (height + labelHeight);
      try {
        final recorder = new ui.PictureRecorder();
        Canvas canvas = new Canvas(recorder, new Rect.fromPoints(new Offset(0.0, 0.0), new Offset(width, newHeight)));
        final fillPaint = new Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawRect(new Rect.fromLTWH(0.0, 0.0, width, newHeight), fillPaint);

        ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
        ui.FrameInfo frameInfo = await codec.getNextFrame();
        canvas.drawImage(frameInfo.image, Offset(0.0, labelHeight), fillPaint);

        final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
            ui.ParagraphStyle(textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center, fontSize: 54, fontFamily: Styles().fontFamilies.bold))
          ..pushStyle(new ui.TextStyle(color: Styles().colors.textSurface))
          ..addText(label);
        final ui.Paragraph paragraph = paragraphBuilder.build()..layout(ui.ParagraphConstraints(width: width));
        double textY = ((newHeight - height) - paragraph.height) / 2.0;
        canvas.drawParagraph(paragraph, Offset(0.0, textY));

        final picture = recorder.endRecording();
        final img = await picture.toImage(width.toInt(), newHeight.toInt());
        ByteData pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
        Uint8List newQrBytes = Uint8List(pngBytes.lengthInBytes);
        for (int i = 0; i < pngBytes.lengthInBytes; i++) {
          newQrBytes[i] = pngBytes.getUint8(i);
        }

        return newQrBytes;
      } catch (e) {
        Log.e('Failed to apply label to image. \nException: ${e.toString()}');
      }
    }
    return null;
  }
}
