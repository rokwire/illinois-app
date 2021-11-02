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

import 'package:gallery_saver/gallery_saver.dart';
import 'package:illinois/service/Log.dart';
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
}
