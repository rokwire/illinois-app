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

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

// Content service does rely on Service initialization API so it does not override service interfaces and is not registered in Services.
class Content /* with Service */ {
  
  // Singletone Factory

  static Content? _instance;

  static Content? get instance => _instance;
  
  @protected
  static set instance(Content? value) => _instance = value;

  factory Content() => _instance ?? (_instance = Content.internal());

  @protected
  Content.internal();

  // Implementation

  Future<ImagesResult> useUrl({String? storageDir, required String url, int? width}) async {
    // 1. first check if the url gives an image
    Uri? uri = Uri.tryParse(url);
    Response? headersResponse = (uri != null) ? await head(Uri.parse(url)) : null;
    if ((headersResponse != null) && (headersResponse.statusCode == 200)) {
      //check content type
      Map<String, String> headers = headersResponse.headers;
      String? contentType = headers["content-type"];
      bool isImage = _isValidImage(contentType);
      if (isImage) {
        // 2. download the image
        Response response = await get(Uri.parse(url));
        Uint8List imageContent = response.bodyBytes;
        // 3. call the Content service api
        String fileName = const Uuid().v1();
        return _uploadImage(storagePath: storageDir, imageBytes: imageContent, fileName: fileName, width: width, mediaType: contentType);
      } else {
        return ImagesResult.error(ImagesErrorType.contentTypeNotSupported, "The provided content type is not supported");
      }
    } else {
      return ImagesResult.error(ImagesErrorType.headerFailed, "Error on checking the resource content type");
    }
  }

  Future<ImagesResult?> selectImageFromDevice({String? storagePath, int? width}) async {
    XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) {
      // User has cancelled operation
      return ImagesResult.cancel();
    }
    try {
      if ((0 < await image.length())) {
        List<int> imageBytes = await image.readAsBytes();
        String fileName = basename(image.path);
        String? contentType = mime(fileName);
        return _uploadImage(storagePath: storagePath, imageBytes: imageBytes, width: width, fileName: fileName, mediaType: contentType);
      }
    }
    catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<ImagesResult> _uploadImage({List<int>? imageBytes, String? fileName, String? storagePath, int? width, String? mediaType}) async {
    String? serviceUrl = Config().contentUrl;
    if (StringUtils.isEmpty(serviceUrl)) {
      return ImagesResult.error(ImagesErrorType.serviceNotAvailable, 'Missing images BB url.');
    }
    if (CollectionUtils.isEmpty(imageBytes)) {
      return ImagesResult.error(ImagesErrorType.contentNotSupplied, 'No file bytes.');
    }
    if (StringUtils.isEmpty(fileName)) {
      return ImagesResult.error(ImagesErrorType.fileNameNotSupplied, 'Missing file name.');
    }
    if (StringUtils.isEmpty(storagePath)) {
      return ImagesResult.error(ImagesErrorType.storagePathNotSupplied, 'Missing storage path.');
    }
    if ((width == null) || (width <= 0)) {
      return ImagesResult.error(ImagesErrorType.dimensionsNotSupplied, 'Invalid image width. Please, provide positive number.');
    }
    if (StringUtils.isEmpty(mediaType)) {
      return ImagesResult.error(ImagesErrorType.mediaTypeNotSupplied, 'Missing media type.');
    }
    String url = "$serviceUrl/image";
    Map<String, String> imageRequestFields = {
      'path': storagePath!,
      'width': width.toString(),
      'quality': 100.toString() // Use maximum quality - 100
    };
    StreamedResponse? response = await Network().multipartPost(
        url: url, fileKey: 'fileName', fileName: fileName, fileBytes: imageBytes, contentType: mediaType, fields: imageRequestFields, auth: Auth2());
    int responseCode = response?.statusCode ?? -1;
    String responseString = (await response?.stream.bytesToString())!;
    if (responseCode == 200) {
      Map<String, dynamic>? json = JsonUtils.decode(responseString);
      String? imageUrl = (json != null) ? json['url'] : null;
      return ImagesResult.succeed(imageUrl);
    } else {
      debugPrint("Failed to upload image. Reason: $responseCode $responseString");
      return ImagesResult.error(ImagesErrorType.uploadFailed, "Failed to upload image.", response);
    }
  }

  bool _isValidImage(String? contentType) {
    if (contentType == null) return false;
    return contentType.startsWith("image/");
  }
}

enum ImagesResultType { error, cancelled, succeeded }
enum ImagesErrorType {
  headerFailed,
  contentTypeNotSupported,
  serviceNotAvailable,
  contentNotSupplied,
  fileNameNotSupplied,
  storagePathNotSupplied,
  dimensionsNotSupplied,
  mediaTypeNotSupplied,
  uploadFailed,
}

class ImagesResult {
  ImagesResultType? resultType;
  ImagesErrorType? errorType;
  String? errorMessage;
  dynamic data;

  ImagesResult.error(this.errorType, this.errorMessage, [this.data]) :
    resultType = ImagesResultType.error;

  ImagesResult.cancel() :
    resultType = ImagesResultType.cancelled;

  ImagesResult.succeed(this.data) :
    resultType = ImagesResultType.succeeded;
}
