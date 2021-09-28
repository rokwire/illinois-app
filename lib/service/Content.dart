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
import 'package:http/http.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

// Content service does rely on Service initialization API so it does not override service interfaces and is not registered in Services.
class Content /* with Service */ {
  static final Content _instance = Content._internal();

  factory Content() {
    return _instance;
  }

  Content._internal();

  Future<ImagesResult> useUrl({String storageDir, String url, int width}) async {
    // 1. first check if the url gives an image
    Response headersResponse = await head(Uri.parse(url));
    if ((headersResponse != null) && (headersResponse.statusCode == 200)) {
      //check content type
      Map<String, String> headers = headersResponse.headers;
      String contentType = headers["content-type"];
      bool isImage = _isValidImage(contentType);
      if (isImage) {
        // 2. download the image
        Response response = await get(Uri.parse(url));
        Uint8List imageContent = response.bodyBytes;
        // 3. call the Content service api
        String fileName = new Uuid().v1();
        return _uploadImage(storagePath: storageDir, imageBytes: imageContent, fileName: fileName, width: width, mediaType: contentType);
      } else {
        return ImagesResult.error("The provided content type is not supported");
      }
    } else {
      return ImagesResult.error("Error on checking the resource content type");
    }
  }

  Future<ImagesResult> selectImageFromDevice({String storagePath, int width}) async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      // User has cancelled operation
      return ImagesResult.cancel();
    }
    if ((image != null) && (await image.exists())) {
      List<int> imageBytes = image.readAsBytesSync();
      String fileName = basename(image.path);
      String contentType = mime(fileName);
      return _uploadImage(storagePath: storagePath, imageBytes: imageBytes, width: width, fileName: fileName, mediaType: contentType);
    } else {
      return null;
    }
  }

  Future<ImagesResult> _uploadImage({List<int> imageBytes, String fileName, String storagePath, int width, String mediaType}) async {
    String serviceUrl = Config().contentUrl;
    if (AppString.isStringEmpty(serviceUrl)) {
      return ImagesResult.error('Missing images BB url.');
    }
    if (AppCollection.isCollectionEmpty(imageBytes)) {
      return ImagesResult.error('No file bytes.');
    }
    if (AppString.isStringEmpty(fileName)) {
      return ImagesResult.error('Missing file name.');
    }
    if (AppString.isStringEmpty(storagePath)) {
      return ImagesResult.error('Missing storage path.');
    }
    if ((width == null) || (width <= 0)) {
      return ImagesResult.error('Invalid image width. Please, provide positive number.');
    }
    if (AppString.isStringEmpty(mediaType)) {
      return ImagesResult.error('Missing media type.');
    }
    String url = "$serviceUrl/image";
    Map<String, String> imageRequestFields = {
      'path': storagePath,
      'width': width.toString(),
      'quality': 100.toString() // Use maximum quality - 100
    };
    StreamedResponse response = await Network().multipartPost(
        url: url, fileKey: 'fileName', fileName: fileName, fileBytes: imageBytes, contentType: mediaType, fields: imageRequestFields, auth: NetworkAuth.User);
    int responseCode = response?.statusCode ?? -1;
    String responseString = await response?.stream?.bytesToString();
    if (responseCode == 200) {
      Map<String, dynamic> json = AppJson.decode(responseString);
      String imageUrl = (json != null) ? json['url'] : null;
      return ImagesResult.succeed(imageUrl);
    } else {
      String error = "Failed to upload image. Reason: $responseString";
      print(error);
      return ImagesResult.error(error);
    }
  }

  bool _isValidImage(String contentType) {
    if (contentType == null) return false;
    return contentType.startsWith("image/");
  }
}

enum ImagesResultType { ERROR_OCCURRED, CANCELLED, SUCCEEDED }

class ImagesResult {
  ImagesResultType resultType;
  String errorMessage;
  dynamic data;

  ImagesResult.error(String errorMessage) {
    this.resultType = ImagesResultType.ERROR_OCCURRED;
    this.errorMessage = errorMessage;
  }

  ImagesResult.cancel() {
    this.resultType = ImagesResultType.CANCELLED;
  }

  ImagesResult.succeed(dynamic data) {
    this.resultType = ImagesResultType.SUCCEEDED;
    this.data = data;
  }
}
