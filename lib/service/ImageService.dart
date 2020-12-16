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
import 'package:http_parser/http_parser.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:mime_type/mime_type.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart';
import 'package:illinois/model/ImageType.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/Network.dart';
import 'package:image_picker/image_picker.dart';

// ImageService does rely on Service initialization API so it does not override service interfaces and is not registered in Services.
class ImageService /* with Service */ {
  static final ImageService _instance = ImageService._internal();

  factory ImageService() {
    return _instance;
  }

  ImageService._internal();

  Future<List<ImageType>> loadImageTypes() async {
    String url = (Config().imagesServiceUrl != null) ? "${Config().imagesServiceUrl}/api/v1/image-types" : null;
    Response response = await Network().get(url);
    if ((response != null) && (response.statusCode == 200)) {
      List<ImageType> imageTypes = List<ImageType>();
      String responseBody = response.body;
      List<dynamic> jsonList = AppJson.decode(responseBody);
      if ((jsonList != null) && jsonList.isNotEmpty) {
        for (dynamic jsonEntry in jsonList) {
          ImageType imageType = ImageType.fromJson(jsonEntry);
          imageTypes.add(imageType);
        }
      }
      return imageTypes;
    } else {
      Log.d("Error getting image types");
      return null;
    }
  }

  Future<ImagesResult> useUrl(ImageType imageType, String url) async {
    // 1. first check if the url gives an image
    Response headersResponse = await head(url);
    if ((headersResponse != null) && (headersResponse.statusCode == 200)) {
      //check content type
      Map<String, String> headers = headersResponse.headers;
      String contentType = headers["content-type"];
      bool isImage = _isValidImage(contentType);
      if (isImage) {
        // 2. download the image
        Response response = await get(url);
        Uint8List imageContent = response.bodyBytes;

        // 3. call the image service api
        var fileName = new Uuid().v1();
        return _callImageService(
            imageType, imageContent, fileName, contentType);
      } else {
        //fire error
        String error = "The provided content type is not supported";
        Log.d(error);
        return ImagesResult.error(error);
      }
    } else {
      //fire error
      String error = "Error on checking the resource content type";
      Log.d(error);
      return ImagesResult.error(error);
    }
  }

  Future<ImagesResult> chooseFromDevice(ImageType imageType) async {
    // 1. choose the image from the gallery
    PickedFile image = await ImagePicker().getImage(source: ImageSource.gallery);
    if (image == null) {
      //return cancel
      Log.d("Cancel picker image");
      return ImagesResult.cancel();
    }

    // 2. call the image service api
    List<int> bytesFile = File(image.path).readAsBytesSync();
    var fName = basename(image.path);
    var contentType = mime(fName);
    return _callImageService(imageType, bytesFile, fName, contentType);
  }

  bool _isValidImage(String contentType) {
    if (contentType == null) return false;
    return contentType.startsWith("image/");
  }

  Future<ImagesResult> _callImageService(ImageType imageType,
      List<int> bytesFile, String fName, String mediaType) async {
    String url = (Config().imagesServiceUrl != null) ? "${Config().imagesServiceUrl}/api/v1/image" : null;
    var uri = Uri.parse(url);
    var request = MultipartRequest("POST", uri);
    request.fields['image-type-identifier'] = imageType.identifier;
    request.files.add(MultipartFile.fromBytes("fileName", bytesFile,
        filename: fName, contentType: MediaType.parse(mediaType)));
    StreamedResponse response = await request.send();
    String responseUrl = ((response != null) && (response.statusCode == 200)) ? await response.stream?.bytesToString() : null;
    if (responseUrl != null) {

      //hack the double quotes!! ""https://....""
      responseUrl = responseUrl.trim().replaceAll("\"", "").trim();

      return ImagesResult.succeed(responseUrl);
    } else {
      //return error
      String error = "Error on calling the images service";
      Log.d(error);
      return ImagesResult.error(error);
    }
  }
}

enum ImagesResultType {ERROR_OCCURRED, CANCELLED, SUCCEEDED}

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
